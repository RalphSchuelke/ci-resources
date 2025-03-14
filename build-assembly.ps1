using namespace system.io
[cmdletbinding()]
Param
(
    [parameter()]
    [validateset('Backend','Cmdlet')]
    [string]$ProjectType = 'Backend',
    [parameter()]
    [directoryinfo]$ProjectRoot = "$PSScriptRoot/.."
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

    foreach($package in Get-childitem -recurse -force -filter "JPMF.$($ProjectRoot.Name).$ProjectType.*nupkg")
    {
	publish-psresource -repositorye $projectRoot.Name -Path $package.fullname
    }
}
