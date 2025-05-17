# === НАСТРОЙКИ ===
$SourceDir = "C:\path\to\source\directory"
$TargetDir = "C:\path\to\target\directory"
$ExcludeDirs = "Dir1", "Dir2", "Dir3"  # Массив директорий для исключения
$SyncIntervalMinutes = 30
# ==================

# Функция для проверки, находится ли путь в исключенной директории
function Is-PathExcluded {
    param (
        [string]$Path,
        [string[]]$ExcludedDirectories
    )
    foreach ($ExcludedDir in $ExcludedDirectories) {
        if ($Path -like "$ExcludedDir\*") {
            return $true
        }
    }
    return $false
}


while ($true) {
    Write-Host "Синхронизация... $(Get-Date)"

    # Синхронизация из sourceDir в targetDir
    Write-Host "Из $SourceDir в $TargetDir"
    Get-ChildItem -Path $SourceDir -Recurse | Where-Object { !$_.PSIsContainer } | ForEach-Object {
        $RelativePath = $_.FullName.Substring($SourceDir.Length).TrimStart("\")
        $TargetPath = Join-Path -Path $TargetDir -ChildPath $RelativePath

        if (Is-PathExcluded -Path $RelativePath -ExcludedDirectories $ExcludeDirs) {
            Write-Host "Пропускается: $RelativePath"
            continue
        }

        if (!(Test-Path -Path $TargetPath)) {
            Write-Host "Копирование: $($_.FullName) -> $TargetPath"
            Copy-Item -Path $_.FullName -Destination $TargetPath
        } else {
            $SourceLastWriteTime = $_.LastWriteTime
            $TargetLastWriteTime = (Get-Item -Path $TargetPath).LastWriteTime

            if ($SourceLastWriteTime -gt $TargetLastWriteTime) {
                Write-Host "Обновление: $($_.FullName) -> $TargetPath"
                Copy-Item -Path $_.FullName -Destination $TargetPath -Force
            }
        }
    }


    # Синхронизация из targetDir в sourceDir
    Write-Host "Из $TargetDir в $SourceDir"
    Get-ChildItem -Path $TargetDir -Recurse | Where-Object { !$_.PSIsContainer } | ForEach-Object {
        $RelativePath = $_.FullName.Substring($TargetDir.Length).TrimStart("\")
        $SourcePath = Join-Path -Path $SourceDir -ChildPath $RelativePath


        if (Is-PathExcluded -Path $RelativePath -ExcludedDirectories $ExcludeDirs) {
            Write-Host "Пропускается: $RelativePath"
            continue
        }

        if (!(Test-Path -Path $SourcePath)) {
            Write-Host "Копирование: $($_.FullName) -> $SourcePath"
            Copy-Item -Path $_.FullName -Destination $SourcePath
        } else {
            $TargetLastWriteTime = $_.LastWriteTime
            $SourceLastWriteTime = (Get-Item -Path -Path $SourcePath).LastWriteTime

            if ($TargetLastWriteTime -gt $SourceLastWriteTime) {
                Write-Host "Обновление: $($_.FullName) -> $SourcePath"
                Copy-Item -Path $_.FullName -Destination $SourcePath -Force
            }
        }
    }

    Write-Host "Синхронизация завершена."
    Start-Sleep -Seconds ($SyncIntervalMinutes * 60)
}

