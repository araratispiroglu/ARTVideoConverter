@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

:menu
echo .
echo Choose what you want
echo [1] normal .AIR
echo [2] exe with included AIR runtime (captive), no installer
echo .

:choice
set /P C=[Choice]: 
echo.

set AIR_TARGET=-captive-runtime

if "%C%"=="1" call bat\Packager.bat
if "%C%"=="2" call bat\PackagerExe.bat

::set AIR_TARGET=
::call bat\Packager.bat

pause