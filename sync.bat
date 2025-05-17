@echo off
setlocal

:: === НАСТРОЙКИ ===
set "sourceDir=C:\path\to\source\directory"
set "targetDir=C:\path\to\target\directory"
set "excludeDirs=Dir1,Dir2,Dir3" :: Директории, разделенные запятыми, которые нужно исключить
set "syncInterval=30" :: Интервал синхронизации в минутах
:: ==================

:loop
echo Синхронизация... %date% %time%

:: Синхронизация из sourceDir в targetDir
call :sync "%sourceDir%" "%targetDir%"

:: Синхронизация из targetDir в sourceDir
call :sync "%targetDir%" "%sourceDir%"

echo Синхронизация завершена.

timeout /t %syncInterval% /nobreak > nul
goto loop

:sync
set "src=%~1"
set "dest=%~2"

for /r "%src%" %%a in (*) do (
  set "filePath=%%a"
  set "relativeFilePath=%%a"
  set "relativeFilePath=!relativeFilePath:%src%\=!"

  :: Проверка, не находится ли файл в исключенной директории
  set "exclude=false"
  for %%e in (%excludeDirs%) do (
    echo !relativeFilePath! | findstr /b /c:"%%e\" > nul
    if !errorlevel! equ 0 (
      set "exclude=true"
      goto :nextFile
    )
  )

  if "%exclude%"=="true" (
    :nextFile
    echo Пропускается: !relativeFilePath!
    goto :eof
  )

  set "destFilePath=%dest%\!relativeFilePath!"

  if not exist "!destFilePath!" (
    echo Копирование: "!filePath!" -> "!destFilePath!"
    xcopy /y /i "!filePath!" "!destFilePath!" > nul
  ) else (
    for %%b in ("!destFilePath!") do (
      if "%%~ta" GTR "%%~tb" (
        echo Обновление: "!filePath!" -> "!destFilePath!"
        xcopy /y "!filePath!" "!destFilePath!" > nul
      )
    )
  )
)

exit /b

endlocal
