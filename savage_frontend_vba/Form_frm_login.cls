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



Private Sub btn_login_Click()
    
    On Error GoTo err_handler
    
    Const adminuid = "savage_admin"
    Const adminpwd = "@d0lphmur!e"
    Const permituid = "savage_permit"
    Const permitpwd = "m@rdymur!e"
    
    Dim uid As String
    Dim pwd As String
    If lbl_login_type.Caption = "write access" Then
        uid = adminuid
        pwd = adminpwd
    ElseIf lbl_login_type.Caption = "permit" Then
        uid = permituid
        pwd = permitpwd
    Else
        MsgBox "lbl_login_type.Caption " & lbl_login_type.Caption & " not understood", vbCritical, "Login type not understood"
    End If
    
    Dim response As Integer
    
    If Me.txt_username <> uid Then
        MsgBox "The username you entered does not exist", vbCritical, "Authentication failure"
        Exit Sub
    ElseIf Me.txt_password <> pwd Then
        MsgBox "The password you entered is incorrect", vbCritical, "Authentication failure"
        Dim wShell As Object
        Set wShell = VBA.CreateObject("WScript.Shell")
        wShell.Run "cmd.exe /c start chrome https://www.youtube.com/watch?v=RfiQYRn7fBg", 0, False
        
        Exit Sub
    Else ' correct credentials
        ' Run the restart script only if the user selected "Yes". Othwerwise, exit
        If savagedb.restart_db(uid, pwd) <> vbYes Then
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
