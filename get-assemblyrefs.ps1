[cmdletbinding()]
Param
(
  [parameter(mandatory,valuefrompipeline)]
  [system.io.fileinfo]$InputObject,

  [parameter()]
  [validatenotnullorempty()]
  [string]$ProjectName = $Env:APPVEYOR_PROJECT_NAME
)

process
{
  $safeParam = [regex]::escape($ProjectName)
  Write-Warning "Filter: $("JPMF\.$($safeparam)") ($($InputObject.FullName))"
  $haveNsRefs = Select-String -Path $inputObject.FullName -Pattern "(namespace\s+|\[)JPMF\.$($safeParam)\."
  if($haveNsRefs)
  { 
    New-Object psobject -Property @{
      HaveNsRefs = $true
      Path = $InputObject.FullName
    }
    Write-Warning "Found a match; updating assembly refs"        
  }
}
