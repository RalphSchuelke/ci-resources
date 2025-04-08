[cmdletbinding()]
Param()
begin
{ 
  $errorActionPreference = 'Stop'
  Write-Host -NoNewline "Disable AppVeyor HTTP proxy..."
  $VerbosePreference='Continue'
}
process
{
	$npRegRoot = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

  try
  {
    Remove-ItemProperty -Path $NpRegRoot -Name ProxyEnable,ProxyServer,ProxyOverride -Force -ErrorAction SilentlyContinue
  }
  catch
  {
    write-warning "Could not unset proxy from registry"
    write-warning $_.exception.message
  }

  # notifying wininet
  $source=@"

[DllImport("wininet.dll")]

public static extern bool InternetSetOption(int hInternet, int dwOption, int lpBuffer, int dwBufferLength);  

"@

  #Create type from source
  $wininet = Add-Type -memberDefinition $source -passthru -name InternetSettings

  #INTERNET_OPTION_PROXY_SETTINGS_CHANGED
  $wininet::InternetSetOption([IntPtr]::Zero, 95, [IntPtr]::Zero, 0)|out-null

  #INTERNET_OPTION_REFRESH
  $wininet::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)|out-null


  remove-item -Path 'env:\APPVEYOR_HTTP_PROXY_IP',
  'Env:\APPVEYOR_HTTP_PROXY_PORT',
  'env:\http_proxy',
  'env:\HTTP_PROXY', 
  'env:\HTTPS_PROXY', 
  'env:\NO_PROXY' -Force -ErrorAction SilentlyContinue

  netsh winhttp reset proxy
  
  Write-Host 'OK' -ForegroundColor Green
}