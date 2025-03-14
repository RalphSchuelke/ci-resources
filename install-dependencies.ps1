[cmdletbinding()]
Param
(
    [string[]] $ModuleList = @('Pester', 'Microsoft.PowerShell.PSResourceGet', 'ModuleBuilder')
)

begin
{
    # exactly WHY do things fail without this?
    $null=    new-item -itemtype directory -path $PWD -name appveyorTemp -verbose
    
#    & "$PSScriptroot/new-temprepo.ps1" -repoName $Env:APPVEYOR_PROJECT_NAME
    $errorActionPreference = 'Stop'
    if($null -eq ( Get-Command dotnet ))
    {
	throw new-object exception 'Could not find dotnet CLI'
    }
}

process
{
    dotnet tool install --tool-manifest ci/.config/dotnet-tools.json  gitversion.tool
    Install-PsResource $ModuleList -Scope CurrentUser
    Update-PsResource $ModuleList -Scope CurrentUser

    Import-module -Name $ModuleList
}
