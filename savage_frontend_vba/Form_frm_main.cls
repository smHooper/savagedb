VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database
Function IsTable(sTblName As String) As Boolean
    'does table exists and work ?
    'note: finding the name in the TableDefs collection is not enough,
    '      since the backend might be invalid or missing

    On Error GoTo handler
    Dim X
    X = DCount("*", sTblName)
    IsTable = True
    Exit Function
handler:
    Debug.Print Now, sTblName, Err.Number, Err.Description
    IsTable = False

End Function
Public Function create_temp_table(table_name As String, sql_str As String)
    On Error Resume Next 'GoTo ErrorHandler
    
    'Delete the table if it exists
    DoCmd.DeleteObject acTable, strTable
    
    'On Error Resume Next
    ' Create the table and populate with values
    CurrentDb.Execute sql_str
    
    Dim exists As Boolean
    exists = IsTable(table_name)
    Exit Function
    
ErrorHandler:
    If Err.Number = 7874 Then
        Resume Next 'Tried to delete a non-existing table, resume
    End If
End Function
Private Function open_db_file_picker() As String
'NOTE: To use this code, you must reference
'The Microsoft Office 16.0 (or current version)
'Object Library by clicking menu Tools > References
'   -Check the box for Microsoft Office 16.0 Object Library
'   -Click OK

    With Application.FileDialog(msoFileDialogFilePicker)
        .title = "Select an Access database to import objects from"
        .Filters.Add "Access Database files", "*.accdb; *.mdb", 1
        
        If .Show Then
            open_db_file_picker = .SelectedItems(1)
        End If
        
    End With
End Function


Function list_objects(db As DAO.Database) As Dictionary
    'On Error GoTo Error_Handler
    Dim rs As DAO.Recordset
    Dim sSQL As String
    Dim object_types As New Dictionary
    
    sSQL = "SELECT MsysObjects.Name AS object_name, MsysObjects.Type AS object_type " & _
                  "FROM MsysObjects " & _
                  "WHERE (MsysObjects.Name Not Like '~*') And (MsysObjects.Name Not Like 'MSys*') " & _
                  "ORDER BY MSysObjects.Name;"
 
    Set rs = db.OpenRecordset(sSQL)
    With rs
        If .RecordCount <> 0 Then
            Do While Not .EOF
                Debug.Print ![object_name]
                Debug.Print ![object_type]
                'Debug.Print object_types.
                'object_types.Add ![object_name], ![object_type]
                .MoveNext
            Loop
        End If
    End With
 
Error_Handler_Exit:
    On Error Resume Next
    If Not rs Is Nothing Then
        rs.Close
        Set rs = Nothing
    End If
    If Not db Is Nothing Then Set db = Nothing
    Exit Function
 
Error_Handler:
    MsgBox "The following error has occured" & vbCrLf & vbCrLf & _
           "Error Number: " & Err.Number & vbCrLf & _
           "Error Source: ListObjects" & vbCrLf & _
           "Error Description: " & Err.Description & _
           Switch(Erl = 0, "", Erl <> 0, vbCrLf & "Line No: " & Erl) _
           , vbOKOnly + vbCritical, "An Error has Occured!"
    Resume Error_Handler_Exit
End Function

Private Sub btn_import_objects_Click()
' Import all access objects (tables, queries, forms, reports, modules, and macros) if they don't
' exist in the current DB (i.e., there is no object of same type and name).
    
    On Error GoTo err_handler
    
    
    Dim current_db As DAO.Database
    Dim other_db As DAO.Database
    Dim other_app As Access.Application
    Dim tdf As DAO.TableDef
    Dim qdf As DAO.QueryDef
    Dim frm As Form
    Dim rpt As Report
    Dim mdl As Module
    Dim object_name As String
    Dim current_objects As New Dictionary
    
    ' Get dictionaries of all access objects. Append type to name in case there are
    '   multiple objects with the same name but different types
    Set current_db = CurrentDb()
    For Each tdf In current_db.TableDefs
        object_name = tdf.Name
        current_objects.Add object_name, acTable
    Next tdf
    
    For Each qdf In current_db.QueryDefs
        object_name = qdf.Name
        current_objects.Add object_name, acQuery
    Next qdf
    
    Dim obj As AccessObject
    For Each obj In CurrentProject.AllForms
        object_name = obj.Name
        current_objects.Add object_name, acForm
    Next obj
    
    For Each rpt In Reports
        object_name = rpt.Name
        current_objects.Add object_name, acReport
    Next rpt

    For Each obj In CurrentProject.AllModules
        object_name = obj.Name
        current_objects.Add object_name, acModule
    Next obj
    
    For Each obj In CurrentProject.AllMacros
        object_name = obj.Name
        current_objects.Add object_name, acMacro
    Next obj
    
    ' Let the user select a DB to import from
    Dim selected_file As String
    selected_file = savagedb.open_file_dialog("Select an Access database file to import from", _
                                              msoFileDialogFilePicker, _
                                              "*.accdb; *.mdb", _
                                              "Access Database files")
    If Len(selected_file) = 0 Then
        Exit Sub
    End If
    
    Dim imports As New Dictionary
    Dim do_import As Boolean: do_import = False
    Dim rs As DAO.Recordset
    Dim sql_str As String
    Dim object_type As Integer
    Dim ac_object_type As Integer
    
    ' Map msyobjects.type values to vbAccessObject types because they're not the same
    Dim valid_types As New Dictionary
    valid_types.Add 1, acTable ' local table
    valid_types.Add 6, acTable ' Linked table
    valid_types.Add 4, acTable ' ODBC-linked table
    valid_types.Add 5, acQuery
    valid_types.Add -32768, acForm
    valid_types.Add -32764, acReport
    valid_types.Add -32761, acModule
    valid_types.Add -32766, acMacro
    
    Dim i As Integer
    Set other_app = New Access.Application
    With other_app
        .OpenCurrentDatabase selected_file
        Set other_db = .CurrentDb()
        'Set imports = list_objects(other_db)
        sql_str = "SELECT MSysObjects.Name AS object_name, MSysObjects.Type AS object_type " & _
                  "FROM MSysObjects " & _
                  "WHERE (MSysObjects.Name Not Like '~*') And (MSysObjects.Name Not Like 'MSys*') " & _
                  "ORDER BY MSysObjects.Name;"
        Set rs = other_db.OpenRecordset(sql_str, dbOpenSnapshot)
        If rs.RecordCount <> 0 Then
            Do While Not rs.EOF
                object_name = rs![object_name].Value
                object_type = rs![object_type].Value
                If object_name Like "f_*_Data" Then
                    GoTo continue_do ' some forms create weird table objects, so ignore them
                End If
                If valid_types.exists(object_type) Then
                    ac_object_type = valid_types(object_type)
                    If current_objects.exists(object_name) Then
                        ' If the object shares the same name as something in the current db but is of a different type
                        ' import it
                        If current_objects(object_name) <> ac_object_type Then
                            ' Add the type in case there are two objects with different types and the same name
                            do_import = True
                        End If
                    ' If the object doesn't exist at all, also import it
                    Else
                        do_import = True
                    End If
                End If
                If do_import Then
                imports.Add object_name & Str(ac_object_type), ac_object_type
                End If
                do_import = False
                
continue_do: ' Called if continuing to next row of record set or if we get to the end of the while iteration
            rs.MoveNext
            Loop
        End If
        other_db.Close
        .CloseCurrentDatabase
        .DoCmd.Quit acQuitSaveNone
    End With
    ' Don't set the other_app to Nothing. Otherwise, it doesn't open blocking the view of the current app
    '   despite calls to .Quit
    'Set other_app = Nothing
    Set other_db = Nothing
    

    Dim import_strs As New Dictionary
    import_strs.Add acTable, ""
    import_strs.Add acQuery, ""
    import_strs.Add acForm, ""
    import_strs.Add acReport, ""
    import_strs.Add acModule, ""
    import_strs.Add acMacro, ""
    
    For i = 0 To imports.Count - 1
        object_type = imports(imports.Keys(i))
        object_name = Replace(imports.Keys(i), Str(object_type), "") ' remove type from name
        DoCmd.TransferDatabase TransferType:=acImport, _
                               DatabaseType:="Microsoft Access", _
                               DatabaseName:=selected_file, _
                               ObjectType:=object_type, _
                               source:=object_name, _
                               destination:=object_name
        import_strs(object_type) = import_strs(object_type) & object_name & ", "
    Next i

    Dim access_objects As New Dictionary
    access_objects.Add acTable, "Tables"
    access_objects.Add acQuery, "Queries"
    access_objects.Add acForm, "Forms"
    access_objects.Add acReport, "Reports"
    access_objects.Add acModule, "Modules"
    access_objects.Add acMacro, "Macros"
    If imports.Count = 0 Then
        MsgBox "No Access objects found that do not exist in the current database.", vbInformation, "Import complete"
    Else
        Dim msg As String: msg = "Import completed for the following Access objects:" & vbCrLf
        ' Loop through each object type in the dict. If the string isn't empty, add it to the message.
        For i = 0 To import_strs.Count - 1
            object_type = import_strs.Keys(i)
            If Len(import_strs(object_type)) > 0 Then
                msg = msg & access_objects(object_type) & " - " & Replace(import_strs(object_type), ", ", "", Count:=1) & vbCrLf
            End If
        Next i
        MsgBox msg, vbInformation, "Import complete"

    End If
    
    Exit Sub
    
err_handler:
    If Err.Number = 457 Then ' Item exists in collection
        MsgBox "There are at least two objects with the name '" & object_name & "' in the current database. " & _
               "To import objects from another database, all names in the currently open database must be unique. " & _
               "Change at least one of them so all objects have unique names.", _
               vbCritical, _
               "Object name error"
        Exit Sub
    Else
        MsgBox "Error encountered in while importing objects from another database:" & vbCrLf & _
                "Error Description: " & Err.Description & _
                Switch(Erl = 0, "", Erl <> 0, vbCrLf & "Line No: " & Erl), _
               vbCritical, _
               "Error btn_import_objects_Click"
    End If

End Sub

Private Sub btn_login_admin_Click()
    
    Dim current_user_state As String
    current_user_state = savagedb.get_user_state()
    
    Dim response As Integer
    If current_user_state <> "read" Then ' The user is signed in either as admin or permit user
        ' Run the restart script only if the user selected "Yes". Othwerwise, exit
        response = restart_db("savage_read", "0l@usmur!e")
        If response <> vbYes Then
            DoCmd.Close acForm, Me.Name
            Exit Sub
        End If
        
'        response = MsgBox("To log in as a different user, the database will need to close and you'll have to re-open it (I know, " & _
'              "Access is pretty annoying, right?). Would you like to close and re-open the database now?", _
'              vbYesNoCancel, _
'              "Close and re-open database?")
'        If response = vbYes Then
'            ' Just set privileges (to read-only) and exit
'            savagedb.set_read_write "savage_read", "0l@usmur!e"
'            Application.Quit
'        End If
    Else
        DoCmd.OpenForm "frm_login" ' Defaults to expect admin credentials
    End If

End Sub

Function min_value(v1 As Double, v2 As Double) As Double
    If v1 <= v2 Then
        min_value = v1
    Else
        min_value = v2
    End If
End Function


Private Sub btn_query_plot_Click()

    If Me.dpd_query.Visible Then
        Me.dpd_query.Visible = False
        Me.dpd_query = "Select a query option"
    Else
        Me.dpd_query.Visible = True
    End If

End Sub



Private Sub dpd_query_AfterUpdate()
' If any of the preset queries were selected, pre-fill the query/plot form
    
    'Dim selection As String: Me.dpd_query
    Dim plot_form As Form
    DoCmd.OpenForm "frm_query_plot"
    Set plot_form = Forms.frm_query_plot
    
    Select Case Me.dpd_query
        Case Is = "Last week by day"
            plot_form.Form.txt_start_date = DateAdd("d", -7, Date)
            plot_form.Form.txt_end_date = Date
            plot_form.Form.dpd_time_step = "Day"
            Form_frm_query_plot.select_all_checkboxes "chk_query*"
            plot_form.Form.chk_plot_stacked = True
            plot_form.Form.chk_optplot_limits = True
        Case Is = "Current year's summary"
            plot_form.Form.txt_start_date = "5/1/" & year(Now)
            plot_form.Form.txt_end_date = CDate(min_value(Int(Date), Int(CDate("9/15/" & year(Now)))))
            plot_form.Form.dpd_time_step = "Year"
            plot_form.Form.chk_query_summary = True
            plot_form.Form.chk_plot_grouped = True
            plot_form.Form.chk_optquery_dates = True
            plot_form.Form.txt_custom_title = "Total vehicles past Savage this season as of " & Split(Now)(0)
        Case Is = "GMP vehicles by year"
            plot_form.Form.txt_start_date = "5/1/1997"
            plot_form.Form.txt_end_date = CDate(min_value(Int(Date), Int(CDate("9/15/" & year(Now)))))
            plot_form.Form.dpd_time_step = "Year"
            plot_form.Form.chk_query_summary = True
            plot_form.Form.chk_plot_stacked = True
            plot_form.Form.chk_optquery_dates = True
            plot_form.Form.chk_optquery_vehicles = True
            plot_form.Form.chk_optplot_limits = True
            plot_form.Form.chk_filter_values = True
            plot_form.Form.txt_custom_title = "GMP vehicles past Savage by year, 1997-" & year(Now)
            Form_frm_query_plot.show_hide_filters
            plot_form.Form.txt_category_filter = "Long tour, VTS, Other JV bus, Lodge bus, GOV, POV"
        Case Is = "Lodge passengers/month"
            plot_form.Form.txt_start_date = "5/1/" & year(Now)
            plot_form.Form.txt_end_date = CDate(min_value(Int(Date), Int(CDate("9/15/" & year(Now)))))
            plot_form.Form.dpd_time_step = "Month"
            plot_form.Form.dpd_summary_stat = "sum"
            plot_form.Form.dpd_summary_field = "n_passengers"
            plot_form.Form.chk_query_buses = True
            plot_form.Form.chk_plot_grouped = True
            plot_form.Form.chk_filter_values = True
            Form_frm_query_plot.show_hide_filters
            plot_form.Form.txt_sql_filter = "KRH, CDN, DBL"
            plot_form.Form.txt_custom_title = "Lodge passengers by month, May-" & _
                                              MonthName(Int(Split(Now, "/")(0)), True) & " " & year(Now)
        Case Is = "Lodge buses/month"
            plot_form.Form.txt_start_date = "5/1/" & year(Now)
            plot_form.Form.txt_end_date = CDate(min_value(Int(Date), Int(CDate("9/15/" & year(Now)))))
            plot_form.Form.dpd_time_step = "Month"
            plot_form.Form.chk_query_buses = True
            plot_form.Form.chk_plot_grouped = True
            plot_form.Form.chk_filter_values = True
            Form_frm_query_plot.show_hide_filters
            plot_form.Form.txt_sql_filter = "KRH, CDN, DBL"
            plot_form.Form.txt_custom_title = "Lodge buses by month, May-" & _
                                              MonthName(Int(Split(Now, "/")(0)), True) & " " & year(Now)
        Case Is = "NPS vehicles this year"
            plot_form.Form.txt_start_date = "5/1/" & year(Now)
            plot_form.Form.txt_end_date = CDate(min_value(Int(Date), Int(CDate("9/15/" & year(Now)))))
            plot_form.Form.dpd_time_step = "Year"
            plot_form.Form.chk_query_nps = True
            plot_form.Form.chk_plot_grouped = True
            plot_form.Form.txt_custom_title = "NPS vehicles past Savage this season as of " & Split(Now)(0)
        Case Is = "Bikes/year since 2010"
            plot_form.Form.txt_start_date = "5/1/2010"
            plot_form.Form.txt_end_date = CDate(min_value(Int(Date), Int(CDate("9/15/" & year(Now)))))
            plot_form.Form.dpd_time_step = "Year"
            plot_form.Form.chk_query_bikes = True
            plot_form.Form.dpd_summary_stat = "sum"
            plot_form.Form.dpd_summary_field = "n_passengers"
            plot_form.Form.txt_custom_title = "Bikes past Savage by year, 2010-" & year(Now)
        Case Is = "Custom query"
            ' do nothing
            Dim a As String: a = "a"
        Case Else
            Dim response As Integer
            response = MsgBox("The query was not understood. Would you like to open the query/plot form anyway " & _
                              "and set all parameters yourself?", _
                              vbYesNo, _
                              "Invalid query name")
            If response = vbNo Then
                DoCmd.Close acForm, "frm_query_plot"
            End If
    
    End Select
    
    Me.dpd_query = "Select a query option"
    Me.btn_query_plot.SetFocus
    Me.dpd_query.Visible = False
    
    DoCmd.RepaintObject acForm, "frm_query_plot"


exit_err:
    On Error Resume Next
    Exit Sub

err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_err

End Sub


Private Sub btn_permits_Click()
    
    On Error GoTo err_handler

    If savagedb.get_user_state() = "admin" Then
        DoCmd.OpenForm "frm_permit_menu"
        Forms!frm_permit_menu!btn_logout.Enabled = False
    Else
        DoCmd.OpenForm "frm_login", acNormal
        Forms!frm_login!lbl_login_type.Caption = "permit"
    End If

exit_err:
    Exit Sub

err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_err


End Sub

Private Sub Command48_Click()
    test_connection
End Sub

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


Private Function check_version()
    
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



Private Sub Form_Open(Cancel As Integer)
' Check the user state. If the user is logged in as "admin", warn them.
' Also set the log in/out button accordingly
    On Error GoTo err_handler
    
    ' Check connection
    If Not test_connection() Then GoTo bad_connection
    
    Dim user_state As String
    user_state = savagedb.get_user_state()
    
    If user_state = "admin" Then
        MsgBox "You are currently logged in as an administrator. Database records are now editable, and " & _
               "all edits are permanent. To log out as an administrator, click the 'Log in as read-only' button.", _
               vbExclamation, _
               "Logged in as administrator"
        Me.btn_login_admin.Caption = "Log in as read-only"
        Me.btn_open_edit_inholders_form.Enabled = True
    ElseIf user_state = "permit" Then
        'Notify user that they can edit permits and nothing else
        DoCmd.Close acForm, Me.Name
        MsgBox "You are currently logged in as a permit administrator. You can edit permit info in the road_permits table only, " & _
               " but no other tables are editable. To log out as an administrator, click the 'Log out' button.", _
               vbExclamation, _
               "Logged in as permit administrator"
        DoCmd.OpenForm "frm_permit_menu"
        
        ' Hide nav pane
        DoCmd.NavigateTo ("acNavigationCategoryObjectType")
        DoCmd.RunCommand (acCmdWindowHide)
    Else
        Me.btn_login_admin.Caption = "Log in as admin"
        Me.btn_open_edit_inholders_form.Enabled = False
        
        ' Hide nav pane
        DoCmd.NavigateTo ("acNavigationCategoryObjectType")
        DoCmd.RunCommand (acCmdWindowHide)
    End If
    
    ' Check to see if there's a later version and prompt the user if so
    check_version
    
    Exit Sub


bad_connection:
        MsgBox "The front end database application could not connect to the back-end database." & _
               " Check your network connection, then close and re-open the front end application to try again.", _
               vbCritical, _
               "Could not connect to back-end database"
        Exit Sub

exit_err:
    On Error Resume Next
    current_db.Close
    Set current_db = Nothing
    Exit Sub

err_handler:
    If Err.Number = -2147467259 Or Err.Description Like "*Could not connect*" Then
        GoTo bad_connection
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err
    
End Sub

