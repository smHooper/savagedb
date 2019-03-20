VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_add_codes_sub_inholders"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database
Private Sub show_hide_insert_code_controls()
' Convenience function to hide or show controls

    If Not Me.btn_add_new_code.Visible Then
        'Hide the stuff to insert and show the button to show this stuff
        Me.btn_add_new_code.Visible = True
        Me.btn_add_new_code.SetFocus
        Me.txt_new_name.Visible = False
        Me.txt_new_code.Visible = False
        Me.btn_insert_code.Visible = False
        Me.btn_cancel_insert_code.Visible = False
        Me.lbl_new_code.Visible = False
        Me.lbl_new_name.Visible = False
    Else
        Me.txt_new_name.Visible = True
        Me.txt_new_code.Visible = True
        Me.btn_insert_code.Visible = True
        Me.btn_cancel_insert_code.Visible = True
        Me.lbl_new_code.Visible = True
        Me.lbl_new_name.Visible = True
        Me.btn_cancel_insert_code.SetFocus 'Divert focus from "add new" button to be able to hide it
        Me.btn_add_new_code.Visible = False
        
    End If

End Sub


Private Sub btn_add_new_code_Click()
    
    Dim response As Integer
    If savagedb.get_user_state() = "read" Then
        response = MsgBox("You must log in as an admin user to add any new codes." & _
                          " Would you like to log in as an admin user now?", _
                          vbInformation + vbYesNoCancel, _
                          "Invalid user permission")
        If response = vbYes Then
            DoCmd.OpenForm "frm_login"
        End If
        Exit Sub
    End If
    
    show_hide_insert_code_controls
    
End Sub

Private Sub btn_cancel_insert_code_Click()
    
    show_hide_insert_code_controls
    
End Sub


Private Sub btn_insert_code_Click()
    
    On Error GoTo err_handler
    
    ' Check that the text boxes are full
    If Trim(Me.txt_new_name & vbNullStr) = vbNullStr Then
        MsgBox "You must enter a new name for this entry", vbCritical, "No name entered"
        Me.txt_new_name.SetFocus
        Exit Sub
    End If
    If Trim(Me.txt_new_code & vbNullStr) = vbNullStr Then
        MsgBox "You must enter a new code for this entry", vbCritical, "No code entered"
        Me.txt_new_code.SetFocus
        Exit Sub
    ElseIf Len(Me.txt_new_code) <> 3 Then
        MsgBox "The code must be 3 letters exactly", vbCritical, "Invalid code entered"
        Me.txt_new_code.SetFocus
        Exit Sub
    End If
    
    
    Dim recordsource As String: recordsource = Me.recordsource
    Dim name_column As String: name_column = Me.txt_existing_name.ControlSource
    Dim code_column As String: code_column = Me.txt_existing_code.ControlSource
    Dim db As DAO.Database
    Dim tdf As TableDef
    Set db = CurrentDb
    Set tdf = db.TableDefs(recordsource)
    Dim sql As String:
    ' Insert values into the table. Codes are all
    sql = "INSERT INTO " & recordsource & " (" & name_column & ", " & code_column & ") VALUES ('" & _
          Me.txt_new_name & "', upper('" & Me.txt_new_code & "') );"
    pass_through_query sql, False, Right(tdf.Connect, Len(tdf.Connect) - 5)
    
    'Refresh the table and parent form
    tdf.RefreshLink
    Me.Parent.Form.Refresh
    Set tdf = Nothing
    Set db = Nothing
    Me.txt_new_name = ""
    Me.txt_new_code = ""
    
    Me.txt_existing_code.SetFocus
    DoCmd.GoToRecord , , acLast
    
    Exit Sub

exit_err:
    On Error Resume Next
    Set tdf = Nothing
    Set db = Nothing
    Exit Sub

err_handler:
    If Err.Number = -2147467259 Then
        MsgBox "This code already exists in this table. Check that you entered the " & _
               "new code as intended and adjust it if necessary", _
                vbCritical, _
                "Duplicate code value"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err

End Sub
