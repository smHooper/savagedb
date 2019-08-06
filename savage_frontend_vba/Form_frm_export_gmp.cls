VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_export_gmp"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub btn_open_filepicker_Click()
'NOTE: To use this code, you must reference
'The Microsoft Office 16.0 (or current version)
'Object Library by clicking menu Tools > References
'   -Check the box for Microsoft Office 16.0 Object Library
''   -Click OK
'
'With Application.FileDialog(msoFileDialogFolderPicker)
'    .title = "Select an output folder"
'
'    If .Show Then
'        Me.txt_output_path = .SelectedItems(1)
'    End If
'
'End With

    Me.txt_output_path = savagedb.open_file_dialog()

End Sub



Private Sub dropdown_start_AfterUpdate()

'update the end year dropdown so only years after start year are shown
    
    On Error GoTo err_handler
    
    Dim start_year As String: start_year = Me.dropdown_start
    Dim current_row_souce As String: current_row_source = Me.dropdown_start.RowSource
    
    ' Apparently VBA doesn't have a Min() function so just make sure end >= start with an if block
    If Me.dropdown_start > Me.dropdown_end Then
        Me.dropdown_end = Me.dropdown_start
    End If
    
    Me.dropdown_end.RowSource = ""
    Me.dropdown_end.RowSource = Replace(current_row_source, _
                                        "ORDER BY 1 DESC", _
                                        " WHERE Year(datetime) >= " & start_year & " ORDER BY 1 DESC")
    Me.dropdown_end.Requery
    
    ' If the start year is the most recent, set the end year to the same
    If Int(Me.dropdown_start) = DMax("Year(datetime)", "accessibility") Then
        Me.dropdown_end = Me.dropdown_start
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_run_Click()

    Dim cmd As String
    
    On Error GoTo Err_btn_run_Click

    ' Check the inputs
    If IsNull(Me.dropdown_start) Then
        MsgBox "Please enter or select a start date", vbCritical, "Start date empty"
        Me.dropdown_start.SetFocus
        Exit Sub
    End If
    If IsNull(Me.dropdown_end) Then
        MsgBox "Please enter or select an end date", vbCritical, "End date empty"
        Me.dropdown_end.SetFocus
        Exit Sub
    End If
    ' Check that start year is before end year. I don't think this should ever happen
    '   because dropdown_end's row source query is updated to only include years >= start
    If Int(Me.dropdown_start) > Int(Me.dropdown_end) Then
        MsgBox "End year must be equal to or after start year", vbCritical, "Invalid 'End year' selection"
        Me.dropdown_end.SetFocus
        Exit Sub
    End If
    If IsNull(Me.txt_output_path) Then
        MsgBox "Please select an output folder", vbCritical, "Output folder empty"
        btn_open_filepicker_Click 'Open the file picker automatically when msg box closed
    End If
    
    ' Assemble the command
    Dim logfile As String: logfile = """" & Me.txt_output_path & "\log.txt"""
    Dim out_dir_arg As String: out_dir_arg = " --out_dir=""" & Me.txt_output_path & """"
    Dim years_arg As String: years_arg = " --years=""" & Me.dropdown_start & "-" & Me.dropdown_end & """"
    Dim stdout_str As String: stdout_str = " > """ & logfile & """ 2>&1"
    cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\query\gmp_count.py " & _
           CONNECTION_TXT & _
           out_dir_arg & _
           years_arg & _
           stdout_str
    savagedb.run_io_command cmd, Replace(logfile, """", ""), Me.txt_output_path
    
    
Exit_btn_run_Click:
    Exit Sub
    
Err_btn_run_Click:
    MsgBox Err.Description & " error"
    Resume Exit_btn_run_Click
    
    
End Sub

Private Sub Form_Load()
' Set the start and end dates to the most recent year
    
    On Error GoTo err_handler
    
    Dim year_max As Integer
    
    year_max = DMax("Year(datetime)", "accessibility")
    Me.dropdown_start = year_max
    dropdown_start_AfterUpdate
    'Me.dropdown_end = year_max

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub
