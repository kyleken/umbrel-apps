# What MS Mail's "Outlook" connection runs (embedded in kyle-ms-mail/docker-compose.yml
# as -EncodedCommand; comment lines are stripped).
# 1. Starts sign-in apps (Sync.com, OneDrive, ...) that aren't running: the Outlook-only
#    (RemoteApp) view has no Explorer desktop, so Windows doesn't start them itself.
# 2. Reuses a running Outlook, otherwise starts it. 3. Maximizes it to fill the tab.
$r = @((Get-Process).Path)
foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
  $p = Get-ItemProperty $k -EA 0
  if ($p) { foreach ($v in $p.PSObject.Properties) {
    if ($v.Name -like 'PS*' -or $v.Name -eq 'SecurityHealth') { continue }
    $c = [Environment]::ExpandEnvironmentVariables([string]$v.Value).Trim()
    if ($c -match '^"([^"]+)"\s*(.*)$' -or $c -match '^(\S+?\.exe)\s*(.*)$') {
      $e = $Matches[1]; $a = $Matches[2]
      if ($r -notcontains $e -and (Test-Path $e)) { if ($a) { start $e $a } else { start $e } }
    } } }
}
$s = New-Object -ComObject WScript.Shell
foreach ($d in [Environment]::GetFolderPath(7), [Environment]::GetFolderPath(24)) {
  foreach ($l in (gci $d -Filter *.lnk -EA 0)) { if ($r -notcontains $s.CreateShortcut($l.FullName).TargetPath) { start $l.FullName } }
}
function W { Get-Process olk -EA 0 | ? MainWindowHandle -ne 0 | select -First 1 }
$w = W
if (-not $w) {
  start explorer.exe 'shell:AppsFolder\Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows'
  for ($i = 0; $i -lt 60 -and -not $w; $i++) { sleep -m 500; $w = W }
}
if ($w) {
  Add-Type -Namespace M -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(System.IntPtr h, int c);'
  [M.U]::ShowWindowAsync($w.MainWindowHandle, 3) | Out-Null
}
