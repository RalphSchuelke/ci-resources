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
$errorActionPreference = 'Stop'
}
process
{
    Write-Warning 'Prepare module before deploying it:'
    write-warning ' - confirm assembly SNK where applicable'
    write-warning ' - confirm assembly signature where applicable'
    write-warning ' - create catalog (sealing package contents) in $($ProjectName).cat'

    # this will throw an exception if path is unavailable or is not a directory
    # so we  don't need to do explicit error handling here.
    [system.io.directoryinfo]$ModuleLocation = Get-Item "$ProjectRoot/Output/$ProjectName/$ModVersion"
    
    New-FileCatalog -CatalogFilePath "$ProjectRoot/Output/$ProjectName/$ModVersion/$($ProjectName).cat" -Path $ModuleLocation.FullName
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
    Compress-PsResource -Path $ModuleLocation.FullName -DestinationPath $OutputPath  -Verbose -ErrorAction Stop
    write-verbose 'Packages available for staging:'
    foreach($file in  get-childitem -Literalpath $outputpath -filter '*.nupkg' -recurse -verbose -force)
    {
	write-verbose "- $($file.fullname)"
    }
}
