# run from root directory of module!

write-host "RUNNING TESTS!"
.\tests\run-all-tests.ps1

write-host "BUILDING PACKAGE!"
$outputDir = "$($env:TMP)\ps_build_output"
$date = (Get-Date -Date (Get-Date)).ToUniversalTime()
$moduleVersion = Read-Host "Enter a Module Version Number (x.x.x.x)"
$moduleName = "PSOoGelf"
$ArtifactPath = "$($moduleName)_$($moduleVersion).zip"

.\build\buildScript.ps1 `
    -OutputDir $outputDir `
    -ManifestPath PSOoGelf.psd1 `
    -ModuleFilePath PSOoGelf.psm1 `
    -ModuleVersion $moduleVersion `
    -ArtifactPath $ArtifactPath

#TODO: git tag this commit?