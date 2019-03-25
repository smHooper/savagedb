VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Report_rpt_road_permit"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database





'Private Sub Report_Open(Cancel As Integer)
'    'On Error GoTo err_handler
'
'    Debug.Print Me.OpenArgs
'    Dim permit_type As String
'    Dim qr_path As String
'    Dim separator_positon As Integer
'    separator_postion = InStrRev(Me.OpenArgs, ",")
'    permit_type = left(Me.OpenArgs, separator_postion - 1)
'    qr_path = Right(Me.OpenArgs, Len(Me.OpenArgs) - separator_postion)
'
'    If Len(permit_type) <> 0 And Len(qr_path) <> 0 Then
'        Select Case permit_type
'            Case Is = "Accessibility"
'                Me.Section(acPageHeader).BackColor = RGB(128, 110, 171)
'            Case Is = "Employee"
'                Me.Section(acPageHeader).BackColor = RGB(194, 89, 99)
'            Case Is = "Inholder"
'                Me.Section(acPageHeader).BackColor = RGB(0, 0, 0)
'                Me.txt_title.ForeColor = RGB(255, 255, 255)
'                Me.txt_permit_number.ForeColor = RGB(255, 255, 255)
'            Case Is = "NPS Approved"
'                Me.Section(acPageHeader).BackColor = RGB(83, 123, 158)
'            Case Is = "NPS Contractor"
'                Me.Section(acPageHeader).BackColor = RGB(158, 158, 158)
'            Case Is = "Pro Photography and Commercial Filming"
'                Me.Section(acPageHeader).BackColor = RGB(212, 138, 68)
'            Case Is = "Subsistence"
'                Me.Section(acPageHeader).BackColor = RGB(214, 204, 45)
'            Case Else
'                Me.Section(acPageHeader).BackColor = RGB(255, 255, 255)
'        End Select
'
'        ' Set the path of the qr code image
'        Me.img_qr.Picture = qr_path
'
'    End If
'
'    Exit Sub
'
'exit_sub:
'    Exit Sub
'
'err_handler:
'    MsgBox Err.Number & ": " & Err.Description, vbCritical, "Error"
'    Resume exit_sub
'
'End Sub
