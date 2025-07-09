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
#   & ./disable-proxy.ps1

    # As of Mar 22, 2025 we (still) need to reference net8 8.0.18
    # for gitversion.tool to run.
#    ci/dotnet-install.ps1 -Version 8.0.18 -Runtime windowsdesktop
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
    
    dotnet gitversion /output buildserver /nonormalize /b $BranchName

    # As a precaution, we check what gitversion handed back to us.
    # In particular, if we are building a tagged but unlabled build (eg because we're on main or release branch),
    # nuget(gallery) won't take our package because the versioning scheme will be rejected.

    if(($Env:GitVersion_Prereleaselabel.Length -eq 0) -and ($Env:GitVersion_PrereleaseTag.Length -gt 0))
    {
	throw new-object Exception 'Build configuration is faulty. Please switch to a labelled branch, or tag this build.'
    }
}
