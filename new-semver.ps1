[cmdletbinding()]
Param
(
    [parameter(mandatory)]
    [string]$BranchName,

    [parameter()]
    [string]$DotNetRoot = ''
)
begin
{
$errorActionPreference = 'Stop'
    disable-proxy

    # As of Mar 22, 2025 we (still) need to reference net8 8.0.13
    # for gitversion.tool to run.
    ci/dotnet-install.ps1 -Version 8.0.13 -Runtime windowsdesktop
}
process
{
    $useDotnetRoot = if($DotnetRoot.Length -eq 0)
    {
	"$(${Env:LocalAppData})/Microsoft/dotnet"
    }
    else
    {
	$DotnetRoot
    }
    If((Test-Path $UseDotnetRoot) -eq $false)
    {
	throw new-object argumentexception "DOTNET_ROOT: $($useDotnetRoot): No such path."
    }

    $Env:Path = $UseDotnetRoot + [System.IO.Path]::PathSeparator + $Env:Path
    $Env:DOTNET_ROOT = $UseDotnetRoot
    
    get-command dotnet
    dotnet --info
 dotnet gitversion /output buildserver /nonormalize /b $BranchName
}
