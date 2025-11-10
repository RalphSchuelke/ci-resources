using namespace System.IO
using namespace system
<#
    .Description

    Ensure that the manifest (psd1) references binary code ("backend" assemblies as well as "frontend" cmdlets (which obviously are also assemblies).

    Thoughts must be given to how to reference these so that things will work as expected later; 
    unfortunately powershell is not too fond of side-by-side assembly loading so it is entirely possible
    we'll see a preloaded assembly we can't override. 

    Ideally, we'd spec minversion and maxversion that must be known to work with us beforehand (both backend and frontend assemblies).
    Frontend assemblies in particular might benefit from a RequiredVersion because obviously if those have been updated, this will affect the external interface.

    .Parameter ModulePath
    Where the manifest is to be found. Must resolve to a single module.
    We may want to also add more exact references (ex: fileinfo psdFile)

#>

[cmdletbinding()]
Param
(
  [parameter(Mandatory=$false)]
  [string]$ModuleName = 'WindowsFirewall',

  [parameter(Mandatory)]
  [DirectoryInfo]$ModulePath,

  [parameter(Mandatory = $false)]
  [version]$VersionExpected = '1.4.3',

  [parameter()]
  [validateset('Debug','Release')]
  [string]$Configuration = 'Release',

  [parameter()]
  [hashtable[]] $ValidTfm = @{
    Desktop = 'net481'
    Core = 'net8.0'
  }  
)

begin
{
  [scriptblock] $assemblyTemplate = {
    Param
    (
      [object[]] $coreList = @(),
      [object[]] $desktoplist = @()
    )
    @'    
    if(${{PSEdition}} -eq 'Core')
    {{      
      @('{0}')
    }}
    else
    {{
      @('{1}') 
    }}  
'@ -f ($corelist -join ''','''),( $desktoplist -join ''',''')
  }
}

process
{
  # Note: PsModuleManifest for psresourceget; ModuleManifest for PowershellGet (update only)
  # First, ascertain module structure is good:
  # - we'll at least need a path component equal to ModuleName
  # - we'll want (not need) a sub folder equal to this module's manifest-registered moduleversion
  # - we'll need a manifest that is named ModuleName.psd1 that identifies the module, so there must be exactly one of these.
  
  # We try to identify ONE path named ModuleName; if there's more then there's a bit of a problem and we may never get the ambiguity out.
  [directoryinfo]$ModRootPath = if($ModulePath.Name -eq $ModuleName) { $ModulePath } else { Get-ChildItem -Recurse -Force -Path $ModulePath.FullName -Filter $ModuleName -Directory | Select-Object -First 1}
  
  if($ModRootPath -eq $null) {throw New-Object exception 'Could not identify module path.'}
  
  [FileInfo[]]$ManifestFile = Get-ChildItem -Recurse -Force -Path $ModRootPath.FullName -File -Filter "${ModuleName}.psd1"
  
  if($ManifestFile.Count -gt 1) 
  {
    # if we have an expected version, we can postfilter on multi-match
    # this will only work for versioned folders, so we enumerate modulename\moduleversion path and see if it has modulename.psd1 in it.
    # If not, that's an error. 
    # Note: On case _sensitive_ file systems, this may not work as intended.
    $ManifestFile = Get-ChildItem ( Join-Path $ModRootPath.FullName -ChildPath $VersionExpected.ToString()) -File -Filter "${ModuleName}.psd1"
  }
  
  if($ManifestFile.Count -ne 1){throw New-Object Exception "Module path cannot be used (expected: 1 manifest; found: $($ManifestFile.Count))"}
  [psmoduleinfo] $ModManifest = Test-ModuleManifest -Path $ManifestFile[0].FullName
  
  # - Identify available assemblies (note: reference our own, only)
  
  foreach($requiredAssy in Get-ChildItem -Path $ModManifest.ModuleBase -Recurse -Force -Filter 'jpmf.*.backend.dll' | Where-Object {$_.FullName.StartsWith($ModRootPath.FullName) -or ($_.FullName.StartsWith($SourcePath.FullName) -and $_.FullName -match  ('bin\\{0}'-f[regex]::Escape($Configuration)))  }) 
  {
    $requiredAssy.fullname
    # note: We'd be better off add-type'ing each assembly and then registering it by its full name; unfortunately to do this we may have to resolve dependencies. Which must come from somewhere.
    #$thisAssy = Add-Type -Path $requiredAssy
  }
  
  $ModManifest| Update-ModuleManifest -RequiredAssemblies $assemblyTemplate.Invoke(0,1) -RequiredModules $assemblyTemplate.Invoke(3,4) -Verbose 

}

end
{

}