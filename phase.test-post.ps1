<#
.Synopsis
  Phase-specific tasks -- init

.Description
Run tasks pre- repository clone. Can/Should ensure we at least have a git client so that we can do anything.


#>
[cmdletbinding()]
Param
(
[string]$CiRoot = $PSScriptRoot
)

begin
{

}

process
{
  # Try to set up an intermediate repository. This is not strictly necessary
  # but it allows us move through all the official channels rather than push code under the radar.
  # Note that, at this point, nothing is signed yet -- this will have to go here too (presumably) as signing sealing and packaging is only useful for anything that actually validates. (AND builds.)
Build-Module   -verbose -OutputDirectory ../Output -SemVer $Env:GitVersion_InformationalVersion

    # publish-module requires dotnet cli, so we need to dotnet-install first.
#  $CiRoot/publish-localartifact.ps1 -Verbose
}

end
{

}

