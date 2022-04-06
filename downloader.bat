::Downloader.bat
::1st creates an SMB share and makes it read only
::then downloads any files specified in manifest.txt to the share
::
::Created for RIT CCDC 2022
::
::TODO
::Better error messages
::Add in option to  extract files then put them in the share
::Add hash checking to prevent download corruption and shenanigans
::Add program which checks file hashes continuously, this share could,
::   be a vector for red team if they replace sysinternals with malware.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off

::Check privilege
NET SESSION >nul 2>&1
IF %ERRORLEVEL% neq 0 (
    echo Rerun with Administrative privileges
    exit /B 1
)

::make the super secret folder
set /p shareDir="Share directory: "
mkdir %shareDir%
if %errorlevel% neq 0 (
  echo That directory already exists. Maybe try making a subdirectory?
  exit /b 0
)
icacls %shareDir% /q /setintegritylevel h >nul
powershell -Command  "New-SmbShare -Name "tools" -Path %shareDir% -ReadAccess 'everyone'" >nul

if %errorlevel% neq 0 ( ::quit if any errors
  echo.
  echo "Something went wrong. Check net share for an existing share and your share directory name and try again. (Remember to use \ not / in the directory name, to remove an existing share use NET SHARE [share directory] /delete)"
  echo cleaning up created folders...
  rmdir %shareDir%
  net share %shareDir% /delete
  exit /b 1
)

::print out share location
FOR /F "tokens=* USEBACKQ" %%F IN (`hostname`) DO (set hostname=%%F)
echo started fileshare @ "\\%hostname%\tools"
echo to add files to share simply put them in %shareDir%
echo edits to the share must be made as an Administrator on this machine
timeout /t 5

::automatically download to file share
echo.
echo.
echo.
echo Starting download of everything in /manifest.txt
echo.

::main download loop
FOR /F "eol=# tokens=1,2,3 USEBACKQ delims=," %%a IN (manifest.txt) DO (
  echo downloading %%a...
  powershell -command "Invoke-WebRequest -Uri %%c -OutFile %shareDir%\%%b"
  echo.
)

echo Done.
echo these commands may be useful for you:
echo "Invoke-WebRequest -Uri <source> -OutFile %shareDir%\ <dest>" to download more things
