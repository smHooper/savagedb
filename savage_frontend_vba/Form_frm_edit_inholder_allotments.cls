VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_edit_inholder_allotments"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Function reset_allotment_source()
' Reset the control source for the allotment textbox

    Dim column_name As String: column_name = "_" & Me.dropdown_year
    
    Me.frm_edit_inholder_allotments_sub.Form.txt_allotment.ControlSource = column_name
    
    DoCmd.RepaintObject acForm, "frm_edit_inholder_allotments"

End Function

Public Function update_edit_allotments_form_sources(year_str As String)
    
Dim parent_form As Form
    
    Set parent_form = Forms.frm_edit_inholder_allotments
    
    parent_form.Form.dropdown_year = year_str 'update dropdown
    CurrentDb.TableDefs("inholder_allotments").RefreshLink 'refresh the inholder's table
    parent_form.Form.dropdown_year.RowSource = ""
    parent_form.Form.dropdown_year.RowSource = "SELECT allotment_year FROM qry_inholder_allotment_years ORDER BY 1 DESC" 'should be able to use .requery but it doesn't work
    parent_form.Form.recordsource = ""
    parent_form.Form.recordsource = "SELECT * FROM inholder_allotments"
    parent_form.Form.frm_edit_inholder_allotments_sub.Form.recordsource = ""
    parent_form.Form.frm_edit_inholder_allotments_sub.Form.recordsource = "SELECT * FROM inholder_allotments"

End Function


Private Sub btn_add_new_column_Click()

Dim year_str As String
Dim year_column_name As String
    
    ' Can't assign year_str with a null string so check if the text box is null
    If IsNull(Me.txt_new_year) Then
        MsgBox "You must enter a year to create a new column for before you can add a new column", _
               vbExclamation, _
               "No year entered"
        Me.txt_new_year.SetFocus
        Exit Sub
    End If
  
    year_str = Me.txt_new_year
    
    ' Validate input here because validation rule prompts are incredibly annoying
    If Len(year_str) <> 4 Then
        MsgBox "Year must be 4 digits", vbCritical, "Invalid year entered"
        Me.txt_new_year.SetFocus
        Exit Sub
    ElseIf Int(year_str) < 0 Then
        MsgBox "Year must be a positive integer", vbCritical, "Invalid year entered"
        Me.txt_new_year.SetFocus
        Exit Sub
    ElseIf DCount("*", "qry_inholder_allotment_years", "allotment_year='" & year_str & "'") = 1 Then
        MsgBox "A column for " & year_str & " already exists", vbCritical, "Invalid year entered"
        Me.txt_new_year = ""
        Me.txt_new_year.SetFocus
        Exit Sub
    End If
    
    year_column_name = "_" & year_str 'postgres can't have columns that start with number
    
    ' Disable the textbox so it can't be changed until the form is closed
    Me.txt_new_year.Enabled = False
    
    ' Add the column via pass-through query
    Dim db As DAO.Database
    Dim tdf As TableDef
    Dim current_cnn_str As String
    Set db = CurrentDb
    Set tdf = db.TableDefs("inholder_allotments")
    current_cnn_str = Right(tdf.Connect, Len(tdf.Connect) - 5)
    pass_through_query "ALTER TABLE inholder_allotments ADD COLUMN " & year_column_name & " smallint;", _
                        False, _
                        current_cnn_str
    Set tdf = Nothing
    Set db = Nothing
    
    ' If copy from other column is checked, insert into new column
    If chk_copy_values.Value Then
        Dim selected_column As String: selected_column = "_" & Me.dropdown_year
        pass_through_query "UPDATE inholder_allotments SET " & year_column_name & " = " & selected_column & ";", _
                           False, _
                           current_cnn_str
                           
    End If
    
    ' Update the form
    update_edit_allotments_form_sources (year_str)
    reset_allotment_source
    
    ' Enable the delete column button
    Me.btn_delete_new_column.Enabled = True
    Me.btn_delete_new_column.Visible = True
    Me.btn_delete_col_disabled.Enabled = True
    Me.btn_delete_col_disabled.Visible = False
    
    
End Sub

Private Sub btn_delete_col_disabled_Click()
    MsgBox "Only a newly created column can be deleted. " & _
            "You must create a new column before it can be deleted.", _
            vbExclamation, "'Delete column' button disabled"

End Sub

Private Sub btn_delete_new_column_Click()
Dim year_str As String
Dim year_column_name As String
    
    year_str = Me.txt_new_year
    
    If DCount("*", "qry_inholder_allotment_years", "allotment_year='" & year_str & "'") = 0 Then
        MsgBox "Column for " & year_str & " does not exist", vbCritical, "Invalid year entered"
        Exit Sub
    End If
    
    year_column_name = "_" & year_str 'postgres can't have columns that start with a number
    
    ' Delete the column via pass-through query
    Dim db As DAO.Database
    Dim tdf As TableDef
    Set db = CurrentDb
    Set tdf = db.TableDefs("inholder_allotments")
    pass_through_query "ALTER TABLE inholder_allotments DROP COLUMN " & year_column_name & ";", _
                        False, _
                        Right(tdf.Connect, Len(tdf.Connect) - 5)
    Set tdf = Nothing
    Set db = Nothing
    
    ' Enable the textbox so it can't be changed until the form is closed
    Me.txt_new_year.Enabled = True
    Me.txt_new_year = "" ' Erase text
    Me.txt_new_year.SetFocus
    
    ' Update the form
    update_edit_allotments_form_sources ("") ' year_str should be blank
    Me.frm_edit_inholder_allotments_sub.Form.txt_allotment.ControlSource = "" 'make the fields blank
    
    'Disable the delete button so it can't be accidentally used again to delete an old column
    Me.btn_delete_new_column.Enabled = False
    Me.btn_delete_col_disabled.Enabled = True
    Me.btn_delete_col_disabled.Visible = True
    
    DoCmd.RepaintObject acForm, "frm_edit_inholder_allotments"
    
    Me.txt_new_year.SetFocus

End Sub

Private Sub dropdown_year_AfterUpdate()
' Sub to detect user-initiated change of the year dropdown
    
    reset_allotment_source

End Sub

