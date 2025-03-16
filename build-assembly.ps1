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
    [string]$ProjectName = $Env:APPVEYOR_PROJECT_NAME
)

begin
{
    $errorActionPreference = 'Stop'
}

process
{
    $Env:GitVersion_NoNormalizeEnabled='true'
    #& "$($ProjectRoot.Fullname)/ci/new-semver.ps1" -BranchName "${Env:APPVEYOR_REPO_BRANCH}"
    dotnet restore          "$($ProjectRoot.FullName)/Source/$($ProjectType)/"
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
