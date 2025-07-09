<#
.Synopsis
  Phase-specific tasks -- build

.Description
Run build related tasks.


#>
[cmdletbinding()]
Param
(
[string]$CiRoot = $PsScriptRoot
)

begin
{

}

process
{  
   & $CiRoot/dotnet-install.ps1 -Channel LTS
   & $CiRoot/new-semver.ps1 -BranchName $Env:APPVEYOR_REPO_BRANCH

  # create backing assembly (todo; make this dependent on whether there actually is something to be built)
  dotnet nuget list source
   & $CiRoot/build-assembly.ps1 -Verbose -ProjectType Backend

#  fixme: build ps module if appropriate config is set
If($env:BUILD_PSMODULE)
{
  Build-Module -Verbose -OutputDirectory ../Module-Test -SemVer $Env:GitVersion_InformationalVersion
}
}

end
{

}

