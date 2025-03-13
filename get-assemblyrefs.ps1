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

    get-content $inputObject.FullName| where-object {$_ -i<match "^JPMF\.$($safaParam)\."} 
}
