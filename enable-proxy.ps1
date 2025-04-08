# Proxy addresses
if($Env:HTTP_PROXY -notmatch '^(https?://)?[0-9]{1,2}\.')
{
write-verbose 'Proxy not configured.'
return
}

[uri]$proxy = $Env:HTTP_PROXY
[string]$ProxyRegRoot = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

Write-Host -NoNewline 'Enabling AppVeyor HTTP proxy...'

$proxy_ip   = $proxy.Host
$proxy_port = $proxy.Port

$null = $(reg add $ProxyRegRoot /v ProxyEnable /t REG_DWORD /d 1 /f)
$null = $(reg add $ProxyRegRoot /v ProxyServer /t REG_SZ    /d "$proxy_ip`:$proxy_port" /f)

if($Env:NO_PROXY)
{
	$NpData = '"{0}"' -f $Env:NO_PROXY
	$null = $(reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d $NpData /f)
}

# notifying wininet
$source=@"

[DllImport("wininet.dll")]

public static extern bool InternetSetOption(int hInternet, int dwOption, int lpBuffer, int dwBufferLength);  

"@

#Create type from source
$wininet = Add-Type -memberDefinition $source -passthru -name InternetSettings

#INTERNET_OPTION_PROXY_SETTINGS_CHANGED
$null = $wininet::InternetSetOption([IntPtr]::Zero, 95, [IntPtr]::Zero, 0)

#INTERNET_OPTION_REFRESH
$null = $wininet::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)

# save proxy details in environment variables
$env:APPVEYOR_HTTP_PROXY_IP = $proxy_ip
$env:APPVEYOR_HTTP_PROXY_PORT = $proxy_port

$env:HTTPS_PROXY = $Env:HTTP_PROXY

Write-Host 'OK' -ForegroundColor Green