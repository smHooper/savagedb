VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_import_data"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database
Private Const ARCHIVE_DIR As String = "C:\users\shooper\desktop\temp\import_test\archive"
Private Const DB_BROWSER_PATH As String = "C:\Program Files\DB Browser for SQLite\DB Browser for SQLite.exe"



Private Sub btn_open_filepicker_Click()
    
    Me.txt_sqlitedb_path = savagedb.open_file_dialog("Select a .db file to import", msoFileDialogFilePicker, _
                             "*.db", "SQLite database files")

End Sub

Private Function set_tab_datasource(Optional tab_name As String)
    
    Dim current_tab As String
    Dim current_query As String
    Dim current_table As String
    
    current_tab = Me.tcl_data.Pages(Me.tcl_data.Value).Name
    ' If tab_name is given
    If (Len(tab_name) > 0) And (current_tab <> tab_name) Then
        current_tab = tab_name
        Dim i As Integer
        For i = 0 To Me.tcl_data.Pages.Count - 1
            With Me.tcl_data.Pages(i)
                If .Name = current_tab Then
                    .SetFocus
                    Exit For
                End If
            End With
        Next i
    Else
        
    End If
    current_table = Right(current_tab, Len(current_tab) - 4)
    current_query = "qry_import_" & current_table
    
    Dim sub_form As Form
    'subform = Me.Form.Controls("sub_" & current_table).Form
    Me.Form.Controls("sub_" & current_table).SourceObject = "Query." & current_query ' References the query object, not SQL
    Me.Form.Controls("sub_" & current_table).Form.recordsource = current_query 'uses the SQL from the query
    Me.Form.Controls("sub_" & current_table).Form.Requery
    

End Function

Private Function break_links()

    Dim i As Integer: i = 0
    Me.tcl_data.Pages(0).SetFocus
    For i = 0 To Me.tcl_data.Pages.Count - 1
        With Me.tcl_data.Pages(i)
            .Visible = True ' This could have been set to false if the function was run before and this table had no data
            Form.Controls("sub_" & Right(.Name, Len(.Name) - 4)).SourceObject = Me.Name & "_sub"
        End With
    Next i


End Function


Private Sub btn_open_sqlitedb_Click()
    
    'On Error Resume Next
    On Error GoTo err_handler
    
    Dim sqlite_path As String
    Dim temp_dir As String
    
    sqlite_path = Nz(Me.txt_sqlitedb_path, "")
    If Len(sqlite_path) = 0 Then
        MsgBox "You must select or enter the path of a database file to import", _
               vbCritical, _
               "No DB file selected"
        Exit Sub
    End If
    
    ' Set the recordsource of all tabs' subforms to drop the connection to the temp DB if there is one
    break_links
    
    ' If the temp dir exists, delete it and re-make it
    temp_dir = Left(sqlite_path, InStrRev(sqlite_path, "\")) & "_temp"
    If Dir(temp_dir, vbDirectory + vbHidden) <> "" Then
        If Dir(temp_dir & "\*.*") <> "" Then
            Kill temp_dir & "\*.*"
        End If
        'RmDir temp_dir
        If Err.Number = 75 Or Err.Number = 70 Then GoTo ErrFileAccess ' File access error
    Else
        MkDir temp_dir
    End If
    
    Dim validate_cmd As String
    Dim logfile As String
    logfile = temp_dir & "\log_validate.txt"
    validate_cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\db_mgmt\validate_app_data.py " & _
                   sqlite_path & _
                   " " & CONNECTION_TXT & _
                   " > " & logfile & " 2>&1"

    savagedb.run_io_command validate_cmd, logfile, temp_dir, False, vbCrLf & vbCrLf & "Validating data from file..."
    
    
    Dim filestream As Integer: filestream = FreeFile
    Dim lines() As String
    Dim i As Integer
    Dim already_imported As Boolean: already_imported = False
    Open logfile For Input As #filestream
        lines = Split(Input$(LOF(filestream), #filestream), vbNewLine)
    Close #filestream
    
    For i = 0 To UBound(lines)
        If lines(i) Like "*These data have already been uploaded*" Then
            already_imported = True
            Exit For
        End If
    Next i
    
    ' Close the script status form immediately if there wasn't an error
    If CurrentProject.AllForms("frm_query_plot_wait").IsLoaded Then
        If Forms.frm_query_plot_wait.label_status.Caption Like "*error*" Then
            If already_imported Then
                DoCmd.Close acForm, "frm_query_plot_wait"
                MsgBox "The data from this file have already been imported. Check that you selected " & _
                        "the right file and that no one else has already imported this file.", _
                        vbCritical, _
                        "Import error"
                Exit Sub
            Else
                Exit Sub
            End If
        Else
            DoCmd.Close acForm, "frm_query_plot_wait"
        End If
    End If
    
    ' Create the temporary dir for storing text files and make the temporary DB
    Dim temp_db_path As String: temp_db_path = temp_dir & "\temp.accdb"
    savagedb.create_temp_db temp_db_path
    
    ' For each file in temp_dir, make a table in the temp DB and set the connection of the associated query
    Dim csv_name As String
    Dim csv_path As String
    Dim table_name As String
    Dim current_db As DAO.Database
    Dim temp_db As DAO.Database
    Dim temp_app As Access.Application
    Dim query_exists As Boolean
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim prp As DAO.Property
    Dim qdf As DAO.QueryDef
    Dim query_name As String
    i = 0 ' Reset to keep track of tables with data for the tables array
    Dim tables() As String
    Dim tab_IDs() As Integer
    Dim response As Integer
    Dim missing_lookups As Boolean: missing_lookups = False
    
    Set temp_app = New Access.Application
    Set current_db = CurrentDb()
    csv_name = Dir(temp_dir & "\*_flagged.csv")
    With temp_app
        .OpenCurrentDatabase temp_db_path, False
        Set temp_db = .CurrentDb()
        Do While Len(csv_name) > 0
            csv_path = temp_dir & "\" & csv_name
            table_name = Replace(csv_name, "_flagged.csv", "")
            .DoCmd.TransferText TransferType:=acImportDelim, _
                                TableName:=table_name, _
                                FileName:=csv_path, _
                                HasFieldNames:=True
            temp_db.TableDefs.Refresh
            
            ' If there are any lookup values in the app data that don't exist in the database,
            '   ask the user if they want to see which values are missing from the DB
            If table_name Like "missing_lookup_values" Then
                csv_name = Dir
                missing_lookups = True
                response = MsgBox("There are values you entered in the app data in fields with look-up values that" & _
                                  " don't match any values in the corresponding look-up tables in the database. You cannot" & _
                                  " import these data without either changing the unmatched values or adding new" & _
                                  " entries to the corresponding tables (requires admin access). Would you like to" & _
                                  " see which values are unmatched?", _
                                  vbYesNoCancel + vbCritical + vbQuestion, _
                                  "Import error")
                If response = vbYes Then
                    DoCmd.OpenForm "frm_add_codes"
                    Forms.frm_add_codes.SetFocus
                    Form_frm_add_codes.load_missing_codes temp_db_path, "missing_lookup_values"
                End If
                
                response = MsgBox("Would you like to open the app data to edit the unmatched values?", _
                                  vbQuestion + vbYesNoCancel, _
                                  "Edit app data?")
                If response = vbYes Then
                    Dim wShell As Object
                    Set wShell = VBA.CreateObject("WScript.Shell")
                    Dim cmd As String: cmd = """" & DB_BROWSER_PATH & """ " & sqlite_path
                    wShell.Run cmd, 1, False ' Run command silently and but don't wait for process to finish
                End If
                
                ' Reset form
                break_links
                
                GoTo exit_err
                'Exit Sub
                'GoTo ContinueDoWhile
            End If
            
            ' Add the import column so the user can check whether or not to keep each record.
            '   Set all records to checked by default
            temp_db.Execute "ALTER TABLE " & table_name & " ADD COLUMN import YESNO;", dbFailOnError
            temp_db.Execute "UPDATE " & table_name & " SET import = -1;", dbFailOnError
            Set tdf = temp_db.TableDefs(table_name)
            Set fld = tdf.fields("import")
            Set prp = fld.CreateProperty("DisplayControl", dbInteger, acCheckBox)
            fld.Properties.Append prp
            
            ' Check if a query for this table exists. It should, but just in case this is a
            '   newly added table or the query was accidentally deleted, just create one
            query_exists = False
            query_name = "qry_import_" & table_name
            For Each qdf In current_db.QueryDefs
                If qdf.Name = query_name Then
                    qdf.sql = "SELECT import, duplicated_in_app, found_in_db, datetime, *, '" & _
                               Environ$("Username") & "' AS entered_by, 'imported' AS entry_method " & _
                              "FROM " & table_name & " IN '" & temp_db_path & "';"
                    query_exists = True
                End If
            Next qdf
            Set qdf = Nothing
            If Not query_exists Then
                Set qdf = current_db.CreateQueryDef(query_name, _
                            "SELECT import, duplicated_in_app, found_in_db, datetime, *, '" & _
                            Environ$("Username") & "' AS entered_by, 'imported' AS entry_method " & _
                            "FROM " & table_name & " IN '" & temp_db_path & "';")
                SetHiddenAttribute acQuery, query_name, True
            End If
            
            ' Set the datasource for this tab if the table has any data. Otherwise,
            '   make the corresponding tab invisible
            If .DCount("id", table_name) > 0 Then
                ReDim Preserve tables(i)
                tables(i) = table_name
                i = i + 1
            Else
                For j = 0 To Me.tcl_data.Pages.Count - 1
                    With Me.tcl_data.Pages(j)
                        If .Name = "tab_" & table_name Then
                            Me.SetFocus
                            .Visible = False
                            Exit For
                        End If
                    End With
                Next j
            End If
            
            ' Get the next csv name
            csv_name = Dir
ContinueDoWhile:
        Loop
        temp_db.Close
        .CloseCurrentDatabase
        .DoCmd.Quit acQuitSaveNone
    End With
    
    Set qdf = Nothing
    current_db.QueryDefs.Refresh
    
    ' If there are any lookup values in the app data that don't exist in the database,
    '   ask the user if they want to see which values are missing from the DB
    'If missing_lookups Then 'Dir(temp_dir & "\missing_lookup_values.csv") <> "" Then 'If the file exists, there are missing values

    'End If
    
    
    Dim tname As Variant
    Dim field_ctl As Control
    For Each tname In tables
        set_tab_datasource "tab_" & tname
    Next tname
    
    ' Set the current tab to the first one that's visible
    For i = 0 To Me.tcl_data.Pages.Count - 1
        With Me.tcl_data.Pages(i)
            If .Visible Then
                .SetFocus
                Exit For
            End If
        End With
    Next i
    
    ' Disable the sqlite path text box so that when the import button is pressed,
    '   we can still retrieve the temp dir path
    Me.txt_sqlitedb_path.Locked = True
    Me.txt_sqlitedb_path.BackColor = Me.tcl_data.BackColor
    Me.txt_sqlitedb_path.BorderColor = Me.Detail.BackColor
    
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

ErrFileAccess:
    MsgBox "A file for folder could not be deleted because it's currently in use. " & _
           "Close all other applications and try again.", _
           vbCritical, _
           "File access error"
    Resume exit_err
    

End Sub



Private Function validate_lookup_values(data_table, data_field, temp_db_path, lookup_table, lookup_field) As Boolean
' Make sure that all values in the data_field of data_table exist
' in the lookup_field of lookup_table
    
    Dim data_rs As DAO.Recordset
    Dim lookup_rs As DAO.Recordset
    
    ' Get recordset for both data_table and lookup_table
    Set data_rs = CurrentDb.OpenRecordset("SELECT " & data_field & " FROM " & data_table & " IN '" & temp_db_path & "';")
    Set lookup_rs = CurrentDb.OpenRecordset("SELECT " & lookup_field & " FROM " & lookup_table & ";")
    
    ' For each value in data field
    '      For each value in lookup table
    '       check if data field value matches lookup value
    '       If so, exit for twice
    '       Else, add to array of missing values
    ' Return the array
    
    ' In main sub,
    ' check if the array has more than a length of 0
    ' If so, ask the user if they would like to add these values to lookup
    '   If yes, show form that has all records for the whole lookup table (probably have to make a different form for each lookup table
    '   If no, cancel import


End Function

Private Sub btn_import_Click()
    
    On Error GoTo err_handler
    
    Dim response As Integer
    response = MsgBox("Are you sure you want to import the data? If you click 'yes', " & _
                       "the data will be copied to the master database and making changes will require admin access.", _
                       vbYesNoCancel + vbQuestion, _
                       "Import data?")
    
    If response = vbYes Then
        Dim sqlite_path As String
        Dim i As Integer ' Counts tabs
        Dim j As Integer ' Counts fields
        Dim table_name As String
        Dim query_name As String
        Dim temp_dir As String
        Dim csv_path As String
        Dim record_set As DAO.Recordset
        Dim field_names As String
        Dim export_sql As String
        
        sqlite_path = Me.txt_sqlitedb_path
        temp_dir = Left(sqlite_path, InStrRev(sqlite_path, "\")) & "_temp"
        DoCmd.OpenForm "frm_query_plot_wait"
        Forms.frm_query_plot_wait.Form.label_status.Caption = vbCrLf & vbCrLf & "Saving changes to app data..."
        DoCmd.RepaintObject acForm, "frm_query_plot_wait"
        
        ' Export data to csvs
        For i = 0 To Me.tcl_data.Pages.Count - 1
            With Me.tcl_data.Pages(i)
                
                table_name = Right(.Name, Len(.Name) - 4)
                query_name = "qry_import_" & table_name
                csv_path = temp_dir & "\" & table_name & "_checked.csv"
                
                ' Check if the subform has data. Can't just use .Visible because some forms
                '   might not have tables that match at all (e.g. other_vehicles) so the .Visible = True but
                '   the .SourceObject of the form might not have been changed from the original frm_import_data_sub
                If Me.Form.Controls("sub_" & table_name).SourceObject = "Query." & query_name Then
                    Set record_set = CurrentDb.OpenRecordset(query_name)
                    With record_set
                        For j = 0 To .fields.Count - 1
                            If (.fields(j).Name <> "import") And (.fields(j).Name <> "duplicated_in_app") And (.fields(j).Name <> "found_in_db") Then
                                field_names = field_names & .fields(j).Name & ", "
                            End If
                        Next j
                        .Close
                    End With
                    export_sql = "SELECT " & Left(field_names, Len(field_names) - 2) & " FROM " & query_name & " WHERE import <> 0;"
                    CurrentDb.CreateQueryDef "temp_export", export_sql
                    DoCmd.TransferText acExportDelim, , "temp_export", csv_path, HasFieldNames:=True
                    DoCmd.DeleteObject acQuery, "temp_export"
                    field_names = ""
                End If
            End With
        Next i
        
        Set record_set = Nothing
        DoCmd.Close acForm, "frm_query_plot_wait"
        
        ' Reset subform data sources (so temp db isn't connected) so the Python script can delete the temp dir
        break_links
        
        ' run script to import data into postgres
        Dim import_cmd As String
        Dim logfile As String
        logfile = temp_dir & "\log_import.txt"
        import_cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\db_mgmt\import_app_data.py " & _
                        temp_dir & " " & _
                        sqlite_path & _
                        " " & CONNECTION_TXT & _
                        " " & ARCHIVE_DIR & _
                        " > " & logfile & " 2>&1"

        savagedb.run_io_command import_cmd, logfile, temp_dir, False, vbCrLf & vbCrLf & "Importing data..."
        
        ' Close the script status form immediately
        If CurrentProject.AllForms("frm_query_plot_wait").IsLoaded Then
            If Not (Forms.frm_query_plot_wait.label_status.Caption Like "*error*") Then
                DoCmd.Close acForm, "frm_query_plot_wait"
            Else
                Exit Sub
            End If
        End If
        
        MsgBox "Your data were successfully imported. You might have to close and reopen the any currently open tables to see the changes.", _
                vbInformation, _
                "Import successful"

    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Function delete_temp_files() As String

    ' If the temp dir exists, delete it and re-make it
    Dim temp_dir As String
    Dim sqlite_path As String: sqlite_path = Nz(Me.txt_sqlitedb_path, "")
    Dim fso As Object
    temp_dir = Left(sqlite_path, InStrRev(sqlite_path, "\")) & "_temp"
    delete_temp_files = temp_dir
    If Dir(temp_dir, vbDirectory + vbHidden) <> "" Then
        If Dir(temp_dir & "\*.*") <> "" Then
            Kill temp_dir & "\*.*"
        End If
        SetAttr temp_dir, vbNormal
        RmDir temp_dir
    End If

End Function


Private Sub btn_cancel_Click()
' Clean up files if necessary
 
    On Error GoTo err_handler
    
    ' If the user has loaded any data, prompt them that changes will be lost
    Dim data_loaded As Boolean: data_loaded = False
    Dim i As Integer
    For i = 0 To Me.tcl_data.Pages.Count - 1
        With Me.tcl_data.Pages(i)
            If Form.Controls("sub_" & Right(.Name, Len(.Name) - 4)).Form.recordsource Like "qry_import*" Then
                data_loaded = True
                Exit For
            End If
        End With
    Next i
    
    Dim temp_dir As String
    Dim sqlite_path As String: sqlite_path = Nz(Me.txt_sqlitedb_path, "")
    temp_dir = Left(sqlite_path, InStrRev(sqlite_path, "\")) & "_temp"
    If data_loaded Then
        Dim response As Integer
        response = MsgBox("Are you sure you want to close this form? If you click 'yes', " & _
                          "your edits and selections will not be saved.", _
                          vbYesNoCancel + vbExclamation, _
                           "Cancel import?")
        If response = vbYes Then
            ' Clean up
            break_links
            temp_dir = delete_temp_files()
            
            DoCmd.Close acForm, Me.Name, acSaveNo
            Exit Sub
        End If
    Else
        delete_temp_files
        DoCmd.Close acForm, Me.Name, acSaveNo
    End If
    
    Exit Sub
    
err_handler:
    If Err.Number >= 70 And Err.Number <= 76 Then
            MsgBox "Temporary files created during import could not be deleted because one or more is currently in use. " & _
                    "You can manually delete these files at " & temp_dir & " (you will have to make hidden files " & _
                    "visible to see this folder).", _
                    vbInformation, _
                    "File delete error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume Next


End Sub
