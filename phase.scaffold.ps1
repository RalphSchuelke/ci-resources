<#
.Synopsis
  Phase-specific tasks -- scaffold

.Description
Run tasks post- repository clone.

Should ensure we have a build environment.
Requires this repository to be present (obviously), so git submodule init/update must come before.

#>
[cmdletbinding()]
Param
(
[string]$CiRoot = $PsScriptRoot,
[string]$ProjectName = $Env:APPVEYOR_PROJECT_NAME
)

begin
{
	$ErroractionPreference = 'Stop'
}

process
{
  & "$CiRoot/new-temprepo.ps1" -repoName $ProjectName
  $null = New-Item ${Env:APPVEYOR_BUILD_BIN_FOLDER}/dotnet -Force -ItemType Directory -Verbose'
    # note: something will have to be done to permit passing, and registering, multiple TFM
    # in a single build. Not least because some NET tools may depend on one TFM
    # and we want to build using another. Or several "anothers".
  & "$CiRoot/dotnet-install.ps1" -JsonFile ${Env:APPVEYOR_BUILD_FOLDER}/global.json -InstallDir ${Env:APPVEYOR_BUILD_BIN_FOLDER}/dotnet -AzureFeed $Env:CI_RES_ROOT -Verbose

# Note: We omit -InstallDir to permit TFMs to persist across builds.
# This should reduce network costs.
# It will ALSO increase a risk of specific TFMs being updated at build time
# and these updates persisting when they aren't expected. So that's a doublesided sword.

# Pass Env:CI_RES_ROOT to have pipeline refer to a specific resource host
# eg off the public network, especially when we'd need a proxy otherwise.
# Not passsing a value just falls back on the Microsoft CDN.

# Note that we have to make sure there's a TFM to run tools too, especially when that tool
# requires a different TFM to what we're planning on using.

# This is going to require a somewhat more flexible implementation later. For now, just run
# dotnet-install twice.
  & $CiRoot/enable-proxy.ps1
  & $CiRoot/dotnet-install.ps1 -Channel LTS -AzureFeed $Env:CI_RES_ROOT
  & $CiRoot/dotnet-install.ps1 -JsonFile ${Env:APPVEYOR_BUILD_FOLDER}/global.json -AzureFeed $Env:CI_RES_ROOT
  Get-Item Env:/APPVEYOR* | format-table Name,Value
   & $CiRoot/install-dependencies.ps1
}

end
{

}

