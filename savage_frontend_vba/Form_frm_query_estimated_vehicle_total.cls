VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_query_estimated_vehicle_total"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database



Private Sub btn_browse_Click()
    On Error GoTo err_handler
    
    Dim filter_str As String
    Dim filter_name As String

    Select Case Me.opg_plot_format
        Case Is = 1
            filter_str = "*.png"
            filter_name = "Portable Network Graphics"
        Case Is = 2
            filter_str = "*.jpg"
            filter_name = "JPEG"
        Case Is = 3
            filter_str = "*.pdf"
            filter_name = "Portable Document Format"
        Case Else
            filter_str = "*.png"
            filter_name = "Portable Network Graphics"
    End Select
    
    Dim selected_path As String
    selected_path = savagedb.open_file_dialog("Select an output file", msoFileDialogSaveAs, initial_view:=2)
    If Nz(selected_path) <> "" Then Me.txt_outpath = Left(selected_path, InStrRev(selected_path, ".") - 1) & Replace(filter_str, "*", "")
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub

Private Sub btn_run_Click()
    
    On Error GoTo err_handler
    
    Dim year As String: year = Nz(Me.dpd_year, "")
    
    Dim plot_type As String
    If Me.opg_plot_type = 1 Then plot_type = "bar" Else plot_type = "point"
        
    If Len(year) = 0 Then
        MsgBox "You must select a year to run the query", vbExclamation, "No year entered"
        Me.dpd_year.SetFocus
        Exit Sub
    ElseIf Len(Me.txt_outpath) = 0 Then
        MsgBox "You must select or enter an output path for the plot", vbExclamation, "No output path"
        Me.txt_outpath.SetFocus
        Exit Sub
    Else
        Dim cmd As String
        cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\query\predict_season_vehicle_total.py " & _
              CONNECTION_TXT & " " & _
              year & " " & _
              """" & Me.txt_outpath & """ " & _
              SCRIPT_DIR & "\predict_total_sensitivity_2002_2018.csv " & _
              plot_type
              
        Dim output_dir As String: output_dir = Left(Me.txt_outpath, InStrRev(Me.txt_outpath, "\") - 1)
        Dim logfile As String: logfile = output_dir & "\log.txt"
        
        savagedb.run_io_command cmd & "> """ & logfile & """ 2>&1", logfile, output_dir
        
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
End Sub
