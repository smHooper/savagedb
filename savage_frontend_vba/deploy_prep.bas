Attribute VB_Name = "deploy_prep"
Option Compare Database


Public Function replace_path_constants()
    
    Dim vb_component As VBComponent
    Dim code_module As VBIDE.CodeModule
    
    ' Set savagedb module constants
    DoCmd.OpenModule "savagedb"
    Set vb_component = VBE.VBProjects(1).VBComponents("savagedb")
    Set code_module = vb_component.CodeModule
    Dim i As Long
    With code_module
        For i = 1 To .CountOfLines
            If .lines(i, 1) Like "Public Const PYTHON_PATH*" Then
                .ReplaceLine i, "Public Const PYTHON_PATH As String = ""C:\ProgramData\Anaconda2\envs\savage\python.exe"""
            
            ElseIf .lines(i, 1) Like "Public Const CONNECTION_TXT*" Then
                .ReplaceLine i, "Public Const CONNECTION_TXT As String = ""D:\savage\config\connection_info.txt"""
            
            ElseIf .lines(i, 1) Like "Public Const SCRIPT_DIR*" Then
               .ReplaceLine i, "Public Const SCRIPT_DIR = ""D:\savage\scripts"""
            
            End If
        Next i
    End With
    DoCmd.Save acModule, "savagedb"
    DoCmd.Close acModule, "savagedb"
    
    'Set import_data constants
    DoCmd.OpenForm "frm_import_data"
    Set vb_component = VBE.VBProjects(1).VBComponents("Form_frm_import_data")
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
    DoCmd.Save acForm, "frm_import_data"
    DoCmd.Close acForm, "frm_import_data"
    
End Function
