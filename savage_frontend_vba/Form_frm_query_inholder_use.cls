VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_query_inholder_use"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Function regex_find_first(ByVal text As String) As String

    Dim result As String
    Dim matches As Object
    Dim re As Object
    Set re = CreateObject("vbscript.regexp")
    
    re.Pattern = "\d{4}"
    re.Global = True
    re.IgnoreCase = True
    Set matches = re.Execute(text)
    
    If matches.Count <> 0 Then
        result = matches.item(0)
    End If
    
    regex_find_first = result

End Function


Private Sub btn_run_Click()

    Dim year As String: year = Nz(Me.dpd_year, "")
    If Len(year) = 0 Then
        MsgBox "You must select a year to run the query", vbExclamation, "No year entered"
        Me.dpd_year.SetFocus
        Exit Sub
    Else
        Dim qdf As QueryDef
        Set qdf = CurrentDb.QueryDefs("qry_remaining_inholder_permits")
        DoCmd.Close acQuery, qdf.name, acSaveNo
        Dim old_sql As String: old_sql = qdf.sql
        qdf.sql = Replace(old_sql, regex_find_first(old_sql), year)
        
        DoCmd.OpenQuery qdf.name, DataMode:=acReadOnly
        DoCmd.RepaintObject acQuery, qdf.name
        
    End If

End Sub
