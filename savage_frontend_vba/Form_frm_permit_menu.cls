VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_permit_menu"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database


Private Sub clear_selection()
    
    On Error GoTo err_handler
    
    ' Reset all checkboxes
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = 0")
    Me.sub_permits.Requery

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Function get_selected_permits() As Recordset

    Dim rs As Recordset
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM qry_permit_menu_sub_source WHERE select_permit", dbOpenSnapshot)
        
    ' Return the recordset
    Set get_selected_permits = rs
        
End Function

Private Sub btn_clear_Click()
    clear_selection
End Sub


Private Sub btn_select_all_Click()

    On Error GoTo err_handler
    
    Dim rs As DAO.Recordset
    Set rs = Me.sub_permits.Form.Recordset
    rs.MoveLast
    If rs.RecordCount = 0 Then GoTo err_no_selection
    
    rs.MoveFirst
    While Not (rs.EOF Or rs.BOF)
        rs.Edit
        rs!select_permit = -1
        rs.Update ' dbUpdateBatch, Force:=True
        rs.MoveNext
    Wend
    
    Set rs = Nothing
    
    Exit Sub

exit_sub:
    Exit Sub

err_no_selection:
    MsgBox "You must select at least one permit in the 'select_permit' field", _
            vbCritical, _
            "No permit selected"
    Set rs = Nothing
    Exit Sub

err_handler:
    If Err.Number = 3021 Or Err.Description Like "*No current record*" Then
        Resume err_no_selection
    ElseIf Err.Number = 3197 Then
        MsgBox "All records are alread selected", vbExclamation, ""
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If

End Sub

Private Sub btn_edit_Click()
' Load the selected permit for editing
    
    On Error GoTo err_handler
    
    ' Get
    Dim rs As Recordset
    Set rs = get_selected_permits()
    ' Check that only one permit was selected. If not, warn the user and exit
    rs.MoveLast ' Need to do this to retreive the actual record count
    If rs.RecordCount = 0 Then
        GoTo err_no_selection
    ElseIf rs.RecordCount > 1 Then
        MsgBox "You selected mutliple permits, but you can select only one permit to edit at a time", _
                vbCritical, _
                "Multiple permits selected"
        Set rs = Nothing
        Exit Sub
    End If

    ' Pre-fill values of editing form with values for this record
    Dim edit_form As Form
    Dim ctl As Control
    Dim current_id As Long
    Dim permit_number As String
    DoCmd.OpenForm "frm_permit_create_edit"
    Set edit_form = Forms("frm_permit_create_edit").Form
    With rs
        .MoveFirst
        current_id = .fields("id")
        permit_number = .fields("permit_number")
        permit_prefix = .fields("permit_number_prefix") & ""
        If Not .BOF And Not .EOF Then
            ' Loop through each control. If it's a textbox or dropdown, the .tag should be the corresponding field in the DB,
            '   so set the value for that field
            For Each ctl In edit_form.Controls
                If ctl.ControlType = acTextBox Or ctl.ControlType = acComboBox And ctl.Tag <> "" Then
                    edit_form.Controls(ctl.Name) = .fields(ctl.Tag)
                ElseIf ctl.ControlType = acCheckBox And (ctl.Tag = "is_lodge_bus" Or ctl.Tag = "is_nps_operations_support") Then
                    If Nz(.fields(ctl.Tag), False) Then edit_form.Controls(ctl.Name) = -1 Else edit_form.Controls(ctl.Name) = 0
                End If
            Next ctl
        End If
        .Close
    End With
    
    ' Set up other controls on edit form
    'If edit_form.Controls("dpd_permit_type") = "Right of Way" Then
    '    edit_form.Controls("dpd_inholder") = edit_form.Controls("txt_permit_holder")
    'End If
    edit_form.Controls("lbl_is_new_permit").Caption = "editing: " & current_id
    edit_form.Controls("lbl_permit_number").Caption = "Permit #: " & permit_prefix & permit_number
    edit_form.Controls("txt_entered_by").Locked = True
    edit_form.Controls("txt_phone").Locked = True
    edit_form.Controls("txt_phone").BackColor = edit_form.Controls("txt_last_edited_by").BackColor
    edit_form.Controls("txt_schedule").Locked = True
    edit_form.Controls("txt_schedule").BackColor = edit_form.Controls("txt_last_edited_by").BackColor
    edit_form.Controls("txt_email").Locked = True
    edit_form.Controls("txt_email").BackColor = edit_form.Controls("txt_last_edited_by").BackColor
    edit_form.Controls("btn_delete").Enabled = True
    edit_form.Controls("btn_print").Enabled = True
    edit_form.Controls("btn_duplicate").Enabled = True
    
    Forms("frm_permit_create_edit").show_hide_dropdowns
    Forms("frm_permit_create_edit").show_hide_lodge_checkbox
    
    DoCmd.RepaintObject acForm, edit_form.Name
    
    ' Deselect check box
    clear_selection
    
    Exit Sub

exit_sub:
    Exit Sub

err_no_selection:
    MsgBox "You must select at least one permit in the 'select_permit' field", _
            vbCritical, _
            "No permit selected"
    Set rs = Nothing
    Exit Sub

err_handler:
    If Err.Number = 3021 Or Err.Description Like "*No current record*" Then
        Resume err_no_selection
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If

End Sub

Private Sub btn_delete_Click()
' Delete the selected permit(s)
    
    On Error GoTo err_handler
    
    Dim rs As Recordset
    Set rs = get_selected_permits()
    rs.MoveLast ' Need to do this to retreive the actual record count
    If rs.RecordCount = 0 Then
        MsgBox "You must select at least one permit in the 'select_permit' field", _
                vbCritical, _
                "No permit selected"
        Set rs = Nothing
        Exit Sub
    End If
    
    Dim response As Integer
    response = MsgBox("You're about to delete " & rs.RecordCount & " permit record(s). If you click 'Yes'," & _
                      " all selected permit records will be permanently deleted. Are you sure you want to continue?", _
                      vbYesNoCancel + vbExclamation, _
                      "Delete " & rs.RecordCount & "permit(s)?")
    
    ' Loop through each selected record and
    Dim delete_values As String: delete_values = "("
    If response = vbYes Then
        With rs
            .MoveFirst
            While Not .EOF
                delete_values = delete_values & .fields("id") & ", "
                .MoveNext
            Wend
        End With
    Else
        Exit Sub
    End If
    Set rs = Nothing
    
    ' Check that we actually have some ID values to delete
    If Not Right(delete_values, 2) = ", " Then
        MsgBox "Problem encountered while deleting records. Try deleting manually in the 'road_permits' table", _
                vbCritical, _
                "No permit selected"
        Exit Sub
    End If
    
    delete_values = Left(delete_values, Len(delete_values) - 2) & ")"
    CurrentDb.Execute ("DELETE * FROM road_permits WHERE id IN " & delete_values & ";")
    Me.sub_permits.Requery
    
    Exit Sub

exit_sub:
    Exit Sub

err_no_selection:
    MsgBox "You must select at least one permit in the 'select_permit' field", _
            vbCritical, _
            "No permit selected"
    Set rs = Nothing
    Exit Sub

err_handler:
    If Err.Number = 3021 Or Err.Description Like "*No current record*" Then
        Resume err_no_selection
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If

End Sub

Private Sub btn_new_permit_Click()
    
    On Error GoTo err_handler
    
    DoCmd.OpenForm "frm_permit_create_edit"
    
    Dim permit_form As Form
    Set permit_form = Forms("frm_permit_create_edit").Form
    
    Dim ctl As Control
    For Each ctl In permit_form.Controls
        If ctl.ControlType = acTextBox Or ctl.ControlType = acComboBox Then
            ctl.Value = ""
        ElseIf ctl.ControlType = acCheckBox And (ctl.Tag = "is_lodge_bus" Or ctl.Tag = "is_nps_operations_support") Then
            ctl.Value = 0
        End If
    Next ctl
    permit_form.Controls("txt_entered_by") = Environ$("Username")
    permit_form.Controls("lbl_is_new_permit").Caption = "new permit"
    permit_form.Controls("lbl_permit_number").Caption = "Permit #: <Null>"

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub

Private Sub btn_print_Click()
' Loop through all of the selected permits and make files for them 1 by 1
    
    On Error GoTo err_handler
    
    Dim out_dir As String: out_dir = savagedb.open_file_dialog()
    If out_dir = "" Then Exit Sub ' The user canceled so just exit
    
    Dim rs As Recordset
    Set rs = get_selected_permits()
    rs.MoveLast ' Need to do this to retreive the actual record count
    Dim n_selected As Integer: n_selected = rs.RecordCount
    If n_selected = 0 Then GoTo err_no_selection
    
    Dim ids() As Long
    Dim permit_types() As String
    Dim permit_numbers() As Long
    Dim permit_prefixes() As String
    Dim is_lodge_bus() As Boolean
    rs.MoveFirst
    Dim i As Integer
    While Not (rs.EOF Or rs.BOF)
        ReDim Preserve ids(i): ids(i) = rs.fields("id")
        ReDim Preserve permit_types(i): permit_types(i) = rs.fields("permit_type") & ""
        ReDim Preserve permit_numbers(i): permit_numbers(i) = rs.fields("permit_number")
        ReDim Preserve permit_prefixes(i): permit_prefixes(i) = rs.fields("permit_number_prefix") & ""
        ReDim Preserve is_lodge_bus(i): If rs.fields("is_lodge_bus") Then is_lodge_bus(i) = True Else is_lodge_bus(i) = False
        i = i + 1
        rs.MoveNext
    Wend
    Set rs = Nothing
    
    ' Clear selection, then select each record individually and make the permit
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = 0;")
    Dim out_path As String
    Dim permit_type As String
    Dim failed_permits() As String
    Dim n_failed As Integer
    For i = 0 To n_selected - 1
        out_path = out_dir & "\special_use_road_permit_" & LCase(Replace(Replace(permit_types(i), " ", "_"), "/", "_")) & "_" & _
                                                           permit_prefixes(i) & permit_numbers(i) & ".pdf"
        CurrentDb.Execute ("UPDATE road_permits SET select_permit = -1 WHERE id=" & ids(i))
        out_path = savagedb.save_permit_to_file(ids(i), permit_types(i), out_path, False, is_lodge_bus(i))
        If out_path = "" Then
            ReDim Preserve failed_permits(n_failed): failed_permits(n_failed) = permit_prefixes(i) & permit_numbers(i)
            n_failed = n_failed + 1
        End If
continue_loop:
    Next i
        
    ' Clear selection again and reload the data
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = 0;")
    Me.sub_permits.Requery

show_success_msg:
    Dim response As Integer
    If n_failed = 0 Then
        response = MsgBox("All " & n_selected & " permits sucessfully saved to " & out_dir & _
                            ". Would you like to open the output folder?", _
                            vbInformation + vbYesNo, _
                            "Export sucessful")
    Else
        Dim failed_str As String: failed_str = vbCrLf
        For i = 0 To n_failed - 1
            failed_str = failed_str & failed_permits(i) & vbCrLf
        Next i
        If n_failed = n_selected Then
            MsgBox "All permit exports failed", vbExclamation, "Export failure"
        Else
            response = MsgBox(n_selected - n_failed & " permits successfully exported to " & out_dir & vbCrLf & vbCrLf & _
                              ". The following " & n_failed & " permits failed: " & failed_str & vbCrLf & _
                              "Would you like to open the output folder to view the exported permits?", _
                              vbExclamation, _
                              "Partial export failure")
        End If
    End If
    
    ' Open the out dir in file explorer
    If response = vbYes Then Shell "C:\WINDOWS\explorer.exe """ & out_dir & "", vbNormalFocus
    
    Exit Sub
    
exit_sub:
    Exit Sub

err_no_selection:
    MsgBox "You must select at least one permit in the 'select_permit' field", _
            vbCritical, _
            "No permit selected"
    Set rs = Nothing
    Exit Sub

err_handler:
    If Err.Number = 3021 Or Err.Description Like "*No current record*" Then
        Resume err_no_selection
    ElseIf Err.Description Like "*OutputTo action was canceled*" Then
        ' This file is open and can't be written over
        response = MsgBox("The PDF file for permit number " & permit_prefixes(i) & permit_numbers(i) & _
               " could not be written over because access to the file was denied. Would you like to try this" & _
               " permit again? If so, close the PDF document, then click 'Yes'. To skip this permit and continue with the" & _
               " remaining selected permits, click 'No'. If you have seen this message multiple times" & _
               " for this permit, click 'Cancel', then click the 'Export selected permit(s)' button again and choose a" & _
               " different location to save the file to.", _
               vbExclamation + vbYesNoCancel, _
               "Error: file could not saved")
        If response = vbYes Then
            i = i - 1 ' Set the counter back one, then try this one again
            Resume continue_loop
        ElseIf response = vbNo Then ' Skip this permit
            out_path = "" ' Set this to an empty str so the next line in the for loop will mark this permit as failed
            If CurrentProject.AllReports("rpt_road_permit").IsLoaded Then DoCmd.Close acReport, "rpt_road_permit"
            Resume Next
        Else
            For i = i To n_selected - 1
                ReDim Preserve failed_permits(n_failed): failed_permits(n_failed) = permit_prefixes(i) & permit_numbers(i)
                n_failed = n_failed + 1
            Next i
            Resume show_success_msg
        End If
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If
    
End Sub

Private Function validate_file_for_import(sheet As Worksheet, field_indices As Dictionary) As Boolean
    
    validate_file_for_import = True
    
    Dim fields_with_nulls As New Dictionary
    Dim null_rows As String
    Dim field_name As Variant
    Dim r As Integer
    ' Loop through each field and check if there are any null cells
    For Each field_name In field_indices.Keys()
        If field_name = "permit_type" Or field_name = "date_in" Or field_name = "date_out" Or field_name = "permit_number_prefix" Or field_name = "permit_holder" Or field_name = "is_lodge_bus" Then
            null_rows = "- " & field_name & ": "
            For r = 2 To sheet.UsedRange.Rows.Count
                ' If there are any null rows, add them to the string
                If IsEmpty(sheet.Cells(r, field_indices(field_name))) Then
                    null_rows = null_rows & r & ", "
                End If
            Next r
            ' Clip the last two characters, which should be ", " if there were any null strings. If replacing the
            '   field_name returns "- ", that means there weren't any null cells in the column
            null_rows = Left(null_rows, Len(null_rows) - 2)
            If Replace(null_rows, field_name, "") <> "- " Then
                fields_with_nulls(field_name) = null_rows
            End If
        End If
    Next field_name
    
    ' If the dictionary has anything in it, show a message
    If UBound(fields_with_nulls.Keys()) >= 0 Then ' Ubound returns -1 if array is empty
        Dim msg As String: msg = "The following row(s) were found with nothing entered for required fields: " & vbCrLf
        Dim row_ind As Variant
        For Each field_name In fields_with_nulls.Keys()
            msg = msg & vbCrLf & fields_with_nulls(field_name)
        Next field_name
        
        If CurrentProject.AllForms("frm_query_plot_wait").IsLoaded Then DoCmd.Close acForm, "frm_query_plot_wait"
        MsgBox msg, vbCritical, "Required field missing"
        
        validate_file_for_import = False
    End If

End Function


Private Sub btn_import_Click()
    
    On Error GoTo err_handler
    
    ' Open file dialog
    Dim file_path As String: file_path = savagedb.open_file_dialog("Select a CSV to import", msoFileDialogFilePicker, "*.xls; *.xlsx", "Excel files")
    If Nz(file_path, "") = "" Then Exit Sub
    
    DoCmd.OpenForm "frm_query_plot_wait"
    Forms.frm_query_plot_wait.label_status.Caption = vbCrLf & vbCrLf & "Importing permits..."
    
    ' Don't use recordset for reading in data because data types might not match
    '   It's best just to create the sql myself
    Dim excel_app As Excel.Application: Set excel_app = CreateObject("Excel.Application")
    Dim workbook As Excel.workbook: Set workbook = GetObject(file_path)
    Dim sheet As Excel.Worksheet: Set sheet = workbook.Worksheets(1)
    
    ' Get column names
    Dim n_columns As Integer: n_columns = sheet.UsedRange.Columns.Count
    Dim field_names As String
    Dim this_name As String
    Dim field_indices As New Dictionary
    Dim year_index As Integer: prefix_index = -9999
    Dim skip_index As Integer: skip_index = -9999
    For c = 1 To n_columns
        this_name = sheet.Cells(1, c).Value
        ' If permit number is in the columns, skip it because the database needs to create its own
        If this_name <> "permit_number" Then
            field_names = field_names & this_name & ", "
            field_indices(this_name) = c
        Else
            skip_index = c
        End If
    Next c
    field_names = field_names & "permit_number, entered_by, time_entered, last_edited_by, time_last_edited"
    
    ' Add constants including is_lodge_bus if it wasn't in the file already
    Dim other_values As String
    other_values = "'" & Environ$("Username") & "', '" & Now() & "', '" & Environ$("Username") & "', '" & Now() & "'"
    If Not field_names Like "*is_lodge_bus*" Then
        field_names = field_names & ", is_lodge_bus"
        other_values = other_values & ", 0"
    End If
    
    ' Check if all required fields are filled for all rows
    If Not validate_file_for_import(sheet, field_indices) Then Exit Sub
    
    ' Loop through all rows after header and execute insert
    Dim values As String
    Dim this_value As Variant
    Dim these_field_names As String
    Dim permit_number As String
    Dim inholder_code As String
    Dim r As Integer
    For r = 2 To sheet.UsedRange.Rows.Count
        these_field_names = field_names
        this_value = sheet.Cells(r, c)
        values = " VALUES("
        For c = 1 To n_columns
            If c = skip_index Then
                GoTo continue_col_for
            ElseIf sheet.Cells(1, c).Value = "vehicle_year" Then
                ' If year is null, the SQL will throw and error, so remove the vehicle_year field from the SQL
                If IsEmpty(this_value) Then
                    these_field_names = Replace(these_field_names, ", vehicle_year", "")
                Else
                    values = values & this_value & ", "
                End If
            Else
                values = values & "'" & sheet.Cells(r, c) & "', "
            End If
            
continue_col_for:
        Next c
        
        permit_number = make_road_permit_number()
        values = values & permit_number & ", " & other_values
        CurrentDb.Execute ("INSERT INTO road_permits (" & these_field_names & ")" & values & ")")
        inholder_code = ""
    Next r
    
    ' Reload the subform to show changes
    Me.sub_permits.Requery
    
    DoCmd.Close acForm, "frm_query_plot_wait"
    MsgBox "Import of " & sheet.UsedRange.Rows.Count - 1 & " permits successful from " & file_path, vbInformation, "Import successful"
    
    Exit Sub
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Sub btn_logout_Click()
    
    Dim current_user_state As String
    current_user_state = savagedb.get_user_state()
    
    Dim response As Integer
    If current_user_state <> "read" Then ' The user is signed in either as admin or permit user
        ' Run the restart script only if the user selected "Yes". Othwerwise, exit
        response = restart_db("savage_read", "0l@usmur!e")
        If response <> vbYes Then
            Exit Sub
        End If
    Else
        DoCmd.OpenForm "frm_login" ' Defaults to expect admin credentials
    End If

End Sub
