VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_query_plot"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database


Private Sub dpd_time_step_AfterUpdate()
    
    On Error GoTo err_handler
    
    Select Case Me.dpd_time_step
        Case Is = "Year"
            Me.dpd_secondary_time.RowSource = "None"
        Case Is = "Month"
            Me.dpd_secondary_time.RowSource = "Year;Anniversary month;None"
        Case Is = "Day"
            Me.dpd_secondary_time.RowSource = "Year;Month;Anniversary day;Anniversary month;None"
        Case Is = "Hour"
            Me.dpd_secondary_time.RowSource = "Year;Month;day;Anniversary day;Anniversary month;None"
        Case Is = "Halfhour"
            Me.dpd_secondary_time.RowSource = "Year;Month;day;Anniversary day;Anniversary month;None"
        Case Else
            Me.dpd_secondary_time.RowSource = "None"
    End Select
    
    Me.dpd_secondary_time = "None"
    Me.dpd_secondary_time.SetFocus

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub
Private Function verify_checkboxes(searchStr As String) As Boolean
    Dim ctl As Control
    verify_checkboxes = True  'initialize return value as True
    For Each ctl In Me.Form.Controls
        If (ctl.ControlType = acCheckBox) Then
            If (ctl.Name Like searchStr) And (ctl.Value = False) Then
                verify_checkboxes = False
                Exit Function
            End If
        End If
    Next ctl
End Function

Private Function count_checkboxes(searchStr As String) As Variant
Dim ctl As Control
Dim count_total As Integer: count_total = 0
Dim count_true As Integer: count_true = 0
    
    For Each ctl In Me.Form.Controls
        If (ctl.ControlType = acCheckBox) Then
            If (ctl.Name Like searchStr) Then
                count_total = count_total + 1
                If ctl.Value Then
                    count_true = count_true + 1
                End If
            End If
        End If
    Next ctl
    
    count_checkboxes = Array(count_total, count_true)
    
End Function

Public Function select_all_checkboxes(searchStr As String)
    Dim ctl As Control
    For Each ctl In Me.Form.Controls
        If (ctl.ControlType = acCheckBox) Then
            If (ctl.Name Like searchStr) Then
                ctl.Value = True
            End If
        End If
    Next ctl
End Function

Private Function deselect_all_checkboxes(searchStr As String)
    Dim ctl As Control
    For Each ctl In Me.Form.Controls
        If (ctl.ControlType = acCheckBox) Then
            If (ctl.Name Like searchStr) Then
                ctl.Value = False
            End If
        End If
    Next ctl
End Function

Private Function plot_checkbox_clicked()
    btn_all_plts.Caption = "Select all"

End Function


Private Sub btn_all_plots_Click()
    
    On Error GoTo err_handler
    
    Dim all_checked As Boolean
    Dim SEARCH_STR As String
    
    SEARCH_STR = "chk_plot*"
    
    ' Check if all of the checkboxes with a name matching a given string are checked
    all_checked = verify_checkboxes(SEARCH_STR)
    
    If all_checked Then
        If btn_all_plots.Caption = "Deselect all" Then
            btn_all_plots.Caption = "Select all"
        End If
        deselect_all_checkboxes (SEARCH_STR)
    Else
        If btn_all_plots.Caption = "Select all" Then
            btn_all_plots.Caption = "Deselect all"
        End If
        select_all_checkboxes (SEARCH_STR)
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_all_queries_Click()
' Either select or deselect all query check boxes when clicked
    On Error GoTo err_handler
    
    Dim all_checked As Boolean
    Dim SEARCH_STR As String
    
    SEARCH_STR = "chk_query*"
    
    ' Check if all of the checkboxes with a name matching a given string are checked
    all_checked = verify_checkboxes(SEARCH_STR)
    
    If all_checked Then
        If btn_all_queries.Caption = "Deselect all" Then
            btn_all_queries.Caption = "Select all"
        End If
        deselect_all_checkboxes (SEARCH_STR)
    Else
        If btn_all_queries.Caption = "Select all" Then
            btn_all_queries.Caption = "Deselect all"
        End If
        select_all_checkboxes (SEARCH_STR)
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_all_optquery_Click()
    
    On Error GoTo err_handler
    
    Dim all_checked As Boolean
    Dim SEARCH_STR As String
    
    SEARCH_STR = "chk_optquery*"
    
    ' Check if all of the checkboxes with a name matching a given string are checked
    all_checked = verify_checkboxes(SEARCH_STR)
    
    If all_checked Then
        If btn_all_optquery.Caption = "Deselect" Then
            btn_all_optquery.Caption = "Select all"
        End If
        deselect_all_checkboxes (SEARCH_STR)
    Else
        If btn_all_optquery.Caption = "Select all" Then
            btn_all_optquery.Caption = "Deselect"
        End If
        select_all_checkboxes (SEARCH_STR)
    End If
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub


Private Sub btn_all_optplot_Click()
    On Error GoTo err_handler
    
    Dim all_checked As Boolean
    Dim SEARCH_STR As String
    
    SEARCH_STR = "chk_optplot*"
    
    ' Check if all of the checkboxes with a name matching a given string are checked
    all_checked = verify_checkboxes(SEARCH_STR)
    
    If all_checked Then
        If btn_all_optplot.Caption = "Deselect" Then
            btn_all_optplot.Caption = "Select all"
        End If
        deselect_all_checkboxes (SEARCH_STR)
    Else
        If btn_all_optplot.Caption = "Select all" Then
            btn_all_optplot.Caption = "Deselect"
        End If
        select_all_checkboxes (SEARCH_STR)
    End If
    
exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_open_filepicker_Click()
    
    On Error GoTo err_handler
    
    Dim out_dir As String: out_dir = savagedb.open_file_dialog()
    If out_dir = "" Then Exit Sub ' the user canceled
    
    If Not check_inputs(check_out_path:=False) Then Exit Sub
    
    ' Create the file name
    Dim summarize_tag As String: summarize_tag = Me.dpd_time_step
    If Nz(Me.dpd_secondary_time, "") <> "None" Then summarize_tag = Me.dpd_time_step & "_" & Me.dpd_secondary_time
    Dim file_name As String
    file_name = LCase(Me.dpd_summary_stat & "_of_" & Me.dpd_summary_field & "_by_" & summarize_tag & "_" & _
                Format(Me.txt_start_date, "yyyymmdd") & "_to_" & Format(Me.txt_end_date, "yyyymmdd") & ".csv") '{query_name}_{summary_stat}_by_{summarize_by}_{aggregate_by}{start_date}_{end_date}
    
    ' Store the output path in
    Me.txt_output_path = out_dir & "\" & file_name

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub
Public Function show_hide_filters()

Dim y_delta As Double: y_delta = 520 ' 1/3" in twips
Dim checkbox_counts As Variant
Dim count_true As Integer
    
    On Error GoTo err_handler
    
    If Me.chk_filter_values.Value Then
        checkbox_counts = count_checkboxes("chk_query*")
        count_true = checkbox_counts(1)
        If count_true > 1 Then
            MsgBox "Only one query can be run at a time if you are filtering values", vbCritical, "Multiple queries selected"
            Me.chk_filter_values.Value = False
            Exit Function
        End If
        
        ' Move the checkbox up
        Me.chk_filter_values.Move Me.chk_filter_values.Left, Me.chk_filter_values.Top - y_delta
        Me.lbl_filter_values.Move Me.lbl_filter_values.Left, Me.lbl_filter_values.Top - y_delta
        
        ' Show the text boxes
        Me.txt_sql_filter.Visible = True
        Me.lbl_sql_filter.Visible = True
        Me.txt_category_filter.Visible = True
        Me.lbl_category_filter.Visible = True
        Me.btn_show_categories.Visible = True
    
    Else
        ' Move the checkbox up
        Me.chk_filter_values.Move Me.chk_filter_values.Left, Me.chk_filter_values.Top + y_delta
        Me.lbl_filter_values.Move Me.lbl_filter_values.Left, Me.lbl_filter_values.Top + y_delta
        
        ' Hide the text boxes
        Me.txt_sql_filter.Visible = False
        Me.lbl_sql_filter.Visible = False
        Me.txt_category_filter.Visible = False
        Me.lbl_category_filter.Visible = False
        Me.btn_show_categories.Visible = False
    End If
    
    DoCmd.RepaintObject acForm, "frm_query_plot"

exit_sub:
    Exit Function
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Function

Private Sub chk_filter_values_Click()
' When checked, show filter textboxes
    show_hide_filters
End Sub
Private Function check_selected_queries() As Boolean

Dim checkbox_counts As Variant
Dim count_true As Integer

    checkbox_counts = count_checkboxes("chk_query*")
    count_true = checkbox_counts(1)
    
    check_selected_queries = True
    If count_true = 0 Then
        MsgBox "You must select 1 (and only 1) query to retreive category values for", vbExclamation, "No query selected"
        check_selected_queries = False
    ElseIf count_true > 1 And Me.chk_filter_values.Value Then
        MsgBox "Only one query can be run at a time if you are filtering values. Please check only one box under 'Query types'", _
                vbExclamation, _
                "Multiple queries selected"
        check_selected_queries = False
    End If

End Function
Private Sub btn_show_categories_Click()
' Show or hide categories listbox
    
    On Error GoTo err_handler
    
    Dim checkbox As Control
    Dim query_name As String
    Dim categories_str As String
    Dim cmd As String
    
    ' Check to see if exactly 1 query was checked. If not, notify the user
    If Not check_selected_queries Then
        Exit Sub
    End If
    
    If Me.lbx_destinations.Visible Then
        Me.lbx_destinations.Visible = False
        Me.rct_destinations_footer.Visible = False
        Me.btn_add_destinations.Visible = False
        Me.btn_show_destinations.Enabled = False ' Make sure someone can't click it while waiting for categories list box
    End If
    
    ' If the list box isn't visible, get values and show it.
    If Not Me.lbx_categories.Visible Then
        Dim ctl As Control
        For Each ctl In Me.Form.Controls
            If (ctl.ControlType = acCheckBox) Then
                If ctl.Value Then
                    If (ctl.Name Like "chk_query*") Then
                        query_name = ctl.Tag
                        cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\query\get_vehicle_categories.py " & _
                                query_name & _
                                " " & CONNECTION_TXT
                        Me.btn_show_categories.Enabled = False 'disable the button so the user can't click it again
                        Me.txt_category_filter.Enabled = False
                        categories_str = savagedb.run_stdout_command(cmd)
                        Me.txt_category_filter.Enabled = True
                        Me.btn_show_categories.Enabled = True
                        Me.lbx_categories.Visible = True
                        Me.rct_category_footer.Visible = True
                        Me.btn_add_categories.Visible = True
                        Me.lbx_categories.RowSource = categories_str
                        Me.btn_show_destinations.Enabled = True
                        DoCmd.RepaintObject acForm, "frm_query_plot"
                        Exit Sub
                    End If
                End If
            End If
        Next ctl
    ' Otherwise it's already visible, so hide it
    Else
        Me.lbx_categories.Visible = False
        Me.rct_category_footer.Visible = False
        Me.btn_add_categories.Visible = False
        DoCmd.RepaintObject acForm, "frm_query_plot"
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub


Private Sub btn_add_categories_Click()
' Set the category filter textbox text to a comma-separated list of all
' selected items in the categories list box
    On Error GoTo err_handler
    
    Dim selection_str As String: selection_str = ""
    Dim item_index As Variant
    
    ' If no selection was made, warn the user and exit
    If Me.lbx_categories.ListCount = 0 Then
        MsgBox "No categories selected to add to the filter. Either select items " & _
                "first or just type them manually in the text box", vbExclamation
        Exit Sub
    End If
    ' If the category filter textbox isn't empty, ask the user if they want to overwrite it
    If Not IsNull(Me.txt_category_filter) Then
        Dim msg_button As Integer
        msg_button = MsgBox("You have already entered text in the category filter " & _
                            "text box. Do you want to replace it with your selection? " & _
                            "To keep the text you already entered, click 'No'", _
                            vbYesNo, _
                            "Overwrite category filter text?")
        If msg_button = vbNo Then
            Exit Sub
        End If
    End If
    
    ' Loop through all selected items
    For Each item_index In Me.lbx_categories.ItemsSelected
            selection_str = selection_str & Me.lbx_categories.ItemData(item_index) & ", "
    Next item_index
    If Right(selection_str, 2) = ", " Then ' Drop the last ", "
        selection_str = Left(selection_str, Len(selection_str) - 2)
    End If
    
    Me.txt_category_filter = selection_str
    
    Me.lbx_categories.Visible = False
    Me.rct_category_footer.Visible = False
    Me.txt_category_filter.SetFocus
    Me.btn_add_categories.Visible = False
    
    DoCmd.RepaintObject acForm, "frm_query_plot"

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_show_destinations_Click()
' Show or hide categories listbox
    On Error GoTo err_handler
    
    Dim checkbox As Control
    Dim query_name As String
    Dim categories_str As String
    Dim cmd As String
    
    'If the other dropdown listbox is visible, hide it
    If Me.lbx_categories.Visible Then
        Me.lbx_categories.Visible = False
        Me.rct_category_footer.Visible = False
        Me.btn_add_categories.Visible = False
    End If
    
    ' If the list box isn't visible, get values and show it.
    If Not Me.lbx_destinations.Visible Then
        Me.lbx_destinations.Visible = True
        Me.rct_destinations_footer.Visible = True
        Me.btn_add_destinations.Visible = True
        DoCmd.RepaintObject acForm, "frm_query_plot"
        Exit Sub
    
    ' Otherwise it's already visible, so hide it
    Else
        Me.lbx_destinations.Visible = False
        Me.rct_destinations_footer.Visible = False
        Me.btn_add_destinations.Visible = False
        DoCmd.RepaintObject acForm, "frm_query_plot"
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_add_destinations_Click()
' Set the category filter textbox text to a comma-separated list of all
' selected items in the categories list box
    On Error GoTo err_handler
    
    Dim selection_str As String: selection_str = ""
    Dim item_index As Variant
    
    ' If no selection was made, warn the user and exit
    If Me.lbx_destinations.ListCount = 0 Then
        MsgBox "No destinations selected to add. Either select items " & _
                "first or just type them manually in the text box", vbExclamation
        Exit Sub
    End If
    ' If the category filter textbox isn't empty, ask the user if they want to overwrite it
    If Not IsNull(Me.txt_destinations) Then
        Dim msg_button As Integer
        msg_button = MsgBox("You have already entered text in the destination filter " & _
                            "text box. Do you want to replace it with your selection? " & _
                            "To keep the text you already entered, click 'No'", _
                            vbYesNo, _
                            "Overwrite destination filter text?")
        If msg_button = vbNo Then
            Exit Sub
        End If
    End If
    
    ' Loop through all selected items
    For Each item_index In Me.lbx_destinations.ItemsSelected
            selection_str = selection_str & Me.lbx_destinations.ItemData(item_index) & ", "
    Next item_index
    If Right(selection_str, 2) = ", " Then ' Drop the last ", "
        selection_str = Left(selection_str, Len(selection_str) - 2)
    End If
    
    Me.txt_destinations = selection_str
    
    Me.lbx_destinations.Visible = False
    Me.rct_destinations_footer.Visible = False
    Me.txt_destinations.SetFocus
    Me.btn_add_destinations.Visible = False
    
    DoCmd.RepaintObject acForm, "frm_query_plot"

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Function check_sql_criteria_and_queries() As Boolean
'Check if there could be a conflict between the SQL criteria
'given and the queries selected.

Dim checkbox_counts As Variant
Dim count_true As Integer
Dim response As Integer
    
    ' Set default return value
    check_sql_criteria_and_queries = True
    
    If txt_sql_criteria <> "" Then
        ' Check if more than one query is selected
        checkbox_counts = count_checkboxes("chk_query*")
        count_true = checkbox_counts(1)
        If count_true > 1 Then
            response = MsgBox("You have entered SQL criteria, and you have selected more than one query." & _
                              " The SQL statement might not be applicable to each query, and this could" & _
                              " result in an error. Would you like to continue anyway?", _
                              "Multiple queries selected")
            If response = vbCancel Or response = vbNo Then
                check_sql_criteria_and_queries = False
            End If
            Exit Function
        End If
        
        ' Check if any queries selected are actually multiple queries from different tables
        Dim ctl As Control
        For Each ctl In Me.Form.Controls
            If (ctl.ControlType = acCheckBox) Then
                If ctl.Value Then
                    If (ctl.Name Like "chk_query*") Then
                        query_name = ctl.Tag
                        If (query_name Like "summary") Or (query_name Like "pov") Or (query_name Like "total") Then
                            response = MsgBox("You have entered SQL criteria, and at least one of the queries you" & _
                                              " selected aggregates multiple queries from different tables." & _
                                              " Your SQL statement could result in an error. Would you like to" & _
                                              " continue anyway?", _
                                              vbExclamation + vbYesNoCancel, _
                                              "Query of multiple tables selected")
                            If response = vbCancel Or response = vbNo Then
                                check_sql_criteria_and_queries = False
                            End If
                            Exit Function
                        End If
                    End If
                End If
            End If
        Next ctl
    End If


End Function

Private Function check_inputs(Optional check_out_path As Boolean = True) As Boolean
    
    check_inputs = True
    
    If IsNull(Me.txt_start_date) Then
        MsgBox "Please enter or select a start date", vbCritical, "Start date empty"
        Me.txt_start_date.SetFocus
        check_inputs = False
    ElseIf IsNull(Me.txt_end_date) Then
        MsgBox "Please enter or select an end date", vbCritical, "End date empty"
        Me.txt_end_date.SetFocus
        check_inputs = False
    ElseIf IsNull(Me.dpd_time_step) Then
        MsgBox "Please select a time step to summarize by", vbCritical, "No time step selected"
        Me.dpd_time_step.SetFocus
        check_inputs = False
    ElseIf IsNull(Me.dpd_summary_field) Then
        MsgBox "Please enter a field to summarize", vbCritical, "Summary field empty"
        Me.dpd_summary_field.SetFocus
        check_inputs = False
    ElseIf IsNull(Me.txt_output_path) And check_out_path Then
        MsgBox "Please select an output folder", vbCritical, "Output folder empty"
        btn_open_filepicker_Click 'Open the file picker automatically when msg box closed
        check_inputs = False
    ElseIf CDate(Me.txt_end_date) < CDate(Me.txt_start_date) Then
        MsgBox "End date must be equal to or after start date", vbCritical, "Invalid date range"
        Me.txt_end_date.SetFocus
        check_inputs = False
    ElseIf Me.chk_filter_values And Not IsNull(Me.txt_sql_filter & Me.txt_category_filter) Then
        ' Verify that there is only 1 query selected if filtering values
        If Not check_selected_queries Then
            check_inputs = False
        End If
    ElseIf Not check_selected_queries Then
        check_inputs = False
    End If


End Function



Private Sub btn_run_Click()
' Run the Python script

    On Error GoTo Err_btn_run_Click
    
    ' Check the inputs
    If Not check_inputs() Then Exit Sub
    
    ' Check this here rather than after_update of SQL criteria because the user
    '   could enter the SQL, then select different queries.
    If Not check_sql_criteria_and_queries Then
        Exit Sub
    End If
    
    ' Get vars from inputs and assemble command
    Dim query_str As String: query_str = ""
    Dim plot_str As String: plot_str = ""
    Dim sql_filter_str As String: sql_filter_str = ""
    Dim category_filter_str As String: category_filter_str = ""
    Dim sql_criteria_str As String: sql_categor_str = ""
    Dim destinations_str As String: destinations_str = ""
    Dim title_str As String: title_str = ""
    Dim options_str As String: options_str = " --write_sql " ' start with a space so we don't have to prepend it later
    
    ' Loop through all controls and append the .Tag (the appropriate param value)
    '  to the appropriate strings if the a checkbox is checked
    Dim ctl As Control
    For Each ctl In Me.Form.Controls
        If (ctl.ControlType = acCheckBox) Then
            If ctl.Value Then
                If (ctl.Name Like "chk_query*") Then
                    query_str = query_str & ctl.Tag & ", "
                ElseIf (ctl.Name Like "chk_plot*") Then
                    plot_str = plot_str & ctl.Tag & ", "
                ElseIf (ctl.Name Like "chk_optquery*") Or (ctl.Name Like "chk_optplot*") Then
                    options_str = options_str & ctl.Tag & " "  ' tag for options is just flag so no need for comma
                End If
            End If
        End If
    Next ctl
    
    ' Get filter values if the filter values check box is checked
    If Me.chk_filter_values.Value Then
        If Not IsNull(Me.txt_sql_filter) Then
            sql_filter_str = " --sql_values_filter=""" & Me.txt_sql_filter & """"
        End If
        If Not IsNull(Me.txt_category_filter) Then
            category_filter_str = " --category_filter=""" & Me.txt_category_filter & """"
        End If
    End If
    
    ' Get the destinations and SQL criteria strings if they were given
    If Me.txt_destinations <> "" Then destinations_str = " --destinations=""" & Me.txt_destinations & """"
    If Me.txt_sql_criteria <> "" Then sql_criteria_str = " --sql_criteria=""" & Me.txt_sql_criteria & """"
    If Me.txt_custom_title <> "" Then title_str = " --custom_plot_title=""" & Me.txt_custom_title & """"
    
    ' prepend the query string with the parameter flag, clip extraneous commas and spaces
    '  from the end if there are any param values given, and make sure they're properly quoted
    '  since some of the plot options have spaces
    If query_str <> "" Then
        query_str = " --queries=""" & query_str
        If Right(query_str, 2) = ", " Then
            query_str = Left(query_str, Len(query_str) - 2)
        query_str = query_str & """" ' need 2 double-quotes because first escapes the second
        End If
    End If
    If plot_str <> "" Then
        plot_str = " --plot_types=""" & plot_str
        If Right(plot_str, 2) = ", " Then
            plot_str = Left(plot_str, Len(plot_str) - 2)
        plot_str = plot_str & """"
        End If
    End If
    
    ' Get start and end times if given
    Dim time_range As String: time_range = ""
    If Not IsNull(Me.txt_start_time) Then
        Me.txt_start_time.SetFocus
        If Not (Me.txt_start_time.text Like "##:##" Or Me.txt_start_time.text Like "#:##") Then
            MsgBox "Start time must be in the format hh:mm or h:mm", vbExclamation, "Incorrect start time format"
            Exit Sub
        End If
        Me.SetFocus
        time_range = " --time_range=""" & Right("0" & Left(Me.txt_start_time, 5), 5) ' Pad with leading 0 if necessary
    ElseIf Not IsNull(Me.txt_end_time) Then
        MsgBox "Start time was empty but end time was not. Either enter a start time to limit the times " & _
               "of day to query or delete the end time to query all times of day", _
               vbCritical, _
               "Invalid start/end time combination"
        Me.txt_start_time.SetFocus
        Exit Sub
    End If
    If Not IsNull(Me.txt_end_time) Then
        Me.txt_end_time.SetFocus
        If Not (Me.txt_end_time.text Like "##:##" Or Me.txt_end_time.text Like "#:##") Then
            MsgBox "End time must be in the format hh:mm or h:mm", vbExclamation, "Incorrect end time format"
            Exit Sub
        End If
        Me.SetFocus
        time_range = time_range & "-" & Right("0" & Left(Me.txt_end_time, 5), 5) & """"
    ElseIf Not IsNull(Me.txt_start_time) Then
        MsgBox "End time was empty but start time was not. Either enter an end time to limit the times " & _
               "of day to query or delete the start time to query all times of day", _
               vbCritical, _
               "Invalid start/end time combination"
        Me.txt_end_time.SetFocus
        Exit Sub
    End If
    
    ' Get output image format
    Dim selected_format As Integer
    Dim plot_ext_arg As String: plot_ext_arg = " --plot_extension="
    Select Case Me.opg_plot_format
        Case Is = 1
            plot_ext_arg = plot_ext_arg & """.png"""
        Case Is = 2
            plot_ext_arg = plot_ext_arg & """.jpg"""
        Case Is = 3
            plot_ext_arg = plot_ext_arg & """.pdf"""
        Case Else
            plot_ext_arg = plot_ext_arg & """.png"""
    End Select
    
    Dim aggregate_by_str As String: aggregate_by_str = ""
    If Nz(Me.dpd_secondary_time, "None") <> "None" Then
        aggregate_by_str = " --aggregate_by=""" & LCase(Me.dpd_secondary_time) & """"
    End If
    
    Dim start_date As String: start_date = " " & Me.txt_start_date
    Dim end_date As String: end_date = " " & Me.txt_end_date
    Dim summarize_by As String: summarize_by = " --summarize_by=" & Replace(LCase(Me.dpd_time_step), " ", "")
    Dim stat_str As String: stat_str = " --summary_stat=" & Me.dpd_summary_stat
    Dim field_str As String: field_str = " --summary_field=" & Me.dpd_summary_field
    
    Dim out_csv As String: out_csv = " --out_csv=""" & Me.txt_output_path & """"
    
    ' Redirect stdout and stderr to a file, which can then be used to check if the script is done
    '   Make sure the output_path doesn't end with "\", so we can safely append the file name
    '   with a "\"
    Dim output_dir As String: output_dir = Left(Me.txt_output_path, InStrRev(Me.txt_output_path, "\") - 1)
    Dim logfile As String: logfile = output_dir & "\log.txt"
    Dim stdout_str As String: stdout_str = "> """ & logfile & """ 2>&1" ' 2>&1 sends both stderr and stdout to file
    
    Dim cmd As String
    cmd = PYTHON_PATH & " " & SCRIPT_DIR & "\query\count_vehicles_by_type.py " & _
           CONNECTION_TXT & _
           start_date & _
           end_date & _
           out_csv & _
           stat_str & _
           field_str & _
           summarize_by & _
           aggregate_by_str & _
           query_str & _
           plot_str & _
           time_range & _
           sql_filter_str & _
           category_filter_str & _
           destinations_str & _
           sql_criteria_str & _
           title_str & _
           plot_ext_arg & _
           options_str & _
           stdout_str
    
    ' Run cmd
    Dim wShell As Object
    Set wShell = VBA.CreateObject("WScript.Shell")
    
    'wShell.Run "cmd.exe /S /K " & cmd
    savagedb.run_io_command cmd, logfile, output_dir
    
Exit_btn_run_Click:
    Exit Sub
        
Err_btn_run_Click:
    MsgBox Err.Description & " error"
    Resume Exit_btn_run_Click


End Sub


Public Function parse_command_from_readme(ByVal readme_path As String)
' Get the command from a previous run of count_vehicle_by_type and set form options accordingly
    
    On Error GoTo err_handler
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set text_file = fso.OpenTextFile(readme_path, 1)
    readme_text = text_file.ReadAll
    text_file.Close
    
    Dim line As Variant
    Dim args() As String
    Dim a As Variant
    Dim arg_dict As New Dictionary
    Dim arg_options() As String
    Dim i As Integer
    For Each line In Split(readme_text, vbCrLf)
        If line Like "ARGUMENTS:*" Then
            args = Split(Replace(line, "ARGUMENTS: ", ""), "||")
            Me.txt_start_date = args(2)
            Me.txt_end_date = args(3)
            For Each a In args
                If a Like "--*=*" Then
                    arg_dict(Split(a, "=")(0)) = Split(a, "=")(1)
                ElseIf a Like "--*" Then
                    ReDim Preserve arg_options(i)
                    arg_options(i) = a
                    i = i + 1
                End If
            Next a
            Exit For
        End If
    Next line
    
    If arg_dict.exists("--time_range") Then
        Me.txt_start_time = Split(arg_dict("--time_range"), "-")(0)
        Me.txt_end_time = Split(arg_dict("--time_range"), "-")(1)
    End If
    
    Dim plot_types() As String
    If arg_dict.exists("--plot_types") Then
        plot_types = Split(arg_dict("--plot_types"), ", ")
    Else
        select_all_checkboxes ("chk_plot*")
    End If
    
    Dim query_types() As String
    If arg_dict.exists("--queries") Then
        query_types = Split(arg_dict("--queries"), ", ")
    Else
        select_all_checkboxes ("chk_query*")
    End If
    
    ' If either of the filter args are given, show them
    If (arg_dict.exists("--sql_values_filter") Or arg_dict.exists("--category_filter")) Then
        Me.chk_filter_values.Value = True
        show_hide_filters
    End If
    
    If arg_dict.exists("--plot_extension") Then
        Select Case arg_dict("--plot_extension")
            Case Is = ".png"
                Me.opg_plot_format = 1
            Case Is = ".jpg"
                Me.opg_plot_format = 2
            Case Is = ".pdf"
                Me.opg_plot_format = 3
            Case Else
                Me.opg_plot_format = 1
        End Select
    End If
    
    ' Get plot/query options
    Dim ctl As Control
    Dim arg_names() As Variant: arg_names = arg_dict.Keys()
    For Each ctl In Me.Controls
        For Each a In query_types
            If ctl.Tag = a And ctl.ControlType = acCheckBox Then
                ctl.Value = True
                GoTo continue_loop
            End If
        Next a
        
        For Each a In plot_types
            If ctl.Tag = a And ctl.ControlType = acCheckBox Then
                ctl.Value = True
                GoTo continue_loop
            End If
        Next a
        
        For Each a In arg_options
            If ctl.Tag = a And ctl.ControlType = acCheckBox Then
                ctl.Value = True
                GoTo continue_loop
            End If
        Next a
        
        For Each a In arg_names
            If ctl.Tag = a And (ctl.ControlType = acTextBox Or ctl.ControlType = acComboBox) Then
                ctl.Value = arg_dict(a)
                GoTo continue_loop
            End If
        Next a
        
continue_loop:
    Next ctl
    
    
exit_sub:
    Exit Function
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Function
