VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_edit_inholder_allotments_sub"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database
Public new_button_original_top As Double

Private Sub btn_add_new_inholder_Click()
    
    On Error GoTo err_handler
    
    ' Set the global var storing the "add new inholder" button's position
    new_button_original_top = Me.btn_add_new_inholder.Top
    new_button_height = Me.btn_add_new_inholder.Height
    ' Disable the button until the user presses add or cancel
    Me.btn_add_new_inholder.Enabled = False
    
    ' Enable and make visible text box and buttons to add or cancel the new inholder
    Me.txt_new_permit_holder.Visible = True
    Me.btn_insert_inholder.Visible = True
    Me.btn_cancel_insert_inholder.Visible = True
    
    ' Move the text box
    With Me.txt_new_permit_holder
        Me.btn_add_new_inholder.Move Me.btn_add_new_inholder.Left, _
                                     new_button_original_top + (.Top + .Height - new_button_original_top) + (.Height / 3)
        
        .SetFocus
    End With
    
    DoCmd.RepaintObject acForm, "frm_edit_inholder_allotments"
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Function hide_inholder_insert_controls()
    
    ' Make buttons and text box invisible again
    Me.txt_allotment.SetFocus ' remove focus from text field so it can be set to invisible
    Me.txt_new_permit_holder.Visible = False
    Me.btn_insert_inholder.Visible = False
    Me.btn_cancel_insert_inholder.Visible = False
    Me.txt_new_permit_holder = ""
    
    ' Move the button back to it's original position
    Me.btn_add_new_inholder.Top = new_button_original_top
    Me.btn_add_new_inholder.Enabled = True

End Function

Private Sub btn_cancel_insert_inholder_Click()
    
    hide_inholder_insert_controls
    
End Sub

Private Sub btn_insert_inholder_Click()
    
    On Error GoTo err_handler
    
    Dim db As DAO.Database
    Dim tdf As TableDef
    Set db = CurrentDb
    Set tdf = db.TableDefs("inholder_allotments")
    pass_through_query "INSERT INTO inholder_allotments (inholder_name) VALUES ('" & Me.txt_new_permit_holder & "');", _
                        False, _
                        Right(tdf.Connect, Len(tdf.Connect) - 5)
    Set tdf = Nothing
    Set db = Nothing
    
    ' Update the recordsources for the form
    Dim parent_form As Form
    Set parent_form = Forms.frm_edit_inholder_allotments
    
    parent_form.Form.dropdown_year = year_str 'update dropdown
    CurrentDb.TableDefs("inholder_allotments").RefreshLink 'refresh the inholder's table
    parent_form.Form.Refresh
    
    Me.txt_allotment.SetFocus
    DoCmd.GoToRecord , , acLast
    
    hide_inholder_insert_controls

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

