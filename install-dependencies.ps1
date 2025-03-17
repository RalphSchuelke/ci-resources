[cmdletbinding()]
Param
(
    [string[]] $ModuleList = @('Pester', 'Microsoft.PowerShell.PSResourceGet', 'ModuleBuilder')
)

begin
{
    $errorActionPreference = 'Stop'
    if($null -eq ( Get-Command dotnet ))
    {
	throw new-object exception 'Could not find dotnet CLI'
    }
}

process
{
    enable-proxy
    dotnet tool restore --tool-manifest ci/.config/dotnet-tools.json
    Install-PsResource $ModuleList -Scope CurrentUser
    Update-PsResource $ModuleList -Scope CurrentUser
    disable-proxy
    Import-module -Name $ModuleList
}
