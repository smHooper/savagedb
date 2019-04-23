VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_query_buses_by_destination"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database



Private Sub txt_offset_hours_AfterUpdate()
' Validate offset
    On Error GoTo err_handler
    
    If Not IsNumeric(Me.txt_offset_hours.Value) Then
        MsgBox "The offset must be a number", vbCritical, "Invalid offset"
        Me.txt_offset_hours.SetFocus
        Exit Sub
    ElseIf Int(Me.txt_offset_hours) < 0 Then
        MsgBox "Offset must be a postive number", vbCritical, "Invalid offset"
        Me.txt_offset_hours.SetFocus
        Exit Sub
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Sub btn_run_Click()

    Dim destination_stmt As String: destination_stmt = ""
    Dim column_stmt As String
    
    On Error GoTo Err_btn_run_Click

    ' Check the inputs
    If IsNull(Me.txt_start_date) Then
        MsgBox "Please enter or select a start date", vbCritical, "Start date empty"
        Me.txt_start_date.SetFocus
        Exit Sub
    End If
    If IsNull(Me.txt_end_date) Then
        MsgBox "Please enter or select an end date", vbCritical, "End date empty"
        Me.txt_end_date.SetFocus
        Exit Sub
    End If
    If IsNull(Me.txt_start_time) Then
        MsgBox "Please enter a start time", vbCritical, "Start time empty"
        Me.txt_start_time.SetFocus
        Exit Sub
    End If
    If IsNull(Me.txt_end_time) Then
        MsgBox "Please enter an end time", vbCritical, "End time empty"
        Me.txt_end_time.SetFocus
        Exit Sub
    End If
    Me.txt_start_time.SetFocus ' For some stupid reason, you can access the .Text property unless the textbox has the focus
    If Not (Me.txt_start_time.text Like "##:##" Or Me.txt_start_time.text Like "#:##") Then
        MsgBox "Start time format must be 'HH:MM'", vbCritical, "Invalid start time"
        Exit Sub
    End If
    Me.txt_end_time.SetFocus
    If Not (Me.txt_end_time.text Like "##:##" Or Me.txt_end_time.text Like "#:##") Then
        MsgBox "Start time format must be 'HH:MM'", vbCritical, "Invalid start time"
        Exit Sub
    End If
    Me.SetFocus
    If CDate(Me.txt_end_date) < CDate(Me.txt_start_date) Then
        MsgBox "End date must be equal to or after start date.", vbCritical, "Invalid date range"
        Me.txt_end_date.SetFocus
        Exit Sub
    End If
    If TimeValue(Me.txt_end_time) <= TimeValue(Me.txt_start_time) Then
        MsgBox "End time must be after start time. Times should also be entered in 24-hour time (e.g., '23:59' for 11:59 PM).", vbCritical, "Invalid time range"
        Me.txt_end_time.SetFocus
        Exit Sub
    End If
    
    ' Check list box inputs
    Dim item_index As Variant
    Dim arr_index As Integer
    Dim i As Integer
    If Me.lbx_functions.ItemsSelected.Count = 0 Then
        MsgBox "You must select at least one aggregation function", vbCritical
        Me.lbx_functions.SetFocus
        Exit Sub
    End If
    
    If Me.lbx_destination.ItemsSelected.Count = 0 Then
        Dim destination_response As Integer
        destination_response = MsgBox("You did not select or enter a destination. " & _
                                      "Do you want to run the query and ignore destination?", _
                                      vbYesNo + vbQuestion, _
                                      "Destination empty")
        ' If the user didn't mean to leave it blank, exit the sub
        If destination_response = vbNo Then
            Me.lbx_destination.SetFocus
            Exit Sub
        End If
    ' If 1 or more items was selected, loop through them and construct the destination_stmt
    Else
        i = 1
        destination_stmt = " AND buses.destination IN ('"
        For Each item_index In Me.lbx_destination.ItemsSelected
            destination_stmt = destination_stmt & Me.lbx_destination.ItemData(item_index) & "', '"
            i = i + 1
        Next item_index
        destination_stmt = Left(destination_stmt, Len(destination_stmt) - 4) & "') "
    End If
    
    ' Assemble the query SQL
    Dim start_date As String: start_date = Format(CDate(Me.txt_start_date), "yyyy-mm-dd")
    Dim end_date As String: end_date = Format(CDate(Me.txt_end_date), "yyyy-mm-dd")
    Dim start_time As String: start_time = Me.txt_start_time
    Dim end_time As String: end_time = Me.txt_end_time
    Dim offset_hours As String: offset_hours = Me.txt_offset_hours
    Dim value_field As String: value_field = Me.dpd_field
    Dim sql_str As String
    Dim qdf As QueryDef
    Dim query_name As String: query_name = "_temp_query"

    ' Get string of columns
    i = 1
    
    Dim functions_str As String: functions_str = "" '
    Dim this_function As String
    Dim numeric_fields As String: numeric_fields = "'n_passengers', 'n_wheelchair', or 'n_lodge_ovrnt'"
    For Each item_index In Me.lbx_functions.ItemsSelected
        this_function = Me.lbx_functions.ItemData(item_index)
        If (this_function = "avg" Or this_function = "stddev" Or this_function = "sum") And (InStr(numeric_fields, value_field) = 0) Then
            MsgBox "You selected the function '" & this_function & "', but this function only works for numeric fields, not " & value_field & _
                   ". Either choose a different summary function or select one of the numeric fields (" & numeric_fields & ").", _
                   vbCritical, _
                   "Invalid function selected"
                   Me.dpd_field.SetFocus
            Exit Sub
        End If
        functions_str = functions_str & Me.lbx_functions.ItemData(item_index) & "(" & value_field & "), "
        i = i + 1
    Next item_index
    functions_str = Left(functions_str, Len(functions_str) - 2) & " "
    
    Dim where_clause As String
    where_clause = "WHERE " & _
                        "(datetime::date BETWEEN '" & start_date & "' AND '" & end_date & "') AND " & _
                        "((datetime + '" & offset_hours & " hours')::Time BETWEEN '" & start_time & "' AND '" & end_time & "') " & _
                        destination_stmt
    
    sql_str = "(SELECT destination_codes.name AS destination, " & functions_str & _
                "FROM buses INNER JOIN destination_codes ON destination_codes.code = buses.destination " & _
                where_clause & _
                "GROUP BY destination_codes.name) " & _
                "UNION ALL " & _
                "(SELECT constant AS destination, " & Replace(functions_str, "(" & value_field & ")", "") & " " & _
                "FROM (SELECT 'All selected destinations' As constant, " & functions_str & _
                " FROM buses " & where_clause & " " & _
                "Group BY constant) AS t);"
    
    ' Delete the query if it already exists
    Dim query_def As QueryDef
    For Each query_def In CurrentDb.QueryDefs
        If query_def.Name = query_name Then
            If SysCmd(acSysCmdGetObjectState, acQuery, query_name) <> 0 Then
                DoCmd.Close acQuery, query_name, acSaveNo
            End If
            DoCmd.DeleteObject acQuery, query_name
            Exit For
        End If
    Next query_def
    
    ' Run a pass through query
    Set qdf = CurrentDb.CreateQueryDef(query_name)
    qdf.Connect = "ODBC;" & savagedb.CONNECTION_STR & "UID=savage_read;PWD=0l@usmur!e;"
    qdf.sql = sql_str
    qdf.Close
    DoCmd.OpenQuery qdf.Name
    Set qdf = Nothing
    
    Exit Sub
    
Err_btn_run_Click:
    If Err.Description Like "* function * does not exist*" Then
        MsgBox "At least one of the summary functions you selected is not valid for the " & value_field & " column. " & _
               "If you are trying to calculate the average (avg) or standard deviation (stddev) of a field it must be " & _
               "either " & numeric_fields & ".", _
               vbCritical, _
               "Invalid summary function"
        Resume Next
    End If
    MsgBox Err.Description, vbCritical
    Exit Sub
    
    
End Sub

