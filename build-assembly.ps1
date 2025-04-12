using namespace system.io
[cmdletbinding()]
Param
(
    [parameter()]
    [validateset('Debug','Release','')]
    [allowemptystring()]
    [string]$ProjectConfiguration = $Env:Configuration,
    [parameter()]
    [validateset('Backend','Cmdlet')]
    [string]$ProjectType = 'Backend',
    [parameter()]
    [directoryinfo]$ProjectRoot = "$PSScriptRoot/..",

    [parameter()]
    [string]$ProjectName = $Env:APPVEYOR_PROJECT_NAME,

    [parameter()]
    [string]$DotNetRoot = "$($Env:LOCALAPPDATA)/Microsoft/dotnet"
)

begin
{
    $errorActionPreference = 'Stop'
}

process
{
    If($ProjectConfiguration.Length -eq 0)
    {
	write-warning 'No project configuration specified. Defaulting to DEBUG.'
	$ProjectConfiguration = 'Debug'
    }
    
    If((Test-Path $DOTNETROOT)-eq$false)
    {
	throw new-object exception ".NET root path: not found: $($dotnetroot)"
    }
    $env:DOTNET_ROOT=$dotnetROOT

    $Env:GitVersion_NoNormalizeEnabled='true'
    # Note: dotnet restore is implied. It should have run earlier (esp in proxied networks).
    # We do not guarantee internet access at this point.

    # Lookup project. There should be only one so named.
    $MyProjectFile = Get-Childitem -Literalpath $ProjectRoot.FullName -Filter "${ProjectName}.csproj" -Recurse
    If($MyProjectFile.Count -ne 1)
    {
	throw new-object exception "Could not identify project file to build $ProjectName."
    }
    
    dotnet build -c $ProjectConfiguration ('"{0}"' -f $MyProjectFile.Fullname)
    dotnet pack  -c $ProjectConfiguration ('"{0}"' -f $MyProjectFile.Fullname)

    write-warning 'Collecting and publishing resources'
    write-warning "(JPMF.${$ProjectName}.$($Env:GitVersion_SemVer).*nupkg)"

    foreach($package in Get-childitem -LiteralPath $ProjectRoot.FullName -recurse -force -filter "JPMF.$($ProjectName).$($ProjectType).*nupkg")
    {
	Write-Verbose "Processing package: $($Package.FullName)"
	# note: this presumes repository configuration. Needs fixing.
	copy-item -destination "$($Projectroot.fullname)/$projectName"  -Path $package.fullname
    }
}
