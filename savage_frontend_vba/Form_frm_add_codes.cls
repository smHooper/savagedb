VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_add_codes"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database



Private Function set_tab_datasource(Optional tab_name As String)
    
    On Error GoTo err_handler
    
    Dim current_tab As String
    Dim current_query As String
    Dim current_table As String
    
    current_tab = Me.tcl_data.Pages(Me.tcl_data.Value).Name
    ' If tab_name is given
    If (Len(tab_name) > 0) And (current_tab <> tab_name) Then
        current_tab = tab_name
        Dim i As Integer
        For i = 0 To Me.tcl_data.Pages.Count - 1
            With Me.tcl_data.Pages(i)
                If .Name = current_tab Then
                    .SetFocus
                    Exit For
                End If
            End With
        Next i
    Else
        
    End If
    current_table = Right(current_tab, Len(current_tab) - 4)
    current_query = "qry_import_" & current_table
    
    Dim sub_form As Form
    'subform = Me.Form.Controls("sub_" & current_table).Form
    Me.Form.Controls("sub_" & current_table).SourceObject = "Query." & current_query ' References the query object, not SQL
    Me.Form.Controls("sub_" & current_table).Form.recordsource = current_query 'uses the SQL from the query
    Me.Form.Controls("sub_" & current_table).Form.Requery
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Function


Public Function load_missing_codes(temp_db_path As String, missing_val_table As String)
' For each distinct table in missing_lookup_values in temp_db
' show the all values from the data_value column as a comma-separated
' string in the txt_missing_values textbox of the associated tab
    
    On Error GoTo err_handler


    Dim distinct_rs As DAO.Recordset
    Dim sql_str As String
    sql_str = "SELECT DISTINCT lookup_table FROM " & missing_val_table & " IN '" & temp_db_path & "';"
    Set distinct_rs = CurrentDb.OpenRecordset(sql_str)
    Dim table_names() As String
    Dim i As Integer
    With distinct_rs
        If Not .BOF And Not .EOF Then
            .MoveFirst
            For i = 0 To .RecordCount - 1
                ReDim Preserve table_names(i)
                table_names(i) = .fields("lookup_table")
                .MoveNext
            Next i
        End If
        .Close
    End With
    Set distinct_rs = Nothing
    
    ' Loop through each table found
    Dim t_name As Variant
    Dim values_rs As DAO.Recordset
    Dim values_str As String: values_str = ""
    Dim tab_ind As Integer
    Dim ctl As Control
    Dim txt_box_name
    Dim missing_value As String
    
    ' Enable this so you can take focus off any of the tabs
    Me.blank_textbox.Enabled = True
    
    For tab_ind = 0 To Me.tcl_lookup_tables.Pages.Count - 1
        With Me.tcl_lookup_tables.Pages(tab_ind)
            'By default, make this tab invisible
            Me.blank_textbox.SetFocus 'set focus on dummy text box so the tab can be invisible
            .Visible = False
            ' Find the corresponding tab by matching the tag with the table name
            For Each t_name In table_names
                sql_str = "SELECT * FROM " & missing_val_table & " IN '" & temp_db_path & "' WHERE lookup_table = '" & t_name & "';"
                Set values_rs = CurrentDb.OpenRecordset(sql_str)
                If .Tag = t_name Then
                    ' This tab has missing values to show, so make it visible
                    .Visible = True ' Make this tab visible
                    
                    ' If there are any missing codes for this tab, set the missing_values textbox
                    If values_rs.RecordCount > 0 Then
                        values_rs.MoveFirst
                        .SetFocus
                        While Not values_rs.EOF 'For i = 0 To values_rs.RecordCount - 1
                            If IsNull(values_rs!data_value) Then
                                missing_value = """"""
                            Else
                                missing_value = values_rs!data_value
                            End If
                            values_str = values_str & Chr(149) & "  " & values_rs!data_table & " (" & values_rs!FileName & "): " & missing_value & vbCrLf
                            values_rs.MoveNext
                        Wend
                        ' Trim the last comma off the end. This would only be necessary if .RecordCount > 1
                        If Right(values_str, 1) = vbCrLf Then values_str = Left(values_str, Len(values_str) - 1)
                        
                        'Set the text in the text box to the value_str
                        txt_box_name = "lbl_missing" & Right(.Name, Len(.Name) - 3) '.Name is name of the tab
                        Me.Form.Controls(txt_box_name).Caption = values_str
                        Exit For
                    End If
                End If
            Next t_name
        End With
        values_str = ""
    Next tab_ind
    
    Set values_rs = Nothing

    ' Reset the dummy text box to be disabled
    Me.SetFocus
    Me.blank_textbox.Enabled = False
    
    ' Set the current tab to the first one that's visible
    For i = 0 To Me.tcl_lookup_tables.Pages.Count - 1
        With Me.tcl_lookup_tables.Pages(i)
            If .Visible Then
                .SetFocus
                Exit For
            End If
        End With
    Next i

    Exit Function

exit_err:
    On Error Resume Next
    current_db.Close
    Set current_db = Nothing
    Exit Function

err_handler:
    If Err.Number = 75 Or Err.Number = 70 Then
            MsgBox "A file for folder could not be accessed because it's currently in use. " & _
                    "Close all other applications and try again.", _
                    vbCritical, _
                    "File access error"
    Else
        MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    End If
    Resume exit_err


End Function
