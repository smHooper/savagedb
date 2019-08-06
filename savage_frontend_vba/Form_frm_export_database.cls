VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_frm_export_database"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub btn_open_filepicker_Click()

    Me.txt_output_dir = savagedb.open_file_dialog()

End Sub



Private Sub dpd_start_year_AfterUpdate()

'update the end year dropdown so only years after start year are shown
    
    On Error GoTo err_handler
    
    Dim start_year As String: start_year = Me.dpd_start_year
    Dim current_row_souce As String: current_row_source = Me.dpd_start_year.RowSource
    
    ' Apparently VBA doesn't have a Min() function so just make sure end >= start with an if block
    If Me.dpd_start_year > Me.dpd_end_year Then
        Me.dpd_end_year = Me.dpd_start_year
    End If
    
    Me.dpd_end_year.RowSource = ""
    Me.dpd_end_year.RowSource = Replace(current_row_source, _
                                        "ORDER BY 1 DESC", _
                                        " WHERE Year(datetime) >= " & start_year & " ORDER BY 1 DESC")
    Me.dpd_end_year.Requery
    
    ' If the start year is the most recent, set the end year to the same
    If Int(Me.dpd_start_year) = DMax("Year(datetime)", "nps_vehicles") Then
        Me.dpd_end_year = Me.dpd_start_year
    End If

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub

End Sub

Private Sub btn_run_Click()

    Dim cmd As String
    
    On Error GoTo Err_btn_run_Click

    ' Check the inputs
    If IsNull(Me.dpd_start_year) Then
        MsgBox "Please enter or select a start date", vbCritical, "Start date empty"
        Me.dpd_start_year.SetFocus
        Exit Sub
    End If
    If IsNull(Me.dpd_end_year) Then
        MsgBox "Please enter or select an end date", vbCritical, "End date empty"
        Me.dpd_end_year.SetFocus
        Exit Sub
    End If
    ' Check that start year is before end year. I don't think this should ever happen
    '   because dropdown_end's row source query is updated to only include years >= start
    If Int(Me.dpd_start_year) > Int(Me.dpd_end_year) Then
        MsgBox "End year must be equal to or after start year", vbCritical, "Invalid 'End year' selection"
        Me.dpd_end_year.SetFocus
        Exit Sub
    End If
    If IsNull(Me.txt_output_dir) Then
        MsgBox "Please select an output folder", vbCritical, "Output folder empty"
        btn_open_filepicker_Click 'Open the file picker automatically when msg box closed
    End If
    If Len(Dir(Me.txt_output_dir & "\*")) > 0 Then
        Dim response As Integer
        response = MsgBox("This directory already has files in it, which will be deleted and replaced with the exported data." & _
                          " Are you sure you want to continue?", _
                          vbYesNoCancel + vbQuestion, _
                          "Output folder not empty")
        If reponse = vbYes Then
            Kill Me.txt_output_dir & "\*"
            ' catch file access error
        End If
    End If
    
    Dim exclude_tables As New Dictionary
    exclude_tables.Add "turned_around", "turned_around"
    exclude_tables.Add "road_permits", "road_permits"
    exclude_tables.Add "permit_users", "permit_users"
    exclude_tables.Add "inholder_allotments", "inholder_allotments"
    exclude_tables.Add "contractor_project_types", "contractor_project_types"
    exclude_tables.Add "bus_codes", "bus_codes"
    exclude_tables.Add "destination_codes", "destination_codes"
    exclude_tables.Add "nps_work_groups", "nps_work_groups"
    exclude_tables.Add "nps_trip_purposes", "nps_trip_purposes"
    exclude_tables.Add "nps_approved_codes", "nps_approved_codes"
    
    
    Dim exclude_columns As New Dictionary
    exclude_columns.Add "driver_name", "driver_name"
    exclude_columns.Add "comments", "comments"
    exclude_columns.Add "entered_by", "entered_by"
    exclude_columns.Add "permit_number", "permit_number"
    exclude_columns.Add "observer_name", "observer_name"
    exclude_columns.Add "is_overnight", "is_overnight"
    exclude_columns.Add "n_lodge_ovrnt", "n_lodge_ovrnt"
    exclude_columns.Add "permit_holder", "permit_holder"
    exclude_columns.Add "inholder_code", "inholder_code"
    exclude_columns.Add "organization", "organization"
    exclude_columns.Add "entry_method", "entry_method"
    exclude_columns.Add "n_wheelchair", "n_wheelchair"
    
    Dim lookup_fields As New Dictionary
    lookup_fields.Add "bus_type", "bus_codes"
    lookup_fields.Add "approved_type", "nps_approved_codes"
    lookup_fields.Add "work_group", "nps_work_groups"
    lookup_fields.Add "trip_purpose", "nps_trip_purposes"
    
    
    Dim tdf As TableDef
    Dim field_str As String
    Dim fld As Field
    Dim qdf As QueryDef: Set qdf = CurrentDb.QueryDefs("_temp_query_local")
    Dim year As Integer
    Dim this_dir As String
    Dim join_stmt As String
    Dim output_file As String
    For year = Int(Me.dpd_start_year) To Int(Me.dpd_end_year)
        
        ' Check if a dir for this year exists
        this_dir = Me.txt_output_dir & "\" & year
        If Len(Dir(this_dir, vbDirectory)) = 0 Then MkDir (this_dir)
        
        For Each tdf In CurrentDb.TableDefs
            If Left$(tdf.Connect, 5) = "ODBC;" And Not exclude_tables.exists(tdf.Name) And Left(tdf.Name, 1) <> "~" Then
                join_stmt = tdf.Name & " INNER JOIN destination_codes ON destination_codes.code = " & tdf.Name & ".destination "
                For Each fld In tdf.fields
                    If Not exclude_columns.exists(fld.Name) Then
                        If fld.Name = "destination" Then ' use the destinaiton lookup table's name col
                            field_str = field_str & "destination_codes.name AS destination, "
                        ElseIf lookup_fields.exists(fld.Name) Then ' use the lookup table's name col
                            field_str = field_str & lookup_fields(fld.Name) & ".name AS " & fld.Name & ", "
                            join_stmt = "(" & join_stmt & ") INNER JOIN " & lookup_fields(fld.Name) & " ON " & tdf.Name & "." & fld.Name & " = " & lookup_fields(fld.Name) & ".code "
                        Else ' otherwise use the field name
                            field_str = field_str & tdf.Name & "." & fld.Name & ", "
                        End If
                    End If
                Next fld
                If Len(field_str) <> 0 Then ' If there are no field names except ones to exclude, field_str would be empty
                    field_str = Left(field_str, Len(field_str) - 2) ' trim last comma
                    qdf.sql = "SELECT " & field_str & " FROM " & join_stmt & " WHERE year(datetime)=" & year
                    output_file = this_dir & "\" & tdf.Name & ".csv"
                    DoCmd.TransferText acExportDelim, TableName:=qdf.Name, FileName:=output_file, HasFieldNames:=True
                End If
            End If
            field_str = ""
        Next tdf
    Next year
    
    
Exit_btn_run_Click:
    Exit Sub
    
Err_btn_run_Click:
    If Err.Number = 3051 Then
        MsgBox "The table """ & tdf.Name & """ cannot be exported because you currently have the file " & output_file & " open. Close the file and try again.", _
                vbCritical, _
                "File in use"
    Else
        MsgBox Err.Description & " error", vbCritical
    End If
    Resume Exit_btn_run_Click
    
End Sub

Private Sub Form_Load()
' Set the start and end dates to the most recent year
    
    On Error GoTo err_handler
    
    Dim year_max As Integer
    
    year_max = DMax("Year(datetime)", "nps_vehicles")
    Me.dpd_start_year = year_max
    dpd_start_year_AfterUpdate
    'Me.dpd_end_year = year_max

exit_sub:
    Exit Sub
    
err_handler:
    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
    Resume exit_sub
    
End Sub
