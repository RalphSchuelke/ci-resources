[cmdletbinding()]
Param
(
    [parameter(mandatory)]
    [string]$BranchName
)
begin
{
$errorActionPreference = 'Stop'
}
process
{
 dotnet gitversion /output buildserver /nonormalize /b $BranchName
}
