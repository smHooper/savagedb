VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_permit_create_edit"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database



Private Function make_permit_number() As String
' Create a permit number. Because the number is prepended with a 2-digit year,
' this requires a lot of regex replacement so the permit numbers start over each year
    
    ' Get the inholder code (second column [0-indexed] and row of the selected item) if this is an inholder.
    '   Otherwise, it should be null
    Dim inholder_code As String
    inholder_code = Me.dpd_inholder.Column(1, Me.dpd_inholder.ListIndex) & ""
    
    ' Run a query to get all permit numbers with leading inholder codes (if there is one) removed
    Dim rs As ADODB.recordset
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
        make_permit_number = ""
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
        .Pattern = "\d{2}0{0:4}"
        id_number = .Replace(Str(max_id), "")
    End With
    
    ' Add the current 2-digit year
    id_number = year_str & Right("0000" & Int(id_number), 5)
    
    If Not (Len(inholder_code) = 0 Or inholder_code = "NUL") Then id_number = inholder_code & id_number
    
    make_permit_number = id_number
    
    Exit Function
    
exit_sub:
    Exit Function
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Function

Public Function show_hide_lodge_checkbox()
    
    If DCount("[name]", "bus_codes", "[name] = '" & Me.dpd_inholder & "'") <> 0 Then
        Me.chk_lodge_bus.Visible = True
        Me.lbl_lodge_bus.Visible = True
    Else
        Me.chk_lodge_bus = 0
        Me.chk_lodge_bus.Visible = False
        Me.lbl_lodge_bus.Visible = False
    End If

End Function


Public Function show_hide_dropdowns()
' Display the corresponding dropdown menus for inholders or NPS approved if applicable

    Dim permit_type As String
    permit_type = Me.dpd_permit_type
    
    If permit_type = "Right of Way" Then
        Me.dpd_inholder.Visible = True
        Me.lbl_inholder.Visible = True
        Me.dpd_approved_type = ""
        Me.dpd_approved_type.Locked = True
        Me.dpd_approved_type.BackColor = Me.txt_entered_by.BackColor
        'Me.txt_permit_holder = ""
        Me.txt_permit_holder.Visible = False
        Me.lbl_permit_holder.Visible = False
        'show_hide_lodge_checkbox
    ElseIf permit_type = "NPS Approved" Then
        Me.dpd_approved_type.Locked = False
        Me.dpd_approved_type.BackColor = Me.dpd_inholder.BackColor
        Me.txt_permit_holder.Visible = True
        Me.lbl_permit_holder.Visible = True
        Me.dpd_inholder = "" '"NUL"
        Me.chk_lodge_bus = 0
        Me.dpd_inholder.Visible = False
        Me.lbl_inholder.Visible = False
        Me.chk_lodge_bus.Visible = False
        Me.lbl_lodge_bus.Visible = False
    Else
        Me.txt_permit_holder.Visible = True
        Me.lbl_permit_holder.Visible = True
        Me.dpd_approved_type = ""
        Me.dpd_approved_type.Locked = True
        Me.dpd_approved_type.BackColor = Me.txt_entered_by.BackColor
        Me.dpd_inholder = "" '"NUL"
        Me.chk_lodge_bus = 0
        Me.dpd_inholder.Visible = False
        Me.lbl_inholder.Visible = False
        Me.chk_lodge_bus.Visible = False
        Me.lbl_lodge_bus.Visible = False
    End If


End Function

Private Function update_permit_numnber()
' Helper function to handle updating the permit number label.
    
    ' Only update the id number if this is a new permit. In that case, the record doesn't
    ' exist yet, so each time make_permit_number() is called, it will return
    ' the same ID number. If we called make_permit_number() when editing an
    ' existing record, it would increment the ID number 1 because make_permit_number()
    ' would find the next highest permit number.
    If Me.lbl_is_new_permit.Caption = "new permit" Then
        Me.lbl_permit_number.Caption = "Permit #: " & make_permit_number()
    
    ' If editing, just update the inholder code if necessary
    Else
        Dim permit_number As String
        Dim inholder_code As String
        inholder_code = Me.dpd_inholder.Column(1, Me.dpd_inholder.ListIndex) & ""
        Dim re As RegExp
        Set re = New RegExp
        With re
            .Global = True
            .Pattern = "[A-Z]{3}"
            permit_number = .Replace(Replace(Me.lbl_permit_number.Caption, "Permit #: ", ""), "")
        End With
        
        If Not (Len(inholder_code) = 0 Or inholder_code = "NUL") Then permit_number = inholder_code & permit_number
        Me.lbl_permit_number.Caption = "Permit #: " & permit_number
    End If

End Function


Private Sub dpd_permit_type_AfterUpdate()

    On Error GoTo err_handler
    
    show_hide_dropdowns
    update_permit_numnber
    
    Exit Sub
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Sub btn_show_parking_Click()
' Show or hide parking locations listbox
    
    On Error GoTo err_handler
    
    ' If the list box isn't visible, get values and show it.
    If Not Me.lbx_parking.Visible Then
        Me.lbx_parking.Visible = True
        Me.rct_parking_footer.Visible = True
        Me.btn_add_parking.Visible = True
        DoCmd.RepaintObject acForm, Me.name
        Exit Sub
    
    ' Otherwise it's already visible, so hide it
    Else
        Me.lbx_parking.Visible = False
        Me.rct_parking_footer.Visible = False
        Me.btn_add_parking.Visible = False
        DoCmd.RepaintObject acForm, Me.name
    End If
    
    Exit Sub

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_add_parking_Click()
' Set the category filter textbox text to a comma-separated list of all
' selected items in the categories list box
    
    On Error GoTo err_handler
    
    Dim selection_str As String: selection_str = ""
    Dim item_index As Variant
    
    ' If no selection was made, warn the user and exit
    If Me.lbx_parking.ListCount = 0 Then
        MsgBox "No parking locations selected to add. Either select items " & _
                "first or just type them manually in the text box", vbExclamation
        Exit Sub
    End If

    
    ' Add each selected item to make a comma-separated string
    If Len(Me.txt_parking & "") = 0 Then
        ' Loop through all selected items
        For Each item_index In Me.lbx_parking.ItemsSelected
            selection_str = selection_str & Me.lbx_parking.ItemData(item_index) & ", "
        Next item_index
    ' If the parking textbox isn't empty, ask the user if they want to append the selection or replace the text
    Else
        Dim msg_button As Integer
        msg_button = MsgBox("You have already entered text in the parking locations text box. " & _
                            "Do you want to replace it with your selection? " & _
                            "To add your selection to the text you already entered, click 'No'. " & _
                            "To keep the text as it is now, click 'Cancel'.", _
                            vbYesNoCancel + vbExclamation, _
                            "Add or replace parking locations?")
        If msg_button = vbYes Then
            ' Just set the text to the new selection
            For Each item_index In Me.lbx_parking.ItemsSelected
                    selection_str = selection_str & Me.lbx_parking.ItemData(item_index) & ", "
            Next item_index
        ElseIf msg_button = vbNo Then
            selection_str = Me.txt_parking & ", "
            ' Loop through each selected item and check if it's in the text already
            For Each item_index In Me.lbx_parking.ItemsSelected
                If Not selection_str Like "*" & Me.lbx_parking.ItemData(item_index) & "*" Then
                    selection_str = selection_str & Me.lbx_parking.ItemData(item_index) & ", "
                End If
            Next item_index
        Else ' The user clicked cancel
            Exit Sub
        End If
    End If
    
    If Right(selection_str, 2) = ", " Then ' Drop the last ", "
        selection_str = left(selection_str, Len(selection_str) - 2)
    End If
    Me.txt_parking = selection_str
    
    Me.lbx_parking.Visible = False
    Me.rct_parking_footer.Visible = False
    Me.txt_parking.SetFocus
    Me.btn_add_parking.Visible = False
    
    Me.SetFocus
    DoCmd.RepaintObject acForm, Me.name
    
    Exit Sub

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Sub dpd_approved_type_AfterUpdate()
    
    On Error GoTo err_handler
    
    update_permit_numnber
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub


Private Sub dpd_inholder_AfterUpdate()
    
    On Error GoTo err_handler
    
    show_hide_lodge_checkbox
    update_permit_numnber
    Me.txt_permit_holder = Me.dpd_inholder
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
End Sub

Private Sub save_edits()
' Helper function to save edits to DB
    
    Dim sql As String: sql = "UPDATE road_permits SET "
    current_id = Int(Replace(Me.lbl_is_new_permit.Caption, "editing: ", ""))
    Dim is_lodge As Boolean
    For Each ctl In Me.Controls
        If ctl.ControlType = acTextBox Or ctl.ControlType = acComboBox And ctl.Tag <> "" Then
            sql = sql & ctl.Tag & "='" & ctl.Value & "', "
        ElseIf ctl.ControlType = acCheckBox And ctl.Tag = "is_lodge_bus" Then
            If ctl.Value = 0 Then is_lodge = False Else is_lodge = True
            sql = sql & "is_lodge_bus=" & is_lodge & ", "
        End If
    Next ctl
    
    Dim inholder_code As String
    inholder_code = Me.dpd_inholder.Column(1, Me.dpd_inholder.ListIndex) & ""
    sql = sql & " permit_number=" & Replace(Me.lbl_permit_number.Caption, "Permit #: " & inholder_code, "") & _
                ", permit_number_prefix='" & inholder_code & "'" & _
                " WHERE id=" & current_id & ";"
    CurrentDb.Execute (sql)


End Sub


Private Function check_text_fields() As Boolean
    
    check_text_fields = False
    
    ' Check that fields are filled in: permit_type, date_in, date_out, inholder or approved type (if applicable), phone, schedule, email
    If IsNull(Me.dpd_permit_type) Or Me.dpd_permit_type = Me.dpd_permit_type.DefaultValue Then
        MsgBox "You must select a permit type to save the permit", vbExclamation, "No permit type selected"
        Me.dpd_permit_type.SetFocus
        Exit Function
    ElseIf Len(Me.txt_date_in & "") = 0 Then
        MsgBox "You must enter a ""Date in"" to save the permit", vbExclamation, "No Date in given"
        Me.txt_date_in.SetFocus
        Exit Function
    ElseIf Len(Me.txt_date_out & "") = 0 Then
        MsgBox "You must enter a ""Date out"" to save the permit", vbExclamation, "No Date out given"
        Me.txt_date_out.SetFocus
        Exit Function
    ElseIf Me.dpd_permit_type = "Right of Way" And (Len(Me.dpd_inholder & "") = 0 Or Me.dpd_inholder = "NUL") Then
        MsgBox "You selected ""Right of Way"" for the permit type, but you have not selected an inholder." & _
                " Either select an inholder or change the permit type before trying to save the permit.", _
                vbExclamation, _
                "No Inholder selected"
        Me.dpd_inholder.SetFocus
        Exit Function
    ElseIf Me.dpd_permit_type = "NPS Approved" And (Len(Me.dpd_approved_type) = 0 Or Me.dpd_approved_type = "Null") Then
        MsgBox "You selected ""NPS Approved"" for the permit type, but you have not selected an approved type." & _
                " Either select an approved type or change the permit type before trying to save the permit.", _
                vbExclamation, _
                "No approved type selected"
        Me.dpd_approved_type.SetFocus
        Exit Function
    ElseIf Len(Me.txt_phone) = 0 Then
        MsgBox "You must enter a phone number to save the permit", vbExclamation, "No phone number given"
        Me.txt_phone.SetFocus
        Exit Function
    ElseIf Len(Me.txt_schedule) = 0 Then
        MsgBox "You must enter your schedule to save the permit", vbExclamation, "No phone number given"
        Me.txt_schedule.SetFocus
        Exit Function
    ElseIf Len(Me.txt_schedule) = 0 Then
        MsgBox "You must enter your email to save the permit", vbExclamation, "No phone number given"
        Me.txt_email.SetFocus
        Exit Function
    End If
    
    check_text_fields = True

End Function


Private Sub btn_save_Click()
' Insert new record or save changes to existing record
    
    On Error GoTo err_handler
    
    ' Already showed the message box, so just exit
    If Not check_text_fields Then Exit Sub
    
    'If Me.dpd_permit_type Like "*Photographer*" The
    Me.txt_last_edited_by = Environ$("Username")
    Me.txt_time_last_edited = Now()
    Dim current_id As Long
    Dim ctl As Control
    ' If this is a new permit, loop through controls and construct the sql
    If Me.lbl_is_new_permit.Caption = "new permit" Then
        Dim fields As String: fields = "("
        Dim values As String: values = "VALUES ("
        Dim is_lodge As Boolean: is_lodge = False
        For Each ctl In Me.Controls
            If ctl.ControlType = acTextBox Or ctl.ControlType = acComboBox And ctl.Tag <> "" Then
                If ctl.Value & "" <> "" Then
                    fields = fields & ctl.Tag & ", "
                    If ctl.Tag = "vehicle_year" Then
                        values = values & ctl.Value & ", "
                    Else
                        values = values & "'" & ctl.Value & "', "
                    End If
                End If
            ElseIf ctl.ControlType = acCheckBox And ctl.Tag = "is_lodge_bus" Then
                If ctl.Value <> 0 Then is_lodge = True
                fields = fields & ctl.Tag & ", "
                values = values & is_lodge & ", "
            End If
        Next ctl
        
        Dim inholder_code As String
        inholder_code = Me.dpd_inholder.Column(1, Me.dpd_inholder.ListIndex) & ""
        fields = fields & " permit_number, permit_number_prefix)"
        values = values & Replace(Me.lbl_permit_number.Caption, "Permit #: " & inholder_code, "") & ", " & _
                          "'" & inholder_code & "')"
        CurrentDb.Execute ("INSERT INTO road_permits " & fields & " " & values & ";")
        
        Dim rs As recordset
        Set rs = CurrentDb.OpenRecordset("SELECT id FROM road_permits ORDER BY id", dbOpenSnapshot)
        rs.MoveLast
        
        If rs.RecordCount > 0 Then
            current_id = rs.fields("id")
            Me.lbl_is_new_permit.Caption = "editing: " & current_id
        Else
            MsgBox "The save operation encountered an unknown error. Check to make sure the record" & _
                   " was added to the table (if the table is currently open, you'll have to close and" & _
                   " re-open it to see the new permit record).", _
                   vbInformation, _
                   "Error encountered during save"
            Exit Sub
        End If
        
        ' The user is now editing an existing record, so set up the form to reflect that
        Me.btn_delete.Enabled = True
        Me.btn_print.Enabled = True
        
    ' Otherwise, do the same, but for an UPDATE and add WHERE statement to select this record
    ElseIf Me.lbl_is_new_permit.Caption Like "editing: *" Then
        save_edits
    
    End If
    
    MsgBox "Changes saved to the ""road_permits"" table", vbInformation, "Permit info successfully saved"
    
    Exit Sub
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_delete_Click()
    
    On Error GoTo err_handler
    
    Dim response As Integer
    response = MsgBox("You're about to delete this permit record. If you click 'Yes', this permit will be" & _
                      " permanently deleted. Are you sure you want to continue?", _
                      vbYesNoCancel + vbExclamation, _
                      "Delete permit?")
    If response = vbYes Then
        Dim current_id As String: current_id = Replace(Me.lbl_is_new_permit.Caption, "editing: ", "")
        CurrentDb.Execute ("DELETE * FROM road_permits WHERE id=" & current_id & ";")
        MsgBox "Permit successfully deleted from ""road_permits"" table", vbInformation, "Delete successful"
        DoCmd.Close acForm, Me.name
    Else
        Exit Sub
    End If
    
    Exit Sub
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub

Private Function check_edits() As Integer
' Check if there are any unsaved edits. Ask the user if they want to save them before continuing.
    Dim id_number As Integer: id_number = Int(Replace(Me.lbl_is_new_permit.Caption, "editing: ", ""))
    Dim rs As recordset
    Dim ctl As Control
    Dim ctl_value As String
    Dim response As Integer
    Dim show_save_msgbox As Boolean: show_save_msgbox = False
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM road_permits WHERE id=" & id_number)
    rs.MoveFirst
    If rs.RecordCount = 1 Then
        For Each ctl In Me.Controls
            If ctl.ControlType = acTextBox Or ctl.ControlType = acComboBox And ctl.Tag <> "" Then
                If ctl.Value <> rs.fields(ctl.Tag) Then
                    show_save_msgbox = True
                    Exit For
                End If
            ElseIf ctl.ControlType = acCheckBox And ctl.Tag = "is_lodge_bus" Then
                If (rs.fields(ctl.Tag) And ctl.Value = 0) Or (Not rs.fields(ctl.Tag) And ctl.Value <> 0) Then
                    show_save_msgbox = True
                    Exit For
                End If
            End If
        Next ctl
        If show_save_msgbox Then
            response = MsgBox("You have unsaved changes to the permit information. Would you like to save" & _
                           " them before creating the permit file?", _
                           vbExclamation + vbYesNoCancel, _
                           "Changes not saved")
            check_edits = response
            If response = vbYes Then
                save_edits
            ElseIf response = vbCancel Then
                If ctl.Visible Then ctl.SetFocus ' Show them which field doesn't match the DB
                Exit Function
            End If
        End If
    End If


End Function

Private Sub btn_print_Click()
' Fill the report with the current record's info and a QR code
    
    On Error GoTo err_handler
    
    ' Already showed the message box, so just exit
    If Not check_text_fields Then Exit Sub
    
    ' Check if the text fields match the database fields
    Dim id_number As Integer: id_number = Int(Replace(Me.lbl_is_new_permit.Caption, "editing: ", ""))
    Dim save_edits_response As Integer
    save_edits_response = check_edits
    If save_edits_response = vbCancel Then Exit Sub ' The user decided to cancel the print action
    
    ' Make sure this record is the only selected record
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = 0;")
    CurrentDb.Execute ("UPDATE road_permits SET select_permit = -1 WHERE id=" & id_number) ' -1 is 'True' for some reason
    
    ' Make the qr_code
    'Dim file_path As String
    Dim out_dir As String
    Dim out_path As String
    Dim permit_type As String
    Dim rs As recordset
    Set rs = CurrentDb.OpenRecordset("SELECT * FROM road_permits WHERE id = " & row_id)
    rs.MoveLast
    If rs.RecordCount = 1 Then
        out_dir = savagedb.open_file_dialog()
        out_path = out_dir & "\special_use_road_permit_" & rs.fields("permit_number_prefix") & rs.fields("permit_number") & ".pdf"
        permit_type = rs.fields("permit_type")
    Else
        ' Couldn't make the output name with permit info so just have the user enter their own file name
        out_path = savagedb.open_file_dialog(title:="Select an output file", dialog_type:=msoFileDialogFilePicker, _
                                             filter_str:="*.pdf", filter_name:="PDF file")
    End If
    If out_path = "" Then Exit Sub ' The user never saved the file
    
    Dim is_lodge_bus As Boolean: If Me.chk_lodge_bus = 0 Then is_lodge_bus = False Else is_lodge_bus = True
    savagedb.save_permit_to_file id_number, permit_type, out_path, is_lodge_bus:=is_lodge_bus
    
    ' Update text fields
    Me.txt_file = out_path
    Me.txt_last_printed_by = Environ$("username")
    
exit_sub:
    Exit Sub

err_handler:
    If Err.Number = 2501 Then ' The file is open and DoCmd.OutputTo failed
        MsgBox "The PDF file could not be written over because it is currently open. Please close the document," & _
               " then try to print again, or choose another location to save the file to.", _
               vbExclamation, _
               "Error: file could not saved"
        Resume Next
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
        Resume exit_sub
    End If
    
End Sub

Private Sub refresh_permit_menu()
' Refresh the data in the permit menu subform
    On Error GoTo exit_sub
    
    Dim menu_form As Form
    Set menu_form = Forms("frm_permit_menu")
    'Dim menu_form_open As Boolean: menu_form_open = savagedb.object_is_open("frm_permit_menu", acForm)
    menu_form.Controls("sub_permits").Requery

exit_sub:
    Exit Sub

End Sub

Private Sub btn_close_Click()
    
    On Error GoTo err_handler
    
    ' Just close the form because the user didn't make any changes
    If lbl_permit_number.Caption Like "*<Null>*" Then
        DoCmd.Close acForm, Me.name
        Exit Sub
    End If
    
    Dim save_edits_response As Integer
    save_edits_response = check_edits
    If save_edits_response = vbCancel Then Exit Sub
    
    DoCmd.Close acForm, Me.name
    refresh_permit_menu

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Sub Form_Close()
    refresh_permit_menu
End Sub
