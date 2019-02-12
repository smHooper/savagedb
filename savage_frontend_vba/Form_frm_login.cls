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
    Const uid = "savage_admin"
    Const pwd = "@d0lphmur!e"

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
    Else
        response = MsgBox("To switch users, the database will need to close and you'll have to re-open it (I know, " & _
                  "Access is pretty annoying, right?). Would you like to close and re-open the database now?", _
                  vbYesNoCancel, _
                  "Close and re-open database?")
        If response = vbYes Then
            generic.set_read_write Me.txt_username, Me.txt_password
            Application.Quit
        Else
            DoCmd.Close acForm, Me.name
            Exit Sub
        End If
    End If

End Sub
