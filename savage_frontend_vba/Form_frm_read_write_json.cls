VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_read_write_json"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database


Private Sub btn_open_json_filepicker_Click()

    generic.open_file_dialog Me.txt_json_path, "Select a JSON configuration file", msoFileDialogFilePicker, _
                             "*.json", "JSON files"

End Sub

Private Function set_subform_source(ByRef Form As SubForm, source As String)
' Convience function to remove link to temporary database

    Form.SourceObject = source

End Function

Private Function reset_temp_db(temp_dir As String)

    set_subform_source Me.sub_dropdown_options, Me.name & "_sub"
    'set_subform_source Me.sub_field_properties, Me.name & "_sub"
    
    ' If the temp dir exists, delete it and re-make it
    If Dir(temp_dir, vbDirectory + vbHidden) <> "" Then
        If Dir(temp_dir & "\*.*") <> "" Then
            Kill temp_dir & "\*.*"
        End If
    Else
        MkDir temp_dir
    End If

End Function


Private Function load_json_config_from_csvs(temp_db_path As String)
    
    On Error GoTo err_handler
    
    Dim temp_dir As String: temp_dir = left(temp_db_path, InStrRev(temp_db_path, "\") - 1)
    Dim current_db As DAO.Database
    Dim temp_db As DAO.Database
    Dim temp_app As Access.Application
    Dim csv_name As String
    Dim table_name As String
    Dim query_name As String
    Dim qdf As QueryDef
    Dim query_exists As Boolean
    Dim sql As String
    
    Set temp_app = New Access.Application
    Set current_db = CurrentDb()
    csv_name = Dir(temp_dir & "\json_config_*.csv")
    
    With temp_app
        .OpenCurrentDatabase temp_db_path, True
        Set temp_db = .CurrentDb()
        Do While Len(csv_name) > 0
            csv_path = temp_dir & "\" & csv_name
            table_name = Replace(csv_name, ".csv", "")
            .DoCmd.TransferText TransferType:=acImportDelim, _
                                TableName:=table_name, _
                                FileName:=csv_path, _
                                HasFieldNames:=True
            temp_db.TableDefs.Refresh
    
            ' Check if a query for this table exists. It should, but just in case this is a
            '   newly added table or the query was accidentally deleted, just create one
            query_exists = False
            query_name = "qry_" & table_name
            sql = "SELECT * FROM " & table_name & " IN '" & temp_db_path & "';"
            For Each qdf In current_db.QueryDefs
                If qdf.name = "qry_" & table_name Then
                    qdf.sql = sql
                    query_exists = True
                End If
            Next qdf
            Set qdf = Nothing
            If Not query_exists Then
                Set qdf = current_db.CreateQueryDef("qry_" & table_name, sql)
                SetHiddenAttribute acQuery, query_name, True
            End If
            
            ' Get the next csv name
            csv_name = Dir
        Loop
        
        ' Close stuff and clean up
        temp_db.Close
        .CloseCurrentDatabase
        .DoCmd.Quit acQuitSaveNone
    End With
    
    Set qdf = Nothing
    current_db.QueryDefs.Refresh
    
    Exit Function
    
exit_err:
    On Error Resume Next
    current_db.Close
    Set current_db = Nothing
    Exit Function

err_handler:
    If Err.Number = 75 Or Err.Number = 70 Then
            MsgBox "A file for folder could not be deleted because it's currently in use. " & _
                    "Close all other applications and try again.", _
                    vbCritical, _
                    "File access error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err


End Function

Private Sub btn_load_json_Click()
    
    On Error GoTo err_handler
    
    Dim json_path As String: json_path = Nz(Me.txt_json_path, "")
    Dim temp_dir As String
    If Len(json_path) = 0 Then
        MsgBox "You must enter the path for a JSON file or select one by clicking the 'Browse JSON' button", _
                vbCritical, _
                "No JSON file given"
        Exit Sub
    End If
    
    ' Reset the source object of subform so it's not linked to the temp DB
    temp_dir = left(json_path, InStrRev(json_path, "\")) & "_temp"
    reset_temp_db temp_dir
    
    ' Run command to parse JSON
    Dim command As String
    Dim logfile As String
    logfile = temp_dir & "\log_parse_json_config.txt"
    cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\db_mgmt\parse_json_config.py " & _
          Me.txt_json_path & _
          " > " & logfile & " 2>&1"

    generic.run_io_command cmd, logfile, temp_dir, False, vbCrLf & vbCrLf & "Loading data from JSON..."
    
    ' Close the script status form immediately if there wasn't an error
    If CurrentProject.AllForms("frm_query_plot_wait").IsLoaded Then
        If Forms.frm_query_plot_wait.label_status.Caption Like "*error*" Then
            Exit Sub
        Else
            DoCmd.Close acForm, "frm_query_plot_wait"
        End If
    End If
    
    ' Create the temporary dir for storing text files and make the temporary DB
    Dim temp_db_path As String: temp_db_path = temp_dir & "\temp.accdb"
    generic.create_temp_db temp_db_path
    
    ' Read in CSVs
    load_json_config_from_csvs temp_db_path
    
    ' Set subform sources to new queries and set up the 'sorted' checkboxes
    set_subform_source Me.sub_dropdown_options, "Query.qry_json_config_dropdown_options"
    configure_checkboxes
    Me.btn_export_json.Enabled = True
    
    Exit Sub

exit_err:
    On Error Resume Next
    Exit Sub

err_handler:
    If Err.Number = 75 Or Err.Number = 70 Then
            MsgBox "A file for folder could not be deleted because it's currently in use. " & _
                    "Close all other applications and try again.", _
                    vbCritical, _
                    "File access error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err
    
End Sub

Private Sub configure_checkboxes()

    Dim subform_ctl As Control
    Dim column_count As Integer: column_count = 0
    For Each subform_ctl In Me.sub_dropdown_options.Controls
        If subform_ctl.ControlType = 116 Then ' 116 is not listed in the AcControlType Enum but it's the value of datasheet cols
            column_count = column_count + 1
        End If
    Next subform_ctl
    
    ' Make the label for the check boxes visible
    Me.lbl_sort.Visible = True
    
    Dim rs As DAO.recordset
    Dim json_has_sort As Boolean: json_has_sort = True
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM qry_json_config_field_properties WHERE attribute = 'sorted';", _
                                     dbOpenSnapshot)
    If rs.RecordCount < 1 Then json_has_sort = False
    
    
    Dim main_ctl As Control
    Dim i As Integer
    Dim left_position As Integer: left_position = Me.sub_dropdown_options.left
    Dim column_name As String
    Dim chk_ctl As Control
    For i = 1 To column_count
        ' Loop through all the controls in the subform and find the next one in order
        For Each subform_ctl In Me.sub_dropdown_options.Controls
            If subform_ctl.ControlType = 116 Then
                With Me.sub_dropdown_options.Controls(subform_ctl.name)
                    column_name = .Properties("Name")
                    If .Properties("ColumnOrder") = i Then
                        ' Loop through and find the checkbox with the corresponding name
                        For Each main_ctl In Me.Controls
                            ' Set the horizontal position of the checkbox
                            If main_ctl.ControlType = acCheckBox And _
                              main_ctl.name = "chk_" & LCase(Replace(column_name, " ", "_")) Then
                                Set chk_ctl = Me.Controls(main_ctl.name)
                                chk_ctl.Visible = True
                                chk_ctl.left = left_position + .Properties("ColumnWidth") / 2
                                
                                'Set value of checkbox
                                If json_has_sort Then
                                    rs.MoveFirst
                                    chk_ctl.Value = rs.Fields(column_name)
                                End If
                                Exit For
                            End If
                        Next main_ctl
                        left_position = left_position + .Properties("ColumnWidth")
                    End If
                End With
            End If
        Next subform_ctl
    Next i
    
    If Not json_has_sort Then
            MsgBox "This JSON file does not contain a 'sort' property in each field. You will have to manually" & _
                   " select which fields to sort in the check boxes under each field.", _
                   vbExclamation, _
                   "No 'sort' property found"
    End If
    
    Set rs = Nothing
    
End Sub

Private Sub btn_load_db_values_Click()
    
    'On Error GoTo err_handler
    
    ' Check if there's a JSON file given and the
    Dim json_path As String: json_path = Nz(Me.txt_json_path, "")
    Dim temp_dir As String
    If Me.sub_dropdown_options.SourceObject Like "*qry_json_config_*" Then
        If Len(json_path) = 0 Then
            MsgBox "Even though you already loaded the JSON data, you must enter the path for this" & _
                   " JSON file or select it by clicking the 'Browse JSON' button", _
                   vbCritical, _
                   "No JSON file given"
            Exit Sub
        Else
            temp_dir = get_temp_dir_path()
        End If
    Else
        Dim response As Integer
        response = MsgBox("Are you sure you want to load values from the database only? All other" & _
                          " configuration options that you want to change (other than sorting fields)" & _
                          " will have to be set manually in the JSON file once you export it.", _
                          vbQuestion + vbYesNoCancel, _
                          "No JSON file given")
        If response <> vbYes Then
            Me.txt_json_path.SetFocus
            Exit Sub
        End If
        temp_dir = CurrentProject.path & "\_temp"
        Me.lbl_temp_dir.Caption = temp_dir
    End If
    
    
    ' Reset the source object of subform so it's not linked to the temp DB
    reset_temp_db temp_dir
    
    ' Run command to parse JSON
    Dim cmd As String
    Dim logfile As String
    'Dim csv_dir As String
    csv_dir = left(temp_dir, InStrRev(temp_dir, "\") - 1)
    logfile = temp_dir & "\log_load_config_data_from_db.txt"
    ' json_path is an optional argument
    cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\db_mgmt\load_config_data_from_db.py " & _
          CONNECTION_TXT & _
          " " & csv_dir & _
          " " & json_path & _
          " > " & logfile & " 2>&1"

    generic.run_io_command cmd, logfile, temp_dir, False, vbCrLf & vbCrLf & "Loading config options from database..."
    
    ' Close the script status form immediately if there wasn't an error
    If CurrentProject.AllForms("frm_query_plot_wait").IsLoaded Then
        If Forms.frm_query_plot_wait.label_status.Caption Like "*error*" Then
            Exit Sub
        Else
            DoCmd.Close acForm, "frm_query_plot_wait"
        End If
    End If
    
    ' Create the temporary dir for storing text files and make the temporary DB
    Dim temp_db_path As String: temp_db_path = temp_dir & "\temp.accdb"
    generic.create_temp_db temp_db_path
    
    ' Read in CSVs
    load_json_config_from_csvs temp_db_path

    ' Set subform sources to new queries and set up the 'sorted' checkboxes
    set_subform_source Me.sub_dropdown_options, "Query.qry_json_config_dropdown_options"
    configure_checkboxes
    Me.btn_export_json.Enabled = True
    
    Exit Sub

exit_err:
    On Error Resume Next
    Exit Sub

err_handler:
    If Err.Number = 75 Or Err.Number = 70 Then
            MsgBox "A file for folder could not be deleted because it's currently in use. " & _
                    "Close all other applications and try again.", _
                    vbCritical, _
                    "File access error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err
    
End Sub

Private Sub btn_open_folderpicker_Click()
    
    generic.open_file_dialog Me.txt_output_path
    
End Sub

Private Function validate_json_config()

    ' Loop through each column
    Dim column_names() As String
    Dim ctl As Control
    Dim i As Integer: i = 0
    For Each ctl In Me.sub_dropdown_options.Controls
        If ctl.ControlType = 116 Then
            ReDim Preserve column_names(i)
            column_names(i) = ctl.name
            i = i + 1
        End If
    Next ctl
    
    ' Clear the missing values table
    Dim temp_db_path As String: temp_db_path = get_temp_dir_path() & "\temp.accdb"
    Dim missing_val_table As String: missing_val_table = "json_config_missing_values"
    CurrentDb.Execute "DELETE * FROM " & missing_val_table & " IN '" & temp_db_path & "' WHERE lookup_table IS NOT NULL"
    
    ' Get recordsets for the validation table names and field names
    Dim table_rs As DAO.recordset 'gets validation table name
    Dim field_rs As DAO.recordset 'gets validation field name
    Dim cntxt_rs As DAO.recordset 'gets context, which will be the data_table
    Set table_rs = CurrentDb.OpenRecordset("SELECT * FROM qry_json_config_field_properties WHERE attribute = 'validation_table';", _
                                            dbOpenSnapshot)
    Set field_rs = CurrentDb.OpenRecordset("SELECT * FROM qry_json_config_field_properties WHERE attribute = 'validation_field';", _
                                            dbOpenSnapshot)
    Set cntxt_rs = CurrentDb.OpenRecordset("SELECT * FROM qry_json_config_field_properties WHERE attribute = 'context';", _
                                            dbOpenSnapshot)
    If table_rs.RecordCount < 1 Or field_rs.RecordCount < 1 Then
        MsgBox "Problem parsing JSON: no validation_table or validation_field"
        Exit Function
    End If
    table_rs.MoveFirst
    field_rs.MoveFirst
    
    ' Populate missing_values table
    Dim validation_table As String
    Dim validation_field As String
    Dim context As String
    Dim sql As String
    Dim missing_values As Boolean: missing_values = False
    Dim col_name As Variant
    Dim values_rs As DAO.recordset
    For Each col_name In column_names
        validation_table = Nz(table_rs.Fields(col_name), "")
        validation_field = Nz(field_rs.Fields(col_name), "")
        context = Nz(cntxt_rs.Fields(col_name), "")

        sql = "INSERT INTO " & missing_val_table & " IN '" & temp_db_path & "'" & _
              " SELECT [" & _
              col_name & "] AS data_value, '" & _
              context & "' AS data_table, " & _
              "'some_string' AS data_field, '" & _
              validation_table & "' AS lookup_table, '" & _
              validation_field & "' AS lookup_field " & _
              "FROM (SELECT [" & col_name & "] FROM qry_json_config_dropdown_options WHERE [" & col_name & "] NOT IN " & _
                "(SELECT " & validation_field & " FROM " & validation_table & ") )"
        
        
        If context <> "global" Then
            Debug.Print sql
            CurrentDb.Execute sql
        End If
    Next col_name
    
    Set table_rs = Nothing
    Set field_rs = Nothing
    Set cntxt_rs = Nothing
    
    ' Open add_codes form
    If DCount("*", "qry_" & missing_val_table) > 0 Then
        Dim response As Integer
        response = MsgBox("There are values you entered that don't match any values in the corresponding look-up" & _
                          " tables in the database. You cannot save this configuration file without either" & _
                          " changing the unmatched values or adding new entries to the corresponding tables" & _
                          " (requires admin access). Would you like to see which values are unmatched?", _
                          vbYesNoCancel + vbCritical + vbQuestion, _
                          "Missing lookup values")
        If response = vbYes Then
            DoCmd.OpenForm "frm_add_codes"
            Forms.frm_add_codes.SetFocus
            Form_frm_add_codes.load_missing_codes temp_db_path, missing_val_table
        End If
    End If

End Function



Private Sub btn_export_json_Click()
    
    'On Error GoTo err_handler
    
    ' Get output dir and check if there's a config file already there because it will get written over
    Dim out_dir As String: out_dir = Nz(Me.txt_output_path, "")
    Dim response As Integer
    If Len(out_dir) = 0 Then
        MsgBox "You must enter an output folder or select one by clicking the 'Browse' button", _
                vbCritical, _
                "No output folder given"
        Exit Sub
    ElseIf Len(Dir(out_dir & "\savageCheckerConfig.json")) <> 0 Then
        response = MsgBox("The output folder you selected already contains a file named 'savageCheckConfig.json'" & _
                          " (the filename the configuration file will be saved to). Would you like to write over" & _
                          " the existing file?", _
                          vbYesNoCancel + vbExclamation, _
                          "Configuration file already exists")
        If response = vbNo Or response = vbCancel Then
            Exit Sub
        End If
    End If
    
    
    'Verify that values in the table are all present in their corresponding lookup fields in the DB
    validate_json_config
    
    Dim temp_dir As String
    Dim temp_db_path As String
    temp_dir = get_temp_dir_path()
    temp_db_path = temp_dir & "\temp.accdb"
    
    ' Update sorted row from check boxes
    Dim ctl As Control
    Dim subform_ctl As Control
    Dim column_name As String
    Dim sql As String
    Dim check_value As Boolean
    For Each ctl In Me.Controls
        If ctl.ControlType = acCheckBox Then
            'Loop through fields and find the one with a matching name
            For Each subform_ctl In Me.sub_dropdown_options.Controls
                column_name = subform_ctl.name
                If subform_ctl.ControlType = 116 And ctl.name = "chk_" & LCase(Replace(column_name, " ", "_")) Then
                    ' Execute update SQL
                    If ctl.Value = -1 Then check_value = True Else check_value = False
                    sql = "UPDATE json_config_field_properties IN '" & temp_db_path & "'" & _
                          " SET [" & column_name & "] = '" & check_value & "' WHERE attribute = 'sorted';"
                    CurrentDb.Execute (sql)
                    Exit For
                End If
            Next subform_ctl
        End If
        
    Next ctl
    
    'Export queries to csvs
    Dim qdf As QueryDef
    Dim csv_path As String
    For Each qdf In CurrentDb.QueryDefs
        If qdf.name Like "qry_json_config*" Then
            csv_path = temp_dir & "\" & Replace(qdf.name, "qry_", "") & "_edited.csv"
            DoCmd.TransferText acExportDelim, , qdf.name, csv_path, HasFieldNames:=True
        End If
    Next qdf
    
    'Run python to dump back to JSON
    Dim command As String
    Dim logfile As String
    logfile = out_dir & "\log_write_json_config.txt"
    cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\db_mgmt\write_json_config.py " & _
          temp_dir & " " & _
          out_dir & _
          " > " & logfile & " 2>&1"
    
    generic.run_io_command cmd, logfile, out_dir, False, vbCrLf & vbCrLf & "Saving config options to JSON..."
    
    Exit Sub
    
exit_err:
    On Error Resume Next
    current_db.Close
    Set current_db = Nothing
    Exit Sub

err_handler:
    If Err.Number = 75 Or Err.Number = 70 Then
            MsgBox "A file for folder could not be deleted because it's currently in use. " & _
                    "Close all other applications and try again.", _
                    vbCritical, _
                    "File access error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err
    

End Sub
Private Function get_temp_dir_path() As String
    
    Dim json_path As String
    json_path = Nz(Me.txt_json_path, "")
    
    If Len(json_path) > 0 Then
        get_temp_dir_path = left(json_path, InStrRev(json_path, "\")) & "_temp"
    Else
        get_temp_dir_path = Me.lbl_temp_dir.Caption
    End If
    
End Function

Private Sub delete_temp_files()
' Clean up temporary files if they still exist
    
    'On Error GoTo err_handler
    
    ' Break links to temp DB
    set_subform_source Me.sub_dropdown_options, Me.name & "_sub"
    
    ' If the temp dir exists, delete it and re-make it
    Dim temp_dir As String
    temp_dir = get_temp_dir_path()
    If Not Len(Trim(temp_dir)) = 0 Then
        If Dir(temp_dir, vbDirectory + vbHidden) <> "" Then
            If Dir(temp_dir & "\*.*") <> "" Then
                Kill temp_dir & "\*.*"
            End If
            SetAttr temp_dir, vbNormal
            RmDir temp_dir
        End If
    End If
    
    Exit Sub
    
exit_err:
    On Error Resume Next
    Exit Sub

err_handler:
    If Err.Number >= 70 And Err.Number <= 76 Then
            MsgBox "Temporary files created while parsing JSON could not be deleted because one or more is currently in use. " & _
                    "You can manually delete these files at " & temp_dir & " (you will have to make hidden files " & _
                    "visible to see this folder).", _
                    vbInformation, _
                    "File delete error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err

End Sub

Private Sub btn_close_Click()
    
    delete_temp_files
    
    DoCmd.Close acForm, Me.name, acSaveNo
    
End Sub


