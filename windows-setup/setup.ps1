# One-time Windows setup for the Outlook Box / MS Mail Umbrel apps.
# dockur/windows runs this at the end of the unattended install (via COMMAND).
# Safe to run again by hand: open PowerShell as Administrator and run
#   iwr -UseBasicParsing https://raw.githubusercontent.com/kyleken/umbrel-apps/main/windows-setup/setup.ps1 | iex

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path 'C:\OEM' | Out-Null
Start-Transcript -Path 'C:\OEM\setup-log.txt' -Append | Out-Null

# --- 1. New Outlook for Windows -------------------------------------------
$outlook = Get-AppxPackage -AllUsers -Name 'Microsoft.OutlookForWindows' -ErrorAction SilentlyContinue
if ($outlook) {
    Write-Output "New Outlook already installed: $($outlook.Version)"
} else {
    Write-Output 'Downloading new Outlook installer from Microsoft...'
    $setup = 'C:\OEM\OutlookSetup.exe'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://go.microsoft.com/fwlink/?linkid=2207851' -OutFile $setup
    Write-Output 'Installing new Outlook for all users...'
    Start-Process -FilePath $setup -ArgumentList '--provision true --quiet --start-' -Wait
    Get-AppxPackage -AllUsers -Name 'Microsoft.OutlookForWindows' | Select-Object Name, Version
}

# --- 2. Allow RemoteApp (lets Guacamole show only the Outlook window) ------
$tsKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList'
New-Item -Path $tsKey -Force | Out-Null
Set-ItemProperty -Path $tsKey -Name 'fDisabledAllowList' -Type DWord -Value 1
$polKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
New-Item -Path $polKey -Force | Out-Null
Set-ItemProperty -Path $polKey -Name 'fAllowUnlistedRemotePrograms' -Type DWord -Value 1

# --- 3. No auto-start for Outlook -------------------------------------------
# MS Mail's "Outlook" connection launches Outlook itself (RemoteApp). A Startup
# shortcut would open a second copy, so remove the one older versions created.
Remove-Item -Force -ErrorAction SilentlyContinue 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Start Outlook.cmd'

# --- 4. Keep it light and always on ----------------------------------------
powercfg /hibernate off
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
# No lock screen / screensaver interrupting remote sessions
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'ScreenSaveActive' -Value '0' -ErrorAction SilentlyContinue

# --- 5. Turn off automatic sign-in ------------------------------------------
# A desktop session left signed in at boot makes Guacamole's "Outlook only"
# (RemoteApp) connection show a blank screen. Sign-in now happens over RDP.
$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty -Path $winlogon -Name 'AutoAdminLogon' -Value '0'
Remove-ItemProperty -Path $winlogon -Name 'DefaultPassword' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $winlogon -Name 'AutoLogonCount' -ErrorAction SilentlyContinue

Write-Output 'Setup finished.'
Stop-Transcript | Out-Null
