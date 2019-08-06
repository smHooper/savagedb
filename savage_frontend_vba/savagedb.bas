Attribute VB_Name = "savagedb"
Option Compare Database
Public Const CONNECTION_STR = "DRIVER={PostgreSQL ANSI};DATABASE=db_name;SERVER=ip_address;PORT=port"
Public Const PYTHON_PATH = "C:\ProgramData\Anaconda3\envs\savagedb\python.exe"
Public Const CONNECTION_TXT = "C:\users\shooper\proj\savagedb\connection_info.txt"
Public Const SCRIPT_DIR = "C:\users\shooper\proj\savagedb\git\scripts"
Public Const MASTER_DB_DIR = "C:\Users\shooper\proj\savagedb\db\test" '"D:\savage"


Public Function parse_parameter_file(path As String, Optional delimiter As String = ";") As Dictionary
    
    Dim fso As Object
    Dim text_file As Object

    Set fso = CreateObject("Scripting.FileSystemObject")
    Set text_file = fso.OpenTextFile(path, 1)
    lines = Split(text_file.ReadAll(), vbCrLf)
    text_file.Close
    
    Dim parameters As New Dictionary
    Dim line As Variant
    For Each line In lines
        If line Like "*" & delimiter & "*" Then parameters(Trim(Split(line, delimiter)(0))) = Trim(Split(line, delimiter)(1))
    Next line
    
    Set parse_parameter_file = parameters

End Function

Public Function get_connection_str(Optional user_key As String) As String

    Dim conn_str As String
    Dim conn_info As New Dictionary: Set conn_info = parse_parameter_file(CONNECTION_TXT)
    conn_str = Replace(Replace(Replace(CONNECTION_STR, "db_name", conn_info("db_name")), "ip_address", conn_info("ip_address")), "port", conn_info("port"))
    
    Dim credential_info As New Dictionary: Set credential_info = parse_parameter_file(Replace(CONNECTION_TXT, "connection_info.txt", "savage_db_credentials.txt"))
    If Len(Nz(user_key, "")) Then
        conn_str = conn_str & ";UID=" & credential_info(user_key & "_un") & ";PWD=" & credential_info(user_key & "_pw") & ";"
    End If
    
    get_connection_str = conn_str

End Function


Public Function pass_through_query(sql_str As String, Optional return_records As Boolean, Optional conn_str As String) As ADODB.Recordset
    Dim connection As New ADODB.connection
    Dim record_set As New ADODB.Recordset
    Dim result As Long
    
    If Len(conn_str) Then
        connection.Open conn_str
    Else
        connection.Open get_connection_str() & ";Trusted_Connection=Yes"
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
        If logged_line Like "*Traceback*" Then
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

Public Function run_stdout_command(cmd As String) As String
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

    run_stdout_command = stdout_str
    
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
        If Left(definition.Name, Len(schemaName)) = schemaName Then
             'plus 2 to strip the _ as well
            definition.Name = Mid(definition.Name, Len(schemaName) + 2)
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
    
    Dim record_set As DAO.Recordset
    Dim user_state As String
    
    Set record_set = CurrentDb.OpenRecordset("Select login FROM user_state;")
    With record_set
        .MoveFirst
        user_state = record_set!login.Value
    End With
    Set record_set = Nothing
    
    get_user_state = user_state

End Function

Public Function set_read_write(new_user_state As String) As String 'Optional username As String, Optional password As String) As String

    On Error GoTo error_login
    
    ' Get the current user state from a local table
    Dim current_user_state As String
    current_user_state = get_user_state
    
    Dim new_cnn_str As String

    If Len(new_user_state) Then 'Len(username) And Len(password) Then
        new_cnn_str = "ODBC;" & get_connection_str(new_user_state)
    Else
        MsgBox "No username or password given", vbCritical, "Invalid arguments for savagedb.set_read_write()"
        set_read_write = ""
        Exit Function
    End If
    
    ' Relink all tables so they have the right permissions
    Dim tdf As DAO.TableDef
    For Each tdf In CurrentDb.TableDefs
        ' Only set the connection if it's an ODBC linked table
        If Left$(tdf.Connect, 5) = "ODBC;" Then
            tdf.Connect = new_cnn_str
            If tdf.Attributes < 537001984 Then
                tdf.Attributes = dbAttachSavePWD 'dbAttachSavePWD = 131072
            End If
            tdf.RefreshLink
        End If
    Next
    
    Dim qdf As QueryDef
    For Each qdf In CurrentDb.QueryDefs
        If Left$(qdf.Connect, 5) = "ODBC;" Then
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

Private Function test_connection() As Boolean
    
    On Error GoTo err_handler
    
    Dim db As DAO.Database
    Dim tdf As TableDef
    Dim current_cnn_str As String
    Set db = CurrentDb
    Set tdf = db.TableDefs("inholder_allotments")
    current_cnn_str = Right(tdf.Connect, Len(tdf.Connect) - 5)
    
    Dim cnn As ADODB.connection
    Set cnn = New ADODB.connection
    
    cnn.Open current_cnn_str
    If cnn.State = adStateOpen Then test_connection = True Else test_connection = False
    
    cnn.Close
 
exit_err:
    Exit Function

err_handler:
    ' If the error is anything other than a bad connection, show the error
    If Err.Number <> -2147467259 Then MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_err

End Function


Public Function read_change_log() As String
    
    Dim log_path As String: log_path = "D:\savage\" & Dir("D:\savage\change_log*.txt", vbHidden)
    If log_path = "D:\savage\" Then Exit Function
    
    Dim fso As Object
    Dim text_file As Object
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set text_file = fso.OpenTextFile(log_path, 1)
    log_str = text_file.ReadAll()
    text_file.Close
    
    Dim line As Variant
    Dim changes As String
    For Each line In Split(log_str, vbCrLf)
        If line Like "[!#]*" And Trim(line) <> "" Then changes = changes & line & vbCrLf
    Next line
    
    read_change_log = changes
    
End Function


Public Function check_version()
    
    Dim master_db_path As String: master_db_path = MASTER_DB_DIR & "\" & Dir(MASTER_DB_DIR & "\savage_frontend_v*.accdb")
    If master_db_path <> MASTER_DB_DIR & "\" Then
        Dim rs As Recordset: Set rs = CurrentDb.OpenRecordset("SELECT version FROM user_state;")
        rs.MoveFirst
        Dim this_version() As String: this_version = Split(rs.fields("version"), ".")
        Set rs = CurrentDb.OpenRecordset("SELECT version FROM user_state IN '" & master_db_path & "';")
        rs.MoveFirst
        Dim master_version() As String: master_version = Split(rs.fields("version"), ".")
        Set rs = Nothing
        
        Dim prompt_user As Boolean: prompt_user = False
        ' If they have different lengths, the versions aren't in the same format
        If UBound(this_version) = UBound(master_version) Then
            ' Loop through each version number decimal starting with the left side (highest level)
            
            Dim i As Integer
            For i = 0 To UBound(this_version)
                ' If the master version decimal is higher than the decimal of this version, prompt the user
                If Int(master_version(i)) > Int(this_version(i)) Then
                    Dim msg As String
                    msg = "A new version of the database is available at " & master_db_path & ". To take advantage of the latest functionality of the database, please" & _
                           " save a new copy of the latest version to your preferred location and use that for all future Savage database operations. If you created" & _
                           " queries, reports, or other Access objects in this old copy of the front end, use the 'Import objects from DB' button in your new copy" & _
                           " to continue using them in the new copy."
                    Dim changes As String: changes = read_change_log()
                    If changes <> "" Then msg = msg & vbCrLf & vbCrLf & "Changes for this version include:" & vbCrLf & vbCrLf & changes
                    MsgBox msg, vbInformation, "New version available"
                    Exit Function
                ' If the opposite is true, this version is new than the master (this should never actually happen)
                ElseIf Int(master_version(i)) < Int(this_version(i)) Then
                    Exit Function
                End If
            Next i
        End If
    End If

End Function


Public Function open_main_form()
' Check the user state, and open the appropriate form.
' If the user is logged in as "admin", warn them, and set the log in/out button accordingly
' Also warn the user if their version of the DB is outdated

    On Error GoTo err_handler
    
    ' Show the datbase version in the caption
    
    Dim rs As Recordset: Set rs = CurrentDb.OpenRecordset("SELECT version FROM user_state;")
    rs.MoveFirst
    
    Dim main_form As Form
    DoCmd.OpenForm "frm_main"
    Set main_form = Forms("frm_main").Form
    main_form.Caption = "Savage Check Station Database Main Menu - " & Nz(rs.fields("version"), "")
    Set rs = Nothing
    
    ' Check connection
    If Not test_connection() Then GoTo bad_connection
    
    Dim user_state As String
    user_state = savagedb.get_user_state()
    
    If user_state = "admin" Then
        MsgBox "You are currently logged in as an administrator. Database records are now editable, and " & _
               "all edits are permanent. To log out as an administrator, click the 'Log in as read-only' button.", _
               vbExclamation, _
               "Logged in as administrator"
        main_form.btn_login_admin.Caption = "Log in as read-only"
        main_form.btn_open_edit_inholders_form.Enabled = True
    ElseIf user_state = "permit" Then
        'Notify user that they can edit permits and nothing else
        DoCmd.Close acForm, main_form.Name
        MsgBox "You are currently logged in as a permit administrator. You can edit permit info in the road_permits table only, " & _
               " but no other tables are editable. To log out as an administrator, click the 'Log out' button.", _
               vbExclamation, _
               "Logged in as permit administrator"
        DoCmd.OpenForm "frm_permit_menu"
        
        ' Hide nav pane
        DoCmd.NavigateTo ("acNavigationCategoryObjectType")
        DoCmd.RunCommand (acCmdWindowHide)
    Else
        GoTo default_open
    End If
    
    ' Check to see if there's a later version and prompt the user if so
    check_version
    
    Exit Function


default_open:
    
    main_form.btn_login_admin.Caption = "Edit vehicle data in tables"
    main_form.btn_open_edit_inholders_form.Enabled = False
    
    ' Hide nav pane
    DoCmd.NavigateTo ("acNavigationCategoryObjectType")
    DoCmd.RunCommand (acCmdWindowHide)
    
    ' Check to see if there's a later version and prompt the user if so
    check_version
    
    Exit Function

bad_connection:
    MsgBox "The front end database application could not connect to the back-end database." & _
           " Check your network connection, then close and re-open the front end application to try again.", _
           vbCritical, _
           "Could not connect to back-end database"
    GoTo default_open
    Exit Function

exit_err:
    On Error Resume Next
    current_db.Close
    Set current_db = Nothing
    Exit Function

err_handler:
    If Err.Number = -2147467259 Or Err.Description Like "*Could not connect*" Then
        GoTo bad_connection
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err

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


Public Function open_file_dialog(Optional ByVal title As String = "Select an output folder", _
                                 Optional ByVal dialog_type As Integer = msoFileDialogFolderPicker, _
                                 Optional ByVal filter_str As String = "", _
                                 Optional ByVal filter_name As String = "", _
                                 Optional ByVal allows_multiple As Boolean = False, _
                                 Optional ByVal initial_view As Integer = msoFileDialogViewDetails) As String
'NOTE: To use this code, you must reference
'The Microsoft Office 16.0 (or current version)
'Object Library by clicking menu Tools > References
'   -Check the box for Microsoft Office 16.0 Object Library
'   -Click OK
    
    Dim selection As Variant
    Dim selected_string As String
    Dim item As Variant
    With Application.FileDialog(dialog_type)
        .title = title
        .AllowMultiSelect = allows_multiple
        .InitialView = msoFileDialogViewDetails ' For some stupid reason, it always opens as large icon view
        
        If Len(Nz(filter_str)) > 0 Then
            .Filters.Add filter_name, filter_str, 1
        End If
        
        If .Show Then
            For Each item In .SelectedItems
                selected_string = selected_string & item & "|"
            Next item
            If Right(selected_string, 1) = "|" Then selected_string = Left(selected_string, Len(selected_string) - 1)
            open_file_dialog = selected_string
        End If
        
    End With

End Function

Public Function export_vba_code(Optional out_dir As String = "")

    Dim c As VBComponent
    Dim ext As String
    'Dim out_dir As String
    
    If out_dir & "" = "" Then
        out_dir = CurrentProject.path & "\" & Left(CurrentProject.Name, InStrRev(CurrentProject.Name, ".") - 1) & "_vba"
    End If
    
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
            c.Export FileName:=out_dir & "\" & c.Name & ext
        End If
    Next c

End Function

Public Function get_inholder_name(inholder_code As String) As String
    
    Dim rs As Recordset
    Set rs = CurrentDb.OpenRecordset("SELECT inholder_name FROM inholder_allotments WHERE inholder_code = '" & inholder_code & "';")
    rs.MoveFirst
    If rs.RecordCount > 0 Then
        get_inholder_name = Nz(rs.fields("inholder_name"), "")
    Else
        get_inholder_name = ""
    End If
    
    Set rs = Nothing

End Function


Public Function make_qr_str(id_number As Integer) As String
' Return a JSON string that the app will be able to read

    Dim qr_str As String
    Dim rs As Recordset
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM road_permits WHERE id = " & id_number, dbOpenSnapshot)
    
    rs.MoveLast
    If rs.RecordCount <> 1 Then
        MsgBox "Error occurred while making QR code string. No permit found with ID " & id_number, vbCritical, "QR code error"
        make_qr_str = ""
        Exit Function
    End If
    
    Dim inholder_name As String
    Dim q As String: q = """""" ' this will produce a double quote ("") in the cmd
    Dim vehicle_type As String: vehicle_type = rs.fields("permit_type")
    Select Case vehicle_type
        Case Is = "Right of Way"
            inholder_name = get_inholder_name(rs.fields("permit_number_prefix"))
            If rs.fields("is_lodge_bus") Then
                qr_str = "{" & q & "vehicle_type" & q & ": " & q & "Lodge Bus" & q & "," & _
                         " " & q & "Lodge" & q & ": " & q & inholder_name & q & ","
            Else
                qr_str = "{" & q & "vehicle_type" & q & ": " & q & "Right of Way" & q & "," & _
                         " " & q & "Inholder name" & q & ": " & q & inholder_name & q & "," '& _
                         '" " & q & "Driver's full name" & q & ": " & q & rs.fields("permit_holder") & q & ","
            End If
        Case Is = "NPS Approved"
            qr_str = "{" & q & "vehicle_type" & q & ": " & q & "NPS Approved" & q & "," & _
                     " " & q & "Approved category" & q & ": " & q & rs.fields("approved_type") & q & ","
            If rs.fields("approved_type") = "Researcher" Then
                qr_str = qr_str & q & "Driver's full name" & q & ": " & q & rs.fields("permit_holder") & q & ","
            End If
        Case Is = "NPS Contractor"
            qr_str = "{" & q & "vehicle_type" & q & ": " & q & "NPS Contractor" & q & "," & _
                     " " & q & "Company/Organization name" & q & ": " & q & rs.fields("permit_holder") & q & ","
        Case Is = "Pro Film/Photo"
            qr_str = "{" & q & "vehicle_type" & q & ": " & q & "Photographer" & q & "," & _
                     " " & q & "Driver's full name" & q & ": " & q & rs.fields("permit_holder") & q & ","
        Case Else ' Accessibility, Employee, Subsistence
            qr_str = "{" & q & "vehicle_type" & q & ": " & q & vehicle_type & q & "," & _
                     " " & q & "Driver's full name" & q & ": " & q & rs.fields("permit_holder") & q & ","
    End Select
    
    Dim n_days As Integer: n_days = DateDiff("d", rs.fields("date_in"), rs.fields("date_out"))
    'qr_str = qr_str & " " & q & "Number of expected nights" & q & ": " & q & n_days & q & ","
    'Dim permit_number As String: permit_number = Replace(Me.lbl_permit_number.Caption, "Permit #: ", "")
    
    If Not qr_str Like "*Permit holder: *" Then qr_str = qr_str & " " & q & "Permit holder" & q & ": " & q & rs.fields("permit_holder") & q & ", "
    qr_str = qr_str & " " & q & "Permit number" & q & ": " & q & rs.fields("permit_number_prefix") & rs.fields("permit_number") & q & "}"
    make_qr_str = qr_str
    Debug.Print qr_str

End Function



Public Function make_qr_code(qr_str As String, Optional output_path As String) As String
    
    'Debug.Print qr_str
    
    ' Get the path of the qr executable
    Dim qr_exe_path As String: qr_exe_path = Left(PYTHON_PATH, InStrRev(PYTHON_PATH, "\")) & "Scripts\qr.exe"
    
    ' If an output path wasn't given, just use the dir where the DB is
    If Len(output_path & "") = 0 Then output_path = CurrentProject.path & "\qr.png"
    
    ' Make and run the command, piping the output to the output path
    Dim cmd As String: cmd = qr_exe_path & " """ & qr_str & """ > " & output_path
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
    
    If Len(out_path & "") = 0 Or Left(out_path, 1) = "\" Then Exit Function ' The user canceled from the file dialog
    
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
            rpt.Controls("txt_title").ForeColor = RGB(255, 255, 255)
            rpt.Controls("txt_permit_number").ForeColor = RGB(255, 255, 255)
        Case Is = "Employee"
            rpt.Section(acPageHeader).BackColor = RGB(194, 89, 99)
        Case Is = "Right of Way"
            If is_lodge_bus Then
                rpt.Section(acPageHeader).BackColor = RGB(145, 90, 119)
            Else
                rpt.Section(acPageHeader).BackColor = RGB(0, 0, 0)
            End If
            rpt.Controls("txt_title").ForeColor = RGB(255, 255, 255)
            rpt.Controls("txt_permit_number").ForeColor = RGB(255, 255, 255)
        Case Is = "NPS Approved"
            rpt.Section(acPageHeader).BackColor = RGB(83, 123, 158)
            rpt.Controls("txt_title").ForeColor = RGB(255, 255, 255)
            rpt.Controls("txt_permit_number").ForeColor = RGB(255, 255, 255)
        Case Is = "NPS Contractor"
            rpt.Section(acPageHeader).BackColor = RGB(158, 158, 158)
        Case Is = "Pro Film/Photo"
            'rpt.Controls("txt_title").TopMargin = 0
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
    CurrentDb.Execute ("UPDATE permit_menu_source SET select_permit = 0;")
    
    save_permit_to_file = out_path ' return the path
    
End Function


Public Function restart_db(user_key As String) As Integer
        
    Const TIMEOUT = 5 ' seconds to wait before quitting the restart script
    
    response = MsgBox("To log in as a different user, the database will need to restart (I know," & _
              " Access is pretty annoying, right?). Any changes you've made to forms, reports, etc. will be automatically saved." & _
              " Would you like to close and re-open the database now?", _
              vbYesNoCancel + vbQuestion, _
              "Restart the database?")
    restart_db = response
    If response = vbYes Then
        ' reset connection
        savagedb.set_read_write user_key
        
        ' run script to reopen db once it's closed
        Dim cmd As String: cmd = SCRIPT_DIR & "\open_db.cmd " & Application.CurrentProject.FullName & " " & TIMEOUT
        Shell cmd, vbHide
        
        Application.Quit
    
    End If
        
End Function


Public Function make_road_permit_number(Optional inholder_code As String = "") As String
' Helper function to create a permit number. Because the number is prepended with a 2-digit year,
' this requires a lot of regex replacement so the permit numbers start over each year

    ' Run a query to get all permit numbers with leading inholder codes (if there is one) removed
    Dim rs As ADODB.Recordset
    Dim db As DAO.Database
    Dim tdf As TableDef
    Dim current_cnn_str As String
    Dim sql As String
    Set db = CurrentDb
    Set tdf = db.TableDefs("inholder_allotments")
    current_cnn_str = Right(tdf.Connect, Len(tdf.Connect) - 5)
    '############################################################
    'Change permit_number column into 2 columns, number and prefix. Then I won't have to use this regex_replace expression
    'sql = "SELECT regexp_replace(permit_number, '[A-Z]{3}', '')::int AS id FROM road_permits ORDER BY 1"
    sql = "SELECT permit_number FROM road_permits ORDER BY 1"
    Set rs = savagedb.pass_through_query(sql, True, current_cnn_str)
    
    ' Get the id of the last record
    rs.MoveLast
    Dim max_id As Long
    If rs.RecordCount > 0 Then
        max_id = rs.fields("permit_number") + 1
    Else
        get_permit_number = ""
        Set rs = Nothing
        Exit Function
    End If
    Set rs = Nothing
    
    ' Strip the 2-digit year and all leading 0s from the id
    Dim year_str As String: year_str = Right(Str(year(Now())), 2)
    Dim id_number As String
    Dim re As RegExp
    Set re = New RegExp
    With re
        .Global = True
        .pattern = "\d{2}0{0:4}"
        id_number = .Replace(Str(max_id), "")
    End With
    
    ' Add the current 2-digit year
    id_number = year_str & Right("0000" & Int(id_number), 5)
    
    If Not (Len(inholder_code) = 0 Or inholder_code = "NUL") Then id_number = inholder_code & id_number
    
    make_road_permit_number = id_number

End Function

