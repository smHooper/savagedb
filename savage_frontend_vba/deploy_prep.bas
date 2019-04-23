Attribute VB_Name = "deploy_prep"
Option Compare Database


Public Function replace_path_constants(db_path As String)
    
    Dim vb_component As VBComponent
    Dim code_module As VBIDE.CodeModule
    
    Dim temp_app As Access.Application
    Set temp_app = New Access.Application
    With temp_app
        .OpenCurrentDatabase db_path, False
        
        ' Set savagedb module constants
        .DoCmd.OpenModule "savagedb"
        Set vb_component = .VBE.VBProjects(1).VBComponents("savagedb")
        Set code_module = vb_component.CodeModule
        Dim i As Long
        With code_module
            For i = 1 To .CountOfLines
                If .lines(i, 1) Like "Public Const PYTHON_PATH*" Then
                    .ReplaceLine i, "Public Const PYTHON_PATH As String = ""D:\savage\savage\python.exe"""
                
                ElseIf .lines(i, 1) Like "Public Const CONNECTION_TXT*" Then
                    .ReplaceLine i, "Public Const CONNECTION_TXT As String = ""D:\savage\config\connection_info.txt"""
                
                ElseIf .lines(i, 1) Like "Public Const SCRIPT_DIR*" Then
                   .ReplaceLine i, "Public Const SCRIPT_DIR = ""D:\savage\scripts"""
                ElseIf .lines(i, 1) Like "Public Const MASTER_DB_DIR*" Then
                   .ReplaceLine i, "Public Const MASTER_DB_DIR = ""D:\savage"""
                
                End If
            Next i
        End With
        .DoCmd.Save acModule, "savagedb"
        .DoCmd.Close acModule, "savagedb" ', acSaveYes
        
        'Set import_data constants
        .DoCmd.OpenForm "frm_import_data"
        Set vb_component = .VBE.VBProjects(1).VBComponents("Form_frm_import_data")
        Set code_module = vb_component.CodeModule
        With code_module
            For i = 1 To .CountOfLines
                If .lines(i, 1) Like "Private Const ARCHIVE_DIR*" Then
                    .ReplaceLine i, "Private Const ARCHIVE_DIR = ""D:\savage\app_data"""
                
                ElseIf .lines(i, 1) Like "Private Const DB_BROWSER_PATH*" Then
                    .ReplaceLine i, "Private Const DB_BROWSER_PATH = ""D:\savage\db_browser_for_sqlite\DB Browser for SQLite.exe"""
                
                End If
            Next i
        End With
        '.DoCmd.Save acForm, "frm_import_data"
        .DoCmd.Close acForm, "frm_import_data", acSaveYes
        
        .CloseCurrentDatabase
    End With
    Set temp_app = Nothing
    
End Function



Public Function deploy()
    
    Dim response As Integer
    response = MsgBox("Are you sure you want to prep this DB for deployment? This will change the values of constants for the RDS server", _
                       vbQuestion + vbYesNo, "Change constants for deployment?")
    If response <> vbYes Then Exit Function
    
    
    ' Get the current version number
    Dim rs As Recordset: Set rs = CurrentDb.OpenRecordset("SELECT version FROM user_state;")
    rs.MoveFirst
    Dim current_version As String: current_version = rs.fields("version")
    Set rs = Nothing
    
    ' Prompt user for a new version and validate it
    Dim new_version As String
    new_version = InputBox("Enter a new version number in the format xx.yy.zz that's greater than the current version: " & current_version)
    
    If UBound(Split(new_version, ".")) <> 2 Then
        MsgBox "Version number must be in the format xx.yy.vv", vbCritical, "Invalid version number"
        Exit Function
    End If
    Dim version_decimal As Variant
    For Each version_decimal In Split(new_version, ".")
        If Not IsNumeric(version_decimal) Then
            MsgBox "Each part of the version number must be an integer. You entered " & version_decimal, _
                vbCritical, "Invalid version number"
            Exit Function
        End If
    Next
    
    savagedb.export_vba_code "C:\Users\shooper\proj\savagedb\git\savage_frontend_vba"
    
    ' Set to read-only user
    savagedb.set_read_write "savage_read", "0l@usmur!e"
    
    ' Set version number
    CurrentDb.Execute ("UPDATE user_state SET version = '" & new_version & "';")
    
    ' Copy this DB to the new location
    Dim new_file_name As String: new_file_name = Replace(CurrentProject.Name, current_version, new_version)
    Dim master_path As String: master_path = "\\inpdenards\savage\" & new_file_name
    
    Dim cmd As String: cmd = "copy " & CurrentProject.FullName & " " & master_path
    Dim wShell As Object
    Set wShell = VBA.CreateObject("WScript.Shell")
    'wShell.Run "cmd.exe /c " & cmd, 0, True
    Dim fso As FileSystemObject
    Set fso = New FileSystemObject
    fso.CopyFile CurrentProject.FullName, master_path
    fso.CopyFile CurrentProject.FullName, CurrentProject.path & "\" & new_file_name
    
    ' If a log file exists, copy it over to the RDS server
    Dim change_log_path As String: change_log_path = CurrentProject.path & "\" & Dir(CurrentProject.path & "\change_log*.txt")
    Dim new_log_path As String: new_log_path = "\\inpdenards\savage\change_log_v" & new_version & ".txt"
    If change_log_path <> CurrentProject.path & "\" Then
        fso.CopyFile change_log_path, new_log_path
    Else
        MsgBox "No log file found with " & CurrentProject.path & "\change_log*.txt", vbExclamation, "No log file"
    End If
    
    Set fso = Nothing
    
    ' Replace constants in the new db
    replace_path_constants master_path
    
    ' Set the file to readonly
    SetAttr new_log_path, vbHidden
    SetAttr master_path, vbReadOnly 'Application.CurrentProject.FullName, vbReadOnly
    
    ' Copy everything from script dir to the RDS script dir. /e flag copies all files within source dir, but not the source dir itself
    cmd = "xcopy " & SCRIPT_DIR & " " & "\\inpdenards\savage\scripts /e /y /r" 'y - suppress warning, /r - write over readonly
    wShell.Run "cmd.exe /c " & cmd, 0, True ' Run command silently and wait for process to finish
    
    ' Set user state back to admin
    savagedb.set_read_write "savage_admin", "@d0lphmur!e"
    
    MsgBox "Front end succesfully deployed to " & master_path, vbInformation
    
End Function

