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
    dotnet restore "$($ProjectRoot.FullName)/Source/$($ProjectType)/"
    dotnet build   "$($ProjectRoot.FullName)/Source/$($ProjectType)/"
    dotnet pack    "$($ProjectRoot.FullName)/Source/$($ProjectType)/"

    write-warning 'Collecting and publishing resources'
    write-warning "(JPMF.$($ProjectName).$($ProjectType).*nupkg)"

    foreach($package in Get-childitem -LiteralPath $ProjectRoot.FullName -recurse -force -filter "JPMF.$($ProjectName).$($ProjectType).*nupkg")
    {
	Write-Verbose "Processing package: $($Package.FullName)"
	publish-psresource -repository $projectName -Path $package.fullname
    }
}
