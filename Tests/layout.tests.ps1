BeforeAll -Scriptblock {
  [system.io.directoryinfo] $testHome = "$psscriptroot/.."
  [system.io.directoryinfo] $modHome = $testHome.Parent
  [string]$ModName = $modHome.Name
  
    Write-Warning "Mod home = $($modhome.fullname)"
    Write-Warning "Mod name = $($Env:Powershell_Module_Name)"

  try
  {
    Remove-Item "$($modHome.FullName)/Module-Test/$($modName)" -Recurse -Force -ErrorAction Stop
  }
  catch # itemnotfoundexception
  {
    write-warning 'work folder already clean'
  }
  ModuleBuilder\Build-Module -SourcePath $modHome.FullName -OutputDirectory "$($modHome.FullName)/Module-Test" -ErrorAction Stop
  Import-Module -Name "$($modHome.FullName)/Module-Test/$($modName)" -ErrorAction Stop 
}

Describe "Module layout" -Fixture {
  [System.Collections.Generic.List[hashtable]] $TestCases = @()
  [system.io.directoryinfo] $testHome = "$psscriptroot/.."
  [system.io.directoryinfo] $modHome = $testHome.Parent
    [string]$ModName = $Env:Powershell_Module_Name

  # [psmoduleinfo] $manifest = Get-Module "$($modHome.Fullname)/Module-Test/$($modName)" -ErrorAction silentlycontinue -ListAvailable
  [psmoduleinfo] $manifest = Test-ModuleManifest "$($modHome.Fullname)/Module-Test/$($modName)/*/$($modName).psd1" -ErrorAction Stop
  $TestCases.Add(
    @{
      modHome = $modHome
      modName = $modName
      manifest = $manifest
    }
  )

  Context "Module = $modName" -Fixture {
    It "Solution file" -TestCases $TestCases  -Test {
      "$($modHome.Fullname)/JPMF.$($ModName).sln" | Should -Exist
    }
    It "Backend project" -TestCases $TestCases -Test {
      "$($modHome.FullName)/Source/Backend/JPMF.$($ModName).Backend.csproj" | Should -Exist
    }
    It "Frontend project" -TestCases $TestCases -Test {
      "$($modHome.FullName)/Source/Cmdlet/JPMF.$($ModName).Cmdlet.csproj" | Should -Exist
    }
  }

  Context "Module manifest" -Fixture {
    It "exists" -TestCases $TestCases -Test {
      "$($modHome.FullName)/Source/$($ModName).psd1" | Should -Exist
    }
    It "is not supplemented by PSM1" -TestCases $TestCases -Test {
      "$($modHome.FullName)/Source/$($ModName).psm1" | Should -Not -Exist
    }
    <#	It "references its backend"  -TestCases $TestCases -Test {
        $manifest.RequiredAssemblies | Where-Object {$_ -match 'JPMF'} | Should -Match "[\\/]JPMF.$($modName).Backend\.dll$"
    } #>
    <#	It "references its frontend" -TestCases $TestCases -Test {
        # Note: Using get-module, we get a name here rather than a path, so verify accordingly.
        # Using test-modulemanifest, we get a fully qualified path.
        # We'll try to account for both, though this might cause issues too...
        $manifest.NestedModules | Should -Match "([\\/]|^)JPMF\.$($modName)\.Cmdlet(\.dll)?$"
    } #>
  }
  Context "Package $modName" -Fixture {
    It "README" -TestCases $TestCases -Test {
      "$($modHome.FullName)/README.md" | Should -Exist
    }
    It "ICON" -TestCases $TestCases -Test	{
      "$($modHome.FullName)/icon.png"|Should -Exist
    }
    It "LICENSE" -TestCases $TestCases -Test	{
      "$($modHome.FullName)/LICENSE"| Should -Exist
    }
  }
  Context "GitVersion configuration" -Fixture {
    It "Configuration exists" -TestCases $TestCases -Test	{
      "$($modHome.FullName)/GitVersion.yml" | Should -Exist
    }
    It "> 5.x / mode" -TestCases $TestCases -Test	{
      "$($modHome.FullName)/GitVersion.yml" | Should -Not -FileContentMatch "mode:.*mainline"
    }
    It "> 5.x / flow" -TestCases $TestCases -Test	{
      "$($modHome.FullName)/GitVersion.yml" | Should -FileContentMatch "workflow:.*flow/v1"
    }
  }
}
