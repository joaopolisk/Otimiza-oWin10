# ===============================
# Windows 10 Startup Cleaner Script
# ===============================

Write-Host "Criando ponto de restauracao..."
Checkpoint-Computer -Description "BeforeStartupCleanup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

# ===============================
# 1. Limpar pasta Startup
# ===============================
Write-Host "Removendo atalhos da pasta Startup..."

Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\*" -Force -ErrorAction SilentlyContinue

# ===============================
# 2. Limpar chaves Run
# ===============================
Write-Host "Limpando registro de inicializacao..."

$runKeys = @(
"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($key in $runKeys) {
    if (Test-Path $key) {
        Get-ItemProperty $key | ForEach-Object {
            $_.PSObject.Properties |
            Where-Object { $_.MemberType -eq "NoteProperty" } |
            ForEach-Object { Remove-ItemProperty -Path $key -Name $_.Name -ErrorAction SilentlyContinue }
        }
    }
}

# ===============================
# 3. Desativar tarefas de logon (nao Microsoft)
# ===============================
Write-Host "Desativando tarefas de logon..."

Get-ScheduledTask |
Where-Object {
    $_.Triggers -match "Logon" -and
    $_.TaskPath -notlike "\Microsoft*"
} |
Disable-ScheduledTask -ErrorAction SilentlyContinue

# ===============================
# 4. Desativar telemetria basica
# ===============================
Write-Host "Desativando telemetria..."

$services = "DiagTrack","dmwappushservice"

foreach ($svc in $services) {
    Stop-Service $svc -Force -ErrorAction SilentlyContinue
    Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# ===============================
# 5. Limpar arquivos temporarios
# ===============================
Write-Host "Limpando arquivos temporarios..."

Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# ===============================
# 6. Desativar hibernacao
# ===============================
Write-Host "Desativando hibernacao..."
powercfg -h off

Write-Host "Concluido. Reinicie o computador."
