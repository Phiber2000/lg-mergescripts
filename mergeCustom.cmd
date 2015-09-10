@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

SET fileprefix=cust
SET prefixlength=4
SET notrunc=n

SET list=%fileprefix%_mergelist.txt
SET list_asc=%fileprefix%_mergelist_asc.txt
SET list_desc=%fileprefix%_mergelist_desc.txt

:main
CALL :prepare
CALL :createLists
IF EXIST %list% (
	CALL :getFileSize
	CALL :mergeFile
	CALL :cleanup
)
PAUSE
GOTO :EOF

:prepare
SET /A prefixlength+=1
GOTO :EOF

:createLists
FOR /F "eol= tokens=* delims=" %%i IN ('DIR %fileprefix%_*.bin /B') DO (
	SET file=%%i
	SET file=!file:~%prefixlength%,-4!
	SET file=00000000!file!
	SET file=!file:~-7!
	ECHO !file!>>%list%
)
IF EXIST %list% (
	SORT %list%>%list_asc%
	SORT /R %list%>%list_desc%
)
GOTO :EOF

:getFileSize
FOR /F "eol= tokens=* delims=0" %%i IN (%list_desc%) DO (
	IF NOT DEFINED filesize (
		SET filesize=%%i
		GOTO :break_getFileSize
	)
)
:break_getFileSize
GOTO :EOF

:mergeFile
IF NOT DEFINED filesize GOTO :EOF
IF EXIST %fileprefix%.img DEL %fileprefix%.img
IF "%notrunc%"=="y" DD.EXE if=/dev/zero of=%fileprefix%.img bs=512 count=%filesize%
FOR /F "eol= tokens=* delims=0" %%i IN (%list_asc%) DO (
	IF NOT DEFINED offset SET offset=%%i
	SET size=%%i
	SET /A skip=%%i-!offset!
	DD.EXE if=%fileprefix%_!size!.bin of=%fileprefix%.img bs=512 count=!size! seek=!skip!
)
GOTO :EOF

:cleanup
IF EXIST %list% DEL %list%
IF EXIST %list_asc% DEL %list_asc%
IF EXIST %list_desc% DEL %list_desc%
GOTO :EOF
