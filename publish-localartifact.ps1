using namespace System.IO
using namespace System
using namespace System.Security.Cryptography.X509Certificates

<#
    we're basically signing and sealing the package here, so that it can be deployed to a repository.

    Care must be taken so we don't break our own processes as there is multi-level signing:

    1- Sign raw resource, in particular, psm1, psd1, and jpmf.*.dll assemblies. 
    # (Any other ressources may require additional handling => but need to be processed BEFORE we're done.)

    2- Once all raw components can be considered immutable, create a file catalog (.cat). Be sure to include anything that's to be deployed and exclude aynthing that's NOT;
    the catalog should match the package's contents exactly and will fail validation if there's more (or less) files than have been registered in it.

    3- Sign the catalog.

    4- Package, as in compress-psresource, the powershell module (if we're building one, obviously)

    5- Then sign that package too.

    6- Ready for deployment.

    We probably won't need to update assembly packages; we should verify them though so we don't hand out invalid / unusable artifacts.
    Although that should probably go into test/pre?

#>
[cmdletbinding()]
Param
(
  [string]$ProjectName = $Env:Powershell_Module_Name,
  [string]$ProjectRoot = $Env:APPVEYOR_BUILD_FOLDER,
  [string]$ModVersion  = $Env:GitVersion_MajorMinorPatch,
  [string]$OutputPath  = $Env:APPVEYOR_BUILD_FOLDER
)
begin
{
# be sure to stop on error, and do verbose output unless disabled
  $errorActionPreference = 'Stop'
  $VerbosePreference =  'Continue'
  
  # Set up proxy for dotnet if it has been requested. It should be able to pick up "standard" proxy envvars.
  if($env:use_http_proxy)
  {
    $env:http_proxy = ${env:use_http_proxy}
    $env:https_proxy = ${env:use_http_proxy}
    # note: no_proxy is passed explicitly as it doesn't affect anything if http_proxy is not configured;
    # if set it will be inherited from parent.
  }
  
  # set timestamp server
  [uri]$timestamper = 'http://timestamp.digicert.com'
}
process
{
  # select available code signing cert that matches thumbprint which was given on external configuration.
  # Doing this we don't need to check for validity; but it does mean we may attempt signing with an expired certificate if configuration is not updated in time.
  
  [X509Certificate2] $CodeSignature = Get-ChildItem -LiteralPath cert:\ -CodeSigningCert -Recurse -Force | Where-Object Thumbprint -eq $env:NuGetSignatureThumb | Select-Object -First 1
  [bool] $HaveCodeSignature = $CodeSignature -ne $null
  
  # do we have a usable certificate?
  if(-not $HaveCodeSignature -or $CodeSignature.NotBefore -gt [datetime]::Now -or $CodeSignature.NotAfter -lt [datetime]::Now ) 
  {
    # If not, set haveCodeSignature false - note? fixme? we may want to expand on this to log "have cert but it's not usable" as well as "don't have a cert by that identity"
    Write-Warning "A Certificate with id = $($env:NuGetSignatureThumb) cannot be used for signing on this node (does not exist or is not valid)"
    $HaveCodeSignature = $false
  }

  Write-Warning 'Prepare module before deploying it:'
  write-warning ' - confirm assembly SNK where applicable'
  write-warning ' - confirm assembly signature where applicable'
  write-warning " - create catalog (sealing package contents) in $($ProjectName).cat"

  # this will throw an exception if path is unavailable or is not a directory
  # so we  don't need to do explicit error handling here.
  [DirectoryInfo]$ModuleLocation = Get-Item "$ProjectRoot/Output/$ProjectName/$ModVersion"
  [FileInfo] $catalogFilePath = "$ProjectRoot/Output/$ProjectName/$ModVersion/$($ProjectName).cat"
  New-FileCatalog -CatalogFilePath $catalogFilePath.FullName  -Path $ModuleLocation.FullName
  if($HaveCodeSignature)
  {
    $result = Set-AuthenticodeSignature -Certificate $CodeSignature -TimestampServer $timestamper.AbsoluteUri -FilePath $catalogFilePath.FullName
  }
  write-warning ' - sign catalog (mind the timestamp)'
  write-warning ' - Verify assemblies are properly set up'
  # verify we have everything properly signed and sealed:
  # - verify strong name is valid (rather than delay signed)
  # - verify assembly has been signed - note, this means the assembly we built *right now* as opposed to whatever we find
  # - verify nuget (if any) has been signed
  # - maybe more
  # Only after that can we publish.
  
  foreach($assembly in get-childitem -recurse -force -path $moduleLocation.fullname -filter jpmf.*)
  {
    switch($assembly.Extension)
    {
      'nupkg' {	dotnet nuget verify ('"{0}"' -f $assembly.FullName) }
      'dll'
      {
        sn -v $assembly.fullname
        get-authenticodesignature $assembly.fullname
      }
    }
  }
  # publish-module can infer version folder. publish-psresource it seems cannot.
  # This requires some additional work - guard against presence of Build_psmodule env, sign created package but not pre-existing ones, and etc.
  Compress-PsResource -Path $ModuleLocation.FullName -DestinationPath $OutputPath 
  write-verbose 'Packages available for staging:'
  [FileInfo]$file = $null
  foreach($file in  Get-ChildItem -LiteralPath $OutputPath -Filter '*.nupkg' -Recurse -Force)
  {
    # dotnet nuget sign ... ?
    write-verbose "- $($file.FullName)"
  }
}
