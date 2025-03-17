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

      write-warning "Using PS $PsEdition version = $($PsVersionTable.PSVersion)"

      $psVersionModPath = if($PsEdition-eq 'Core'){'PowerShell'}else{'WindowsPowerShell'}
      $Env:PsModulePath = '{1}/Documents/{2}\Modules{0}{3}' -f ([io.path]::pathseparator), $Env:UserProfile, $PsVersionModPath, $env:PsModulePath
      write-warning "Using module path = ${Env:PsModulePath}"
      Import-Module -Name $tool.Name -RequiredVersion $Tool.Version -Verbose

    }
}
