BeforeAll {}

# TODO: This test seems to hold both CS and cmdlet references. Clean that up, so that we can split cs and cmdlet.

Describe "CS files" -Fixture {
    [system.io.directoryinfo] $testHome = "$psscriptroot/.."
    [system.io.directoryinfo] $modHome = $testHome.Parent
    [string]$ModName = $Env:Powershell_Module_Name
    Write-Warning "mod home = $($modhome.fullname)"
    #Write-Warning

    [system.collections.generic.list[hashtable]]$testCases = @()

    [system.io.fileinfo[]] $CsSourceFiles = Get-Childitem -Path $modHome.FullName -REcurse -Force -Filter '*.cs' |
      Where-Object Fullname -notmatch '[\\/](bin|obj)[\\/]'
    write-warning "Found $($cssourcefiles.count) CS files to process"



    foreach($file in $csSourceFiles)
    {
    $ns = select-string -pattern '^\s*namespace\s+(.*)$' -Path $file.fullname

    [microsoft.powershell.commands.matchinfo[]] $classIndicator = Select-String '^\s*[^/].+\b(interface|class|enum)\s+(?<className>[^ :]+):?.*$'  -Path $file.FullName

    #	write-warning "for element = $($file.name)"
    #	write-warning "testcase len = $($testcases.count)"
    #	write-warning "class indicator len = $($classindicator.matches.count)"
    #	write-warning "group count = $($classindicator.matches.groups.count)"

    if($classindicator.matches.count -eq 0)
    {
      #todo: what do we do with enums?
      # ignore those for the moment, but obviously at this point if we have ANY cs file that doesn't have a class definition in it, we're skipping it here.
      # Not that great.
	    
      write-warning "SKIP: $($file.name)"
      continue
    }

    $testCases.Add(@{
         ModName = $modName
         CsPath = $file.FullName
         CsName = $File.BaseName
         Namespace = $ns.Line
         ClassName = $classIndicator.Matches[0].Groups[2].Value
           })
    }

    Context "namespace" -Fixture {
    It "<CsName> has a JPMF namespace" -TestCases $testCases -Test {
      # Note: There's a few CS files such as interfaces that might not adhere to backend/cmdlet namespaces
      # See how to deal with those; do we force them to adhere or do we permit additional namespaces?
      $CsPath | Should -Filecontentmatch "^\s*namespace\s+JPMF\.$($ModName)\.(Backend|Cmdlet|API|Exceptions?)\b" -Because $Namespace
    }
    It "<CsName> matches class (<ClassName>)" -TestCases $TestCases -Test {
      $className | Should -Be $CsName
    }
    }
}
