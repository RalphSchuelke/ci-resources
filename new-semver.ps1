[cmdletbinding()]
Param
(
    [parameter(mandatory)]
    [string]$BranchName
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
    get-command dotnet
 dotnet gitversion /output buildserver /nonormalize /b $BranchName
}
