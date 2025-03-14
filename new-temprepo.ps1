
<#
.Description
This is to somewhat cleanly set up a temporary repository for holding build artifacts.
Some further consideration is required if we even want some temporary build artifacts we then have to hold here... or if we want to require all dependencies to first be available globally before we depend on them.

This script is supposed to reliably fail if there is an issue.
Right now we try to sidestep anything that might go wrong along the way and only bail if by the end we don't have what we want.

Might want to reconsider this too, eg by failing the moment something goes wrong so that we know there's a consistent environment.

#>

[cmdletbinding()]
Param
(
    [parameter(mandatory)]
    [string]$RepoName,
    [string]$RepoRoot = $PWD
)
begin
{
$errorActionPreference = 'Stop'
}
process
{
    try
    {
	Unregister-PsResourceRepository -Name $RepoName
    }
    catch
    {
	write-warning ('Could not unregister temporary repository ({0}).' -f $repoName)
    }
    try
    {
	$repoPath = New-Item -ItemType Directory -Path $RepoName -Force
    }
    catch
    {
	write-warning ('Could not create repository path for [{0}]' -f $repoName)
    }

    try
    {
	[uri]$RepoLocation = "file://$($RepoRoot)/$($RepoName)"
	If($repoPath.Exists)
	{
	    Register-PSResourceRepository -Name $RepoName -Uri $RepoLocation -Trusted
	}
	else
	{
	    throw new-object exception 'Failed to set up repository'
	}
    }
    catch
    {
	write-warning 'Failed to set up repository'
	throw new-object exception 'Failed to set up repository'
    }
    write-verbose "Created temporary repository for $($RepoName)."
}
