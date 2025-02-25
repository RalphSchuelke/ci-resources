[cmdletbinding()]
Param
(
    [Parameter()]
    [uri] $Proxy = $Env:HTTP_PROXY
)

process
{
    [hashtable]$ProxyConfig = @{}
    If($Proxy -ne $null)
    {
	$ProxyConfig.Add('Proxy', $Proxy)
    }

    Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile dotnet-install.ps1 @ProxyConfig

}
