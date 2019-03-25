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

Private Function get_selected_permits() As recordset

    Dim rs As recordset
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM qry_permit_menu_sub_source WHERE select_permit <> 0", dbOpenSnapshot)
        
    ' Return the recordset
    Set get_selected_permits = rs
        
End Function

Private Sub btn_clear_Click()
    clear_selection
End Sub


Private Sub btn_select_all_Click()

    On Error GoTo err_handler
    
    Dim rs As DAO.recordset
    Set rs = Me.sub_permits.Form.recordset
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
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If

End Sub

Private Sub btn_edit_Click()
' Load the selected permit for editing
    
    On Error GoTo err_handler
    
    ' Get
    Dim rs As recordset
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
                    edit_form.Controls(ctl.name) = .fields(ctl.Tag)
                ElseIf ctl.ControlType = acCheckBox And ctl.Tag = "is_lodge_bus" Then
                    If .fields(ctl.Tag) Then edit_form.Controls(ctl.name) = -1 Else edit_form.Controls(ctl.name) = 0
                End If
            Next ctl
        End If
        .Close
    End With
    
    ' Set up other controls on edit form
    If edit_form.Controls("dpd_permit_type") = "Right of Way" Then
        edit_form.Controls("dpd_inholder") = edit_form.Controls("txt_permit_holder")
    End If
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
    
    Forms("frm_permit_create_edit").show_hide_dropdowns
    Forms("frm_permit_create_edit").show_hide_lodge_checkbox
    
    DoCmd.RepaintObject acForm, edit_form.name
    
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
    
    Dim rs As recordset
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
    
    delete_values = left(delete_values, Len(delete_values) - 2) & ")"
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
        ElseIf ctl.ControlType = acCheckBox And ctl.Tag = "is_lodge_bus" Then
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
    
    Dim rs As recordset
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
        out_path = out_dir & "\special_use_road_permit_" & LCase(Replace(permit_types(i), " ", "_")) & "_" & _
                                                           permit_prefixes(i) & permit_numbers(i) & ".pdf"
        CurrentDb.Execute ("UPDATE road_permits SET select_permit = -1 WHERE id=" & ids(i))
        out_path = savagedb.save_permit_to_file(ids(i), permit_types(i), out_path, False, is_lodge_bus(i))
        If out_path = "" Then
            ReDim Preserve failed_permits(n_failed): failed_permits(n_failed) = permit_prefixes(i) & permit_numbers(i)
            n_failed = n_failed + 1
        End If
    Next i
        
    ' Clear selection again and reload the data
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = 0;")
    Me.sub_permits.Requery
    
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
            MsgBox "All permit exports failed for an unknown reason", vbCritical, "Error"
        Else
            response = MsgBox(n_selected - n_failed & " permits successfully exported to " & out_dir & _
                              ", but the following " & n_failed & " permits failed: " & failed_str & _
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
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If
    
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
