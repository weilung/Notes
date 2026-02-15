#Requires -RunAsAdministrator
# ============================================================
# Windows 10 System Optimization Script
# Usage: Right-click PowerShell -> Run as Administrator
#        powershell -ExecutionPolicy Bypass -File "Windows10_Optimize.ps1"
# ============================================================

Write-Host "=== Windows 10 System Optimization ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------
# 1. Disable unnecessary services
# ----------------------------------------
Write-Host "[1/6] Disabling unnecessary services..." -ForegroundColor Yellow

$services = @(
    @{ Name = 'SysMain';            Desc = 'Superfetch' },
    @{ Name = 'WSearch';            Desc = 'Windows Search Index' },
    @{ Name = 'DiagTrack';          Desc = 'Telemetry (Connected User Experiences)' },
    @{ Name = 'dmwappushservice';   Desc = 'WAP Push Message' },
    @{ Name = 'MapsBroker';         Desc = 'Downloaded Maps Manager' },
    @{ Name = 'lfsvc';              Desc = 'Geolocation Service' },
    @{ Name = 'RetailDemo';         Desc = 'Retail Demo Service' },
    @{ Name = 'WMPNetworkSvc';      Desc = 'Windows Media Player Network Sharing' },
    @{ Name = 'XblAuthManager';     Desc = 'Xbox Live Auth Manager' },
    @{ Name = 'XblGameSave';        Desc = 'Xbox Live Game Save' },
    @{ Name = 'XboxNetApiSvc';      Desc = 'Xbox Live Networking' },
    @{ Name = 'wisvc';              Desc = 'Windows Insider Service' },
    @{ Name = 'icssvc';             Desc = 'Windows Mobile Hotspot' },
    @{ Name = 'WbioSrvc';           Desc = 'Windows Biometric Service' },
    @{ Name = 'TabletInputService'; Desc = 'Touch Keyboard and Handwriting' },
    @{ Name = 'Fax';                Desc = 'Fax Service' },
    # @{ Name = 'PrintNotify';        Desc = 'Printer Extensions and Notifications' }  # Enable if using printer
)

$disabledCount = 0
foreach ($svc in $services) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Disabled: $($svc.Name) ($($svc.Desc))" -ForegroundColor Green
        $disabledCount++
    }
}
Write-Host "  Total: $disabledCount services disabled" -ForegroundColor Cyan

# ----------------------------------------
# 2. Visual effects - Best performance
# ----------------------------------------
Write-Host ""
Write-Host "[2/6] Setting visual effects to best performance..." -ForegroundColor Yellow

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2 -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value '0' -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' -ErrorAction SilentlyContinue

# Disable transparency
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 -ErrorAction SilentlyContinue

Write-Host "  Done" -ForegroundColor Green

# ----------------------------------------
# 3. Disable Game Mode and Game Bar
# ----------------------------------------
Write-Host ""
Write-Host "[3/6] Disabling Game Mode and Game Bar..." -ForegroundColor Yellow

New-Item -Path 'HKCU:\Software\Microsoft\GameBar' -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -Value 0 -ErrorAction SilentlyContinue

Write-Host "  Done" -ForegroundColor Green

# ----------------------------------------
# 4. Disable auto maintenance
# ----------------------------------------
Write-Host ""
Write-Host "[4/6] Disabling auto maintenance..." -ForegroundColor Yellow

New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance' -Name 'MaintenanceDisabled' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "  Done" -ForegroundColor Green

# ----------------------------------------
# 5. Disable Cortana
# ----------------------------------------
Write-Host ""
Write-Host "[5/6] Disabling Cortana..." -ForegroundColor Yellow

$cortanaPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
if (-not (Test-Path $cortanaPath)) {
    New-Item -Path $cortanaPath -Force | Out-Null
}
Set-ItemProperty -Path $cortanaPath -Name 'AllowCortana' -Value 0 -ErrorAction SilentlyContinue

Write-Host "  Done" -ForegroundColor Green

# ----------------------------------------
# 6. Power plan - High Performance
# ----------------------------------------
Write-Host ""
Write-Host "[6/6] Setting power plan to High Performance..." -ForegroundColor Yellow

powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null

Write-Host "  Done" -ForegroundColor Green

# ----------------------------------------
# Summary
# ----------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Optimization Complete!" -ForegroundColor Cyan
Write-Host " Restart recommended for full effect." -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
