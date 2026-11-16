# What MS Mail's "Outlook" connection runs (embedded in kyle-ms-mail/docker-compose.yml
# as -EncodedCommand; comment lines are stripped, so keep it short).
# 1. Starts sign-in apps (Sync.com, OneDrive, ...) that aren't running: the Outlook-only
#    (RemoteApp) view has no Explorer desktop, so Windows doesn't start them itself.
# 2. Reuses a running Outlook, otherwise starts it.
# 3. Re-fits Outlook only if it isn't maximized to the tab; stops once it has looked
#    right for 3 checks in a row (~1 s). Gives up after ~12 s.
$r=@((ps).Path)
foreach($k in 'HKCU:','HKLM:','HKLM:\Software\WOW6432Node'){$p=gp "$k\Software\Microsoft\Windows\CurrentVersion\Run" -EA 0
if($p){foreach($v in $p.PSObject.Properties){if($v.Name -like 'PS*' -or $v.Name -eq 'SecurityHealth'){continue}
$c=[Environment]::ExpandEnvironmentVariables([string]$v.Value).Trim()
if($c -match '^"([^"]+)"\s*(.*)$' -or $c -match '^(\S+?\.exe)\s*(.*)$'){$e=$Matches[1];$a=$Matches[2]
if($r -notcontains $e -and (Test-Path $e)){if($a){start $e $a}else{start $e}}}}}}
$s=New-Object -ComObject WScript.Shell
foreach($d in [Environment]::GetFolderPath(7),[Environment]::GetFolderPath(24)){foreach($l in (gci $d -Filter *.lnk -EA 0)){if($r -notcontains $s.CreateShortcut($l.FullName).TargetPath){start $l.FullName}}}
function W{ps olk -EA 0|?{$_.MainWindowHandle -ne 0}|select -First 1}
$w=W
if(!$w){start explorer.exe 'shell:AppsFolder\Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows'
for($i=0;$i -lt 60 -and !$w;$i++){sleep -m 500;$w=W}}
if($w){Add-Type -A System.Windows.Forms
Add-Type -Namespace M -Name U -MemberDefinition '[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr h,int c);[DllImport("user32.dll")]public static extern bool IsZoomed(IntPtr h);[DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out R r);public struct R{public int L,T,X,B;}'
$ok=0
for($i=0;$i -lt 30 -and $ok -lt 3;$i++){$w=W
if($w){$h=$w.MainWindowHandle;$q=New-Object M.U+R;[void][M.U]::GetWindowRect($h,[ref]$q);$a=[Windows.Forms.Screen]::FromHandle($h).WorkingArea
if([M.U]::IsZoomed($h) -and ($q.X-$q.L) -ge $a.Width -and ($q.B-$q.T) -ge $a.Height){$ok++}else{$ok=0;[void][M.U]::ShowWindowAsync($h,9);[void][M.U]::ShowWindowAsync($h,3)}}
sleep -m 400}}
