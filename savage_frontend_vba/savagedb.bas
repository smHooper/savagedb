Attribute VB_Name = "savagedb"
Option Compare Database
Public Const CONNECTION_STR = "DRIVER={PostgreSQL ANSI};DATABASE=savage;SERVER=165.83.50.66;PORT=5432"
Public Const PYTHON_PATH = "C:\ProgramData\Anaconda2\python.exe"
Public Const CONNECTION_TXT = "C:\users\shooper\proj\savagedb\connection_info.txt"
Public Const SCRIPT_DIR = "C:\users\shooper\proj\savagedb\git\scripts"


Public Function pass_through_query(sql_str As String, Optional return_records As Boolean, Optional conn_str As String) As ADODB.recordset
    Dim connection As New ADODB.connection
    Dim record_set As New ADODB.recordset
    Dim result As Long
    
    If Len(conn_str) Then
        connection.Open conn_str
    Else
        connection.Open CONNECTION_STR & ";Trusted_Connection=Yes"
    End If
    
    record_set.CursorLocation = adUseClient
    record_set.Open sql_str, connection, adOpenDynamic, adLockOptimistic
'    Set connection = New ADODB.connection
'    connection.ConnectionString = conn_str
'    connection.Open
    
    
'    Set record_set = New ADODB.recordset
'    With record_set
'        .ActiveConnection = conn
'        .CursorType = adOpenDynamic
'        .LockType = adLockOptimistic
'        .source = sql_str
'        .Open
'    End With
    
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
'    If current_user_state = "read-only" Then
'        new_user_state = "admin"
'        If Len(username) And Len(password) Then
'            new_cnn_str = "ODBC;" & CONNECTION_STR & ";UID=" & username & ";PWD=" & password & ";"
'        Else
'            MsgBox "No username or password given", vbCritical, "Invalid arguments for savagedb.set_read_write()"
'            set_read_write = ""
'            Exit Function
'        End If
'    Else
'        new_user_state = "read-only"
'        new_cnn_str = "ODBC;" & CONNECTION_STR & ";UID=savage_read;PWD=0l@usmur!e;"
'    End If

    If Len(username) And Len(password) Then
        new_cnn_str = "ODBC;" & CONNECTION_STR & ";UID=" & username & ";PWD=" & password & ";"
        new_user_state = Split(username, "_")(1) ' all usernames are in the form savage_<userstate>
    Else
        MsgBox "No username or password given", vbCritical, "Invalid arguments for savagedb.set_read_write()"
        set_read_write = ""
        Exit Function
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
    
error_exit:
    On Error Resume Next
    Exit Function
    
error_login:
    If Err.Number = 3059 Then 'The user canceled so just exit
        Exit Function
    Else
        MsgBox "Problem with login: " & Err.Description
        GoTo error_exit
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


Public Function open_file_dialog(Optional title As String = "Select an output folder", Optional dialog_type As Integer = msoFileDialogFolderPicker, Optional filter_str As String = "", Optional filter_name As String = "") As String
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
            open_file_dialog = .SelectedItems(1)
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


Public Function make_qr_str(id_number As Integer) As String
' Return a JSON string that the app will be able to read

    Dim qr_str As String
    Dim rs As recordset
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM road_permits WHERE id = " & id_number, dbOpenSnapshot)
    
    rs.MoveLast
    If rs.RecordCount <> 1 Then
        MsgBox "Error occurred while making QR code string. No permit found with ID " & id_number, vbCritical, "QR code error"
        make_qr_str = ""
        Exit Function
    End If
    
    Dim vehicle_type As String: vehicle_type = rs.fields("permit_type")
    Select Case vehicle_type
        Case Is = "Right of Way"
            If rs.fields("is_lodge_bus") Then
                qr_str = "{""vehicle_type"": ""Lodge Bus""," & _
                         " ""Lodge"": """ & rs.fields("permit_holder") & ""","
            Else
                qr_str = "{""vehicle_type"": ""Right of Way""," & _
                         " ""Right of Way"": """ & rs.fields("permit_holder") & ""","
            End If
        Case Is = "NPS Approved"
            qr_str = "{""vehicle_type"": ""NPS Approved""," & _
                     " ""Approved category"": """ & rs.fields("approved_type") & ""","
        Case Is = "NPS Contractor"
            qr_str = "{""vehicle_type"": ""NPS Contractor""," & _
                     " ""Company/Organization Name"": """ & rs.fields("permit_holder") & ""","
        Case Is = "Pro Photography and Film"
            qr_str = "{""vehicle_type"": ""Photographer"","
        Case Else ' Accessibility, Employee, Subsistence
            qr_str = "{""vehicle_type"": """ & vehicle_type & """," & _
                     " ""Permit holder"": """ & rs.fields("permit_holder") & ""","
    End Select
    
    Dim n_days As Integer: n_days = DateDiff("d", rs.fields("date_in"), rs.fields("date_out"))
    'Dim permit_number As String: permit_number = Replace(Me.lbl_permit_number.Caption, "Permit #: ", "")
    
    qr_str = qr_str & " ""Driver's full name"": """ & rs.fields("driver_name") & """," & _
                      " ""Number of expected nights"": """ & n_days & """," & _
                      " ""Permit number"": """ & rs.fields("permit_number") & """}"
    make_qr_str = qr_str

End Function



Public Function make_qr_code(qr_str As String, Optional output_path As String) As String
    
    Debug.Print qr_str
    
    ' Get the path of the qr executable
    Dim qr_exe_path As String: qr_exe_path = left(PYTHON_PATH, InStrRev(PYTHON_PATH, "\")) & "Scripts\qr.exe"
    
    ' If an output path wasn't given, just use the dir where the DB is
    If Len(output_path & "") = 0 Then output_path = CurrentProject.path & "\qr.png"
    
    ' Make and run the command, piping the output to the output path
    Dim cmd As String: cmd = qr_exe_path & " '" & qr_str & "' > " & output_path
    Dim wShell As Object
    Set wShell = VBA.CreateObject("WScript.Shell")
    ' Don't show the window but wait until the QR code command is done. This is necessary because when
    '   looping through multiple permits, save_permit_to_file tries to set the picture of the img_qr
    '   while the image is in the middle of being created
    wShell.Run "cmd.exe /c " & cmd, 0, True
    
    ' Return the path
    make_qr_code = output_path

End Function


Public Function save_permit_to_file(ByVal row_id As Integer, permit_type As String, out_path As String, Optional show_file As Boolean = True, Optional is_lodge_bus As Boolean = False) As String

    Dim qr_str As String: qr_str = savagedb.make_qr_str(row_id)
    Dim qr_path As String: qr_path = savagedb.make_qr_code(qr_str)
    
    If Len(out_path & "") = 0 Or left(out_path, 1) = "\" Then Exit Function ' The user canceled from the file dialog
    
    ' update last printed by and file_path columns for this record
    CurrentDb.Execute ("UPDATE road_permits SET file_path='" & out_path & "', last_printed_by='" & Environ$("username") & "'" & _
                       " WHERE id=" & row_id)
    
    ' Open the report and set it up for printing
    DoCmd.OpenReport "rpt_road_permit", acViewPreview ', OpenArgs:=permit_type & "," & qr_path
    
    ' Change the background color to match the colors in the app
    Dim rpt As Report: Set rpt = Reports("rpt_road_permit").Report

    Select Case permit_type
        Case Is = "Accessibility"
            rpt.Section(acPageHeader).BackColor = RGB(128, 110, 171)
        Case Is = "Employee"
            rpt.Section(acPageHeader).BackColor = RGB(194, 89, 99)
        Case Is = "Right of Way"
            If is_lodge_bus Then
                rpt.Section(acPageHeader).BackColor = RGB(145, 90, 119)
            Else
                rpt.Section(acPageHeader).BackColor = RGB(0, 0, 0)
                rpt.Controls("txt_title").ForeColor = RGB(255, 255, 255)
                rpt.Controls("txt_permit_number").ForeColor = RGB(255, 255, 255)
            End If
        Case Is = "NPS Approved"
            rpt.Section(acPageHeader).BackColor = RGB(83, 123, 158)
        Case Is = "NPS Contractor"
            rpt.Section(acPageHeader).BackColor = RGB(158, 158, 158)
        Case Is = "Pro Photography and Film"
            rpt.Controls("txt_title").TopMargin = 0
            rpt.Section(acPageHeader).BackColor = RGB(212, 138, 68)
        Case Is = "Subsistence"
            rpt.Section(acPageHeader).BackColor = RGB(214, 204, 45)
        Case Else
            rpt.Section(acPageHeader).BackColor = RGB(255, 255, 255)
    End Select

    ' Set the path of the qr code image
    rpt.Controls("img_qr").Picture = qr_path
    
    ' Save to file and close it
    DoCmd.OutputTo acOutputReport, "rpt_road_permit", acFormatPDF, out_path, show_file
    DoCmd.Close acReport, "rpt_road_permit", acSaveNo
    
    ' delete qr.png
    Kill qr_path
    
    ' Deselect all permits
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = 0;")
    
    save_permit_to_file = out_path ' return the path
    
End Function


Public Function restart_db(uid As String, pwd As String) As Integer
        
    Const TIMEOUT = 5 ' seconds to wait before quitting the restart script
    
    response = MsgBox("To log in as a different user, the database will need to restart (I know," & _
              " Access is pretty annoying, right?). Any changes you've made to forms, reports, etc. will be automatically saved." & _
              " Would you like to close and re-open the database now?", _
              vbYesNoCancel + vbQuestion, _
              "Restart the database?")
    restart_db = response
    If response = vbYes Then
        ' reset connection
        savagedb.set_read_write uid, pwd
        
        ' run script to reopen db once it's closed
        Dim cmd As String: cmd = SCRIPT_DIR & "\open_db.cmd " & Application.CurrentProject.FullName & " " & TIMEOUT
        Shell cmd, vbHide
        
        Application.Quit
    
    End If
        
End Function
