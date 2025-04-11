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
  # provision tooling as defined in ci resources
  Start-Process -Wait -NoNewWindow dotnet -ArgumentList 'tool', 'restore', '--tool-manifest', ( '"{0}{1}.config{1}dotnet-tools.json"' -f $CiPath.FullName, [path]::DirectorySeparatorChar )
      
  # Restore (all) cs projects as that's what's going to require network access.
  # Note; we're doing a leap of faith here and ASSUME any and all external refs have gone into, or were at least cached by, the backend project.
  # We're not going to be able to hold this assumption for pure cmdlet projects. But it should probably work anyway (hopefully) on the assumption cmdlet projects do not require *additional* resources.
  # Well, except of course the powershell related packages. /shrug
  
    foreach($project in get-childitem -LiteralPath ('{1}{0}{2}{0}{3}' -f [path]::DirectorySeparatorChar, $ProjectRoot.FullName, 'Source' ) -Filter "$($Env:APPVEYOR_PROJECT_NAME).csproj")
  {
    Write-Verbose "Processing project: $($Project.Name) ($($Project.directory.fullname))"
    Start-Process -Wait -NoNewWindow dotnet -ArgumentList 'restore', ('"{0}"' -f $project.fullname)
  }
}

end
{
  # clean up env
  disable-proxy 
  
  # Preconfigure versioning. Note; we may have to do this offline (ie, without external access). 
  new-semver -BranchName $env:APPVEYOR_REPO_BRANCH
  
  $VerbosePreference = 'silentlycontinue'
}
