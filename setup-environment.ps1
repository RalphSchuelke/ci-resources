using namespace System.IO
[cmdletbinding()]
Param
(
  [parameter()]
  [validatescript({($_|get-item).exists})]
  [DirectoryInfo]$ProjectRoot = $env:APPVEYOR_BUILD_FOLDER,
  [parameter(Mandatory)]
  [DirectoryInfo]$CiPath
)

begin
{
  $ErrorActionPreference = 'stop'
  $VerbosePreference = 'continue'

  # update search path to include ourselves - this means preferring what we have over everything else
  # We also set up proxy cfg here.
  $env:Path = $CiPath.FullName + [path]::PathSeparator + $env:Path
  Write-Verbose "Setting search path to [$($env:Path)"
  
  enable-proxy  
}
process
{

  # set up dotnet and dotnet-tools
  dotnet-install -JsonFile ${Env:APPVEYOR_BUILD_FOLDER}/global.json -AzureFeed $Env:CI_RES_ROOT
   
  if($env:http_proxy.length -gt 0)
  {
    Write-Verbose "Set nuget proxy to $($env:http_proxy)"
    Start-Process -Wait -NoNewWindow   dotnet -ArgumentList  'nuget', 'config', 'set', 'http_proxy', ('"{0}"' -f $env:http_proxy)
  }
  else
  {
    Write-Verbose 'Note: Not updating nuget network connection details (connect immediately)'
  }
  Write-verbose 'Running command:' 
  write-host Start-Process -Wait -NoNewWindow dotnet -ArgumentList 'tool', 'restore', '--tool-manifest', ( '"{0}{1}.config{1}dotnet-tools.json"' -f $CiPath.FullName, [Path]::PathSeparator )
  Start-Process -Wait -NoNewWindow dotnet -ArgumentList 'tool', 'restore', '--tool-manifest', ( '"{0}{1}.config{1}dotnet-tools.json"' -f $CiPath.FullName, [path]::PathSeparator )
   
  
  # Restore (all) cs projects as that's what's going to require network access.
  foreach($project in get-childitem -LiteralPath $ProjectRoot.FullName -Recurse -Force -Filter '*.csproj')
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