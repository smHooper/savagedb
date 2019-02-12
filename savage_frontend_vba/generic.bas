Attribute VB_Name = "generic"
Option Compare Database
Public Const CONNECTION_STR = "DRIVER={PostgreSQL ANSI};DATABASE=savage;SERVER=165.83.50.66;PORT=5432"
Public Const PYTHON_PATH = "python"
Public Const CONNECTION_TXT = "C:\Users\shooper\proj\savagedb\connection_info.txt"
Public Const SCRIPT_DIR = "C:\Users\shooper\proj\savagedb\git\scripts"

Public Function pass_through_query(sql_str As String, Optional return_records As Boolean, Optional conn_str As String) As ADODB.recordset
    Dim connection As New ADODB.connection
    Dim record_set As New ADODB.recordset
    Dim result As Long
    
    If Len(conn_str) Then
        connection.Open conn_str
    Else
        connection.Open CONNECTION_STR & ";Trusted_Connection=Yes"
    End If
    
    record_set.Open sql_str, connection
    
    'Cleanup
    If return_records Then
        Set pass_through_query = record_set
    Else
        If record_set.State <> adStateClosed Then record_set.Close
        Set record_set = Nothing
        If connection.State <> adStateClosed Then connection.Close
        Set connection = Nothing
    End If
    
End Function


Public Function script_status(logfile As String) As String
    Dim file_number As Integer
    Dim logged_line As String
    Dim status As String: status = ""
    Dim warning_found As Boolean: warning_found = False
    Dim details_msg As String: details_msg = "Click ""Open output folder"" and open log.txt for details."
    
    ' If the file doesn't exist yet, exit. Otherwise, open it
    If Dir(logfile) = "" Then
        status = "running"
        'Exit Function
    Else
        file_number = FreeFile()
        Open logfile For Input As #file_number
    End If
    
    Do While Not EOF(file_number)
        Line Input #file_number, logged_line ' read in data 1 line at a time
        ' If there was an error, the log will have traceback info
        If logged_line Like "Traceback*" Then
            status = "with errors. " & details_msg
            Exit Do ' Exit because an error was found
        ' If the script ran successfully, the last line in the log will give the output dir
        ElseIf logged_line Like "* file* written to*" Then
            status = "successfully"
        ' Check if there were any warnings
        ElseIf logged_line Like "*warnings.warn(*" Then
            warning_found = True
        End If
    Loop
    
    If warning_found And (status <> "with errors") Then
        status = status & " with warnings. " & details_msg
    End If
    
    script_status = status

    Close #file_number

End Function

Public Function run_io_command(ByVal cmd As String, logfile As String, outpath As String, Optional silent As Boolean = False, Optional wait_msg As String)
' Submit a file IO command to a terminal
    
    ' If the progress form is open, close it
    If CurrentProject.AllForms("frm_query_plot_wait").IsLoaded Then
        DoCmd.Close acForm, "frm_query_plot_wait"
    End If
    
    ' Start the command
    On Error GoTo ErrHndlr
    
    If Not silent Then
        DoCmd.OpenForm "frm_query_plot_wait" ' Show progess form
        'Forms.query_plot_wait.Form.SetFocus
        If Len(wait_msg) Then
            Forms.frm_query_plot_wait.label_status.Caption = wait_msg
            DoCmd.RepaintObject acForm, "frm_query_plot_wait"
        End If
    End If
    
    Dim wShell As Object
    Set wShell = VBA.CreateObject("WScript.Shell")
    wShell.Run "cmd.exe /c " & cmd, 0, True ' Run command silently and wait for process to finish
    On Error GoTo 0
    
    ' Read the log file and get status
    status = script_status(logfile)
    
    If Not silent Then
        Dim status_label As label
        Set status_label = Forms!frm_query_plot_wait!label_status
        status_label.Caption = "Script finished " & status
        If Len(status) > 15 Then
            'status_label.FontSize = 10
            status_label.TextAlign = 1 ' Left alignment
        End If
        Forms.frm_query_plot_wait.btn_close.Visible = True
        Forms.frm_query_plot_wait.btn_open_file_location.Visible = True
        Forms.frm_query_plot_wait.btn_open_file_location.Tag = outpath
        
        DoCmd.RepaintObject acForm, "frm_query_plot_wait"
    End If
        
    Exit Function

ErrHndlr:
    MsgBox "Error starting command:" & vbCrLf & _
           "Command: " & cmd & vbCrLf & _
           "Err Desc: " & Err.Description
    Err.Clear
End Function

Public Function run_sdout_command(cmd As String) As String
'Run a shell command, returning the output as a string
Dim wShell As Object
Dim output As Object
Dim logfile As String
Dim stdout_str As String

    On Error GoTo ErrHndlr
    
    ' Start the command
    logfile = CurrentProject.path & "\temp.txt"
    Set wShell = VBA.CreateObject("WScript.Shell")
    wShell.Run "cmd.exe /c " & cmd & " > " & logfile & " 2>&1", 0, True ' Run command silently and wait for process to finish
    On Error GoTo 0

    ' Read the log file
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set text_file = fso.OpenTextFile(logfile, 1)
    stdout_str = text_file.ReadAll
    text_file.Close
        
    ' Clean up an delete the temp file
    Set file = fso.GetFile(logfile)
    file.Delete
    Set file = Nothing

    run_sdout_command = stdout_str
    
    Exit Function

ErrHndlr:
    MsgBox "Error starting command:" & vbCrLf & _
           "Command: " & cmd & vbCrLf & _
           "Err Desc: " & Err.Description
    Err.Clear
    
End Function

Function create_user_dsn(dsn_name As String, server_str As String, db_name As String, read_only As Integer, Optional username As String, Optional password As String) As String
    On Error GoTo create_user_dsn_Err

    Dim connect_options As String
    
    If Len(username) = 0 Then
        ' Use trusted authentication if username is not supplied.
        connect_options = "Description=" & dsn_name & vbCr & "SERVER=" & server_str & vbCr & "DATABASE=" & db_name & vbCr & "PORT=5432" & vbCr & "Trusted_Connection=Yes"
    Else
        connect_options = "Description=" & dsn_name & vbCr & "SERVER=" & server_str & vbCr & "DATABASE=" & db_name & vbCr & _
                    "PORT=5432" & vbCr & "UID=" & username & vbCr & "PWD=" & password & vbCr & _
                    "read_only=" & read_only & vbCr
    End If
    
    DBEngine.RegisterDatabase dsn_name, "PostgreSQL ANSI", True, connect_options
        
    create_user_dsn = connect_options
    Exit Function
    
create_user_dsn_Err:
    
    create_user_dsn = ""
    MsgBox "create_user_dsn encountered an unexpected error: " & Err.Description
    
End Function

Public Function stripSchemaName(schemaName As String, silent As Boolean)
    'schemaName that prefixes the table e.g. 'public'
    '--EXAMPLE use from immediate window -
    '--  StripSchemaName "public"
    Dim definition As Object
    Dim i As Integer
    For Each definition In CurrentDb.TableDefs
        If left(definition.name, Len(schemaName)) = schemaName Then
             'plus 2 to strip the _ as well
            definition.name = Mid(definition.name, Len(schemaName) + 2)
        End If
    Next
    If Not silent Then MsgBox "Removed " + schemaName + " from all tables"

End Function

Public Function object_is_open(object_name As String, Optional object_type As Integer = acForm) As Boolean
' object_type can be:
' acTable (value 0)
' acQuery (value 1)
' acForm (value 2) Default
' acReport (value 3)
' acMacro (value 4)
' acModule (value 5)
' Returns True if object_name is open, False otherwise.
On Error Resume Next
    IsObjectOpen = (SysCmd(acSysCmdGetObjectState, object_type, object_name) <> 0)
     
    If Err <> 0 Then
        object_is_open = False
    End If
    
End Function


Public Function get_user_state() As String
    
    Dim record_set As DAO.recordset
    Dim user_state As String
    
    Set record_set = CurrentDb.OpenRecordset("Select login FROM user_state;")
    With record_set
        .MoveFirst
        user_state = record_set!login.Value
    End With
    Set record_set = Nothing
    
    get_user_state = user_state

End Function

Public Function set_read_write(Optional username As String, Optional password As String) As String

    'On Error GoTo error_login
    
    ' Get the current user state from a local table
    Dim current_user_state As String
    current_user_state = get_user_state
    
    Dim new_user_state As String
    Dim new_cnn_str As String
    If current_user_state = "read-only" Then
        new_user_state = "admin"
        If Len(username) And Len(password) Then
            new_cnn_str = "ODBC;" & CONNECTION_STR & ";UID=" & username & ";PWD=" & password & ";"
        Else
            MsgBox "No username or password given", vbCritical, "Invalid arguments for generic.set_read_write()"
            set_read_write = ""
            Exit Function
        End If
    Else
        new_user_state = "read-only"
        new_cnn_str = "ODBC;" & CONNECTION_STR & ";UID=savage_read;PWD=0l@usmur!e;"
    End If
    
    ' Relink all tables so they have the right permissions
    Dim tdf As DAO.TableDef
    For Each tdf In CurrentDb.TableDefs
        ' Only set the connection if it's an ODBC linked table
        If left$(tdf.Connect, 5) = "ODBC;" Then
            tdf.Connect = new_cnn_str
            If tdf.Attributes < 537001984 Then
                tdf.Attributes = dbAttachSavePWD 'dbAttachSavePWD = 131072
            End If
            tdf.RefreshLink
        End If
    Next
    
    Dim qdf As QueryDef
    For Each qdf In CurrentDb.QueryDefs
        If left$(qdf.Connect, 5) = "ODBC;" Then
            qdf.Connect = new_cnn_str
        End If
    Next
    CurrentDb.QueryDefs.Refresh
    
    Set new_tdf = Nothing
    
    ' Update the user state in the local table
    
    Dim update_sql As String
    update_sql = "UPDATE user_state SET login = '" & new_user_state & "'"
    Set qdf = CurrentDb.CreateQueryDef("", update_sql)
    qdf.Execute dbFailOnError
    
    set_read_write = new_user_state
    
    Exit Function
    
    
    
error_login:
    If Err.Number = 3059 Then 'The user canceled so just exit
        Exit Function
    Else
        MsgBox "Problem with login: " & Err.Description
    End If
    
End Function


Public Function cleanODBCConection()
    
    stripSchemaName "public", True
    
End Function

Public Function create_temp_db(Optional path As String)
    On Error GoTo errHandler
    
    Dim temp_db As DAO.Database
    Dim file_path As String
    
    If Len(path) Then
        file_path = path
    Else
        file_path = CurrentProject.path & "\temp.accdb"
    End If
    
    'close connections to temp file
    'Me.subTemp.SourceObject = ""
    
    'delete temporary file first
    If Dir(file_path) > "" Then
        Kill file_path
    End If
    
    'create temporary database
    Set temp_db = DBEngine.CreateDatabase(file_path, dbLangGeneral, dbVersion120)
    temp_db.Close
    Set temp_db = Nothing
    
    Exit Function

errExit:
    On Error Resume Next
    temp_db.Close
    Set temp_db = Nothing
    Exit Function

errHandler:
    MsgBox Err.Number & ": " & Err.Description, vbInformation, "Error"
    Resume errExit
    Resume
End Function


Public Function open_file_dialog(ByRef textbox As textbox, Optional title As String = "Select an output folder", Optional dialog_type As Integer = msoFileDialogFolderPicker, Optional filter_str As String = "", Optional filter_name As String = "")
'NOTE: To use this code, you must reference
'The Microsoft Office 16.0 (or current version)
'Object Library by clicking menu Tools > References
'   -Check the box for Microsoft Office 16.0 Object Library
'   -Click OK

    With Application.FileDialog(dialog_type)
        .title = title
        
        If Len(Nz(filter_str)) > 0 Then
            .Filters.Add filter_name, filter_str, 1
        End If
        
        If .Show Then
            textbox = .SelectedItems(1)
        End If
        
    End With

End Function

Public Sub ExportAllCode()

    Dim c As VBComponent
    Dim ext As String
    Dim out_dir As String

    out_dir = CurrentProject.path & "\" & left(CurrentProject.name, InStrRev(CurrentProject.name, ".") - 1) & "_vba"
    If Dir(out_dir, vbDirectory) = "" Then
        MkDir out_dir
    End If
    
    For Each c In VBE.VBProjects(1).VBComponents
        Select Case c.Type
            Case vbext_ct_ClassModule, vbext_ct_Document
                ext = ".cls"
            Case vbext_ct_MSForm
                ext = ".frm"
            Case vbext_ct_StdModule
                ext = ".bas"
            Case Else
                ext = ""
        End Select
        
        If ext <> "" Then
            c.Export FileName:=out_dir & "\" & c.name & ext
        End If
    Next c

End Sub

