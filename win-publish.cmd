@rem win-publish

set DEVEL=c:\tmp\devel
set DART_SDK=c:\dart\dart-sdk
set OBJ_SRC=%DEVEL%\obj

set OLD_CD=%CD%
cd %OBJ_SRC%
call %DART_SDK%\bin\pub publish
cd %OLD_CD%

@rem eof
