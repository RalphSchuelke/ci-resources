using namespace system.io
[cmdletbinding()]
Param
(
    [parameter()]
    [validateset('Backend','Cmdlet')]
    [string]$ProjectType = 'Backend',
    [parameter()]
    [directoryinfo]$ProjectRoot = "$PSScriptRoot/..",

    [parameter()]
    [string]$ProjectName = $Env:APPVEYOR_PROJECT_NAME,

    [parameter()]
    [string]$DotNetRoot = "$($Env:LOCALAPPDATA/Microsoft/dotnet)"
)

begin
{
    $errorActionPreference = 'Stop'
}

process
{
    If((Test-Path $DOTNETROOT)-eq$false)
    {
	throw new-object exception ".NET root path: not found: $($dotnetroot)"
    }
    $env:DOTNET_ROOT=$dotnetROOT

    $Env:GitVersion_NoNormalizeEnabled='true'
    enable-proxy
    dotnet restore          "$($ProjectRoot.FullName)/Source/$($ProjectType)/"
    disable-proxy
    dotnet build -c Release "$($ProjectRoot.FullName)/Source/$($ProjectType)/"
    dotnet pack  -c Release "$($ProjectRoot.FullName)/Source/$($ProjectType)/"

    write-warning 'Collecting and publishing resources'
    write-warning "(JPMF.$($ProjectName).$($ProjectType).*nupkg)"

    foreach($package in Get-childitem -LiteralPath $ProjectRoot.FullName -recurse -force -filter "JPMF.$($ProjectName).$($ProjectType).*nupkg")
    {
	Write-Verbose "Processing package: $($Package.FullName)"
	# note: this presumes repository configuration. Needs fixing.
	copy-item -destination "$($Projectroot.fullname)/$projectName"  -Path $package.fullname
    }
}
