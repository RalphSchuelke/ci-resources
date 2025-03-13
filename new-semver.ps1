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
}
process
{
 dotnet gitversion /output buildserver /nonormalize /b $BranchName
}
