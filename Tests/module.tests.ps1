BeforeAll -Scriptblock {  
}

Describe -Name 'Module metainfo' -Fixture {  
  Context -Name 'file name matches function' -Fixture {

    [System.Collections.Generic.List[hashtable]] $Testcases = @()
    [System.IO.DirectoryInfo] $modroot = get-item -Path "$PSScriptRoot/../../Source"
    [System.IO.FileInfo[]] $SourceFiles = Get-ChildItem -LiteralPath @(
      ('{0}\Private' -f $modroot.FullName),
      ('{0}\Public'  -f $modroot.FullName)
    )  -Recurse   -File -Filter '*.ps1'
    #write-warning ( 'Found functions: {0}' -f  $SourceFiles.Count )  

    foreach($entry in $SourceFiles)
    {      
      $srcfile = $null
      [Microsoft.PowerShell.Commands.MatchInfo] $MatchResult = (select-string -Pattern '^\s*Function\s+([^\s]+)\b.*$' -LiteralPath $entry.Fullname )
      [string]$ExpectedResult = ''
      
      if($MatchResult.Matches.Count -gt 0)
      { 
        [string] $ExpectedResult = $MatchResult.Matches[0].Groups[1].Value.Trim()
      
      

        [hashtable] $newCase = @{
          srcFile = $entry.baseName
          ExpectedResult = $ExpectedResult
        }
        $Testcases.Add($newCase)
      }
      else
      {
      write-warning ('NO FUNCTION DEFINITION FOUND in [{0}]' -f $entry.fullname)
      }
    }    
    It -Name '<expectedResult>' -TestCases $TestCases.ToArray() -Test {                       
      $srcFile | Should -Be $ExpectedResult      
    }
  }
}