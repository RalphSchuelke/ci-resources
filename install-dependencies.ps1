[cmdletbinding()]
Param
(
    [hashtable[]] $ModuleList = @(
    @{ Name = 'Pester';                             Version = '5.7.1'},
    @{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = '1.1.0'},
    @{ Name = 'ModuleBuilder';                      Version = '3.1.7'}
)
)

begin
{   
    $VerbosePreference = 'Continue'
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
    foreach($tool in $ModuleList)
    {
    # *-PsResource takes a -Version string that is interpreted according to nuget version range definitions,
    # so there is no -minimumversion/-requiredversion/-maximiumversion.
    # Passing an explicit version such as '1.2.3' will fetch, or update to, that version if none exists (install)
    # or an older version is present (update).
    # -Module in turn uses the classical minimum/maximum/requiredversion specifiers.
    
      Install-PsResource @tool -Scope CurrentUser -verbose
      Update-PsResource @tool -Scope CurrentUser -Verbose
      Import-Module -Name $tool.Name -RequiredVersion $Tool.Version -Verbose

    }
}
