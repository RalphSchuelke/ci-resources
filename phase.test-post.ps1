<#
.Synopsis
  Phase-specific tasks -- post test

.Description
Run tasks after testing. Should contain anything related to deploying the package, as in signing, sealing, and preparing it for publishing it.
Once done it is to be assumed no further processing will happen except actual deployment of nupkg and, optionally, snupkg.
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

    # note: publish-module requires dotnet cli, so we need to dotnet-install first.

    # todo/fixme: be sure to handle ps modules only when instructed to do so.

# if($Env:BUILD_PSMODULE)
#     {
&  "${CiRoot}/publish-localartifact.ps1" -Verbose
#  }
}

end
{

}

