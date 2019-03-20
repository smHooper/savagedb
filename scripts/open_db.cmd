
SETLOCAL ENABLEDELAYEDEXPANSION
SET /a counter=0

:CHECKLOCKFILE
echo !counter!
IF "!counter!" == "%2" GOTO timeout_error
ping 127.0.0.0 -n 2 -w 500 > nul
SET /a counter+=1

IF EXIST "%~dpn1.laccdb" GOTO CHECKLOCKFILE
 
%1

EXIT /B

:timeout_error
echo x=MsgBox("The database could not be re-opened because Microsoft Access did not delete the lock file (.laccdb). You will have to open the file manually in the file Explorer.", 48, "Error: Could not re-open database") > %tmp%\tmp_msgbox.vbs
cscript //nologo %tmp%\tmp_msgbox.vbs
del %tmp%\tmp_msgbox.vbs
