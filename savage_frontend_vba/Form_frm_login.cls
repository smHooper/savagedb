VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_login"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database
Option Explicit


Private Sub btn_login_Click()
    
    On Error GoTo err_handler
    
    If Len(Nz(Me.txt_username, "")) = 0 Then
        MsgBox "You must enter a Username to log on with different permissions.", vbCritical, "No Username given"
        Me.txt_username.SetFocus
        Exit Sub
    ElseIf Len(Nz(Me.txt_password, "")) = 0 Then
        MsgBox "You must enter a Password to log on with different permissions.", vbCritical, "No Password given"
        Me.txt_password.SetFocus
        Exit Sub
    End If
    
    Dim uid As String
    Dim pwd As String
    Dim user_key As String
    Dim credentials As New Dictionary: Set credentials = parse_parameter_file(Replace(CONNECTION_TXT, "connection_info.txt", "savage_db_credentials.txt"))
    If lbl_login_type.Caption = "write access" Then
        user_key = "admin"
        uid = credentials("admin_un")
        pwd = credentials("admin_pw")
    ElseIf lbl_login_type.Caption = "permit" Then
        user_key = "permit"
        uid = credentials("permit_un")
        pwd = credentials("permit_pw")
    Else
        MsgBox "lbl_login_type.Caption " & lbl_login_type.Caption & " not understood", vbCritical, "Login type not understood"
    End If
    
    Dim response As Integer
    
    
    If Nz(Me.txt_username, "") <> uid Then
        MsgBox "The username you entered does not exist", vbCritical, "Authentication failure"
        Exit Sub
    ElseIf Nz(Me.txt_password, "") <> pwd Then
        MsgBox "The password you entered is incorrect", vbCritical, "Authentication failure"
        Dim wShell As Object
        Set wShell = VBA.CreateObject("WScript.Shell")
        wShell.Run "cmd.exe /c start chrome https://www.youtube.com/watch?v=RfiQYRn7fBg", 0, False
        
        Exit Sub
    Else ' correct credentials
        ' Run the restart script only if the user selected "Yes". Othwerwise, exit
        If savagedb.restart_db(user_key) <> vbYes Then
            DoCmd.Close acForm, Me.Name
            Exit Sub
        End If
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub
