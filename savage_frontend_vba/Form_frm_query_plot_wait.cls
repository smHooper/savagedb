VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_query_plot_wait"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database


Private Sub btn_open_file_location_Click()
    
    On Error GoTo err_handler
    
    Dim output_dir As String
    
    If Me.btn_open_file_location.Tag <> "" Then
        output_dir = Me.btn_open_file_location.Tag
    Else
        output_dir = Forms!frm_query_plot!txt_output_path
    End If
    
    Shell "C:\WINDOWS\explorer.exe """ & output_dir & "", vbNormalFocus

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub

