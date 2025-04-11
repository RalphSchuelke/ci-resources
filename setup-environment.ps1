using namespace System.IO
[cmdletbinding()]
Param
(
  [DirectoryInfo]$ProjectRoot = $PSScriptRoot
)

begin
{
  $ErrorActionPreference = 'stop'
  $VerbosePreference = 'continue'

  # update search path to include ourselves - this means preferring what we have over everything else
  # We also set up proxy cfg here.
  $env:Path = $ProjectRoot.FullName + [path]::PathSeparator + $env:Path
  Write-Verbose "Setting search path to [$($env:Path)"
  
  enable-proxy
}
process
{

  # set up dotnet and dotnet-tools
   dotnet-install -JsonFile ${Env:APPVEYOR_BUILD_FOLDER}/global.json -AzureFeed $Env:CI_RES_ROOT
   Start-Process -Wait -NoNewWindow dotnet -ArgumentList 'tool', 'restore', '--tool-manifest', ( '"{0}{1}.config{1}dotnet-tools.json"' -f $ProjectRoot.FullName, [path]::PathSeparator )
   
  
  # Restore (all) cs projects as that's what's going to require network access.
  foreach($project in get-childitem -LiteralPath $ProjectRoot.FullName -Recurse -Force)
  {
    Write-Verbose "Processing project: $($Project.Name) ($($Project.directory.fullname))"
    Start-Process -Wait -NoNewWindow dotnet -ArgumentList 'restore', ('"{0}"' -f $project.fullname)
  }
}

end
{
  # clean up env
  disable-proxy 
  $VerbosePreference = 'silentlycontinue'
}