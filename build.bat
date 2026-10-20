@echo off

powershell -ExecutionPolicy Bypass -File .\Update-Version.ps1 -ProjectFile "TulipErrorInline.dproj"

git-cliff -o "CHANGELOG.md"

:: Load Delphi environment variables
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"

:: Execute clean build
msbuild TulipErrorInline.dproj /t:Rebuild /p:Config=Release /p:Platform=Win32
