﻿[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global vars used for local test execution only.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'All scenario tests have equal parameter set.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Secrets are transferred as plain text.')]
Param(
    [switch] $github,
    [switch] $linux,
    [string] $githubOwner = $global:E2EgithubOwner,
    [string] $repoName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetTempFileName()),
    [string] $e2eAppId,
    [string] $e2eAppKey,
    [string] $algoauthapp = ($global:SecureALGOAUTHAPP | Get-PlainText),
    [string] $pteTemplate = $global:pteTemplate,
    [string] $appSourceTemplate = $global:appSourceTemplate,
    [string] $adminCenterApiCredentials = ($global:SecureadminCenterApiCredentials | Get-PlainText),
    [string] $azureCredentials = ($global:SecureAzureCredentials | Get-PlainText),
    [string] $githubPackagesToken = ($global:SecureGitHubPackagesToken | Get-PlainText)
)

Write-Host -ForegroundColor Yellow @'
#  _    _          _____           _           _   _____                            _                 _
# | |  | |        |  __ \         (_)         | | |  __ \                          | |               (_)
# | |  | |___  ___| |__) | __ ___  _  ___  ___| |_| |  | | ___ _ __   ___ _ __   __| | ___ _ __   ___ _  ___  ___
# | |  | / __|/ _ \  ___/ '__/ _ \| |/ _ \/ __| __| |  | |/ _ \ '_ \ / _ \ '_ \ / _` |/ _ \ '_ \ / __| |/ _ \/ __|
# | |__| \__ \  __/ |   | | | (_) | |  __/ (__| |_| |__| |  __/ |_) |  __/ | | | (_| |  __/ | | | (__| |  __/\__ \
#  \____/|___/\___|_|   |_|  \___/| |\___|\___|\__|_____/ \___| .__/ \___|_| |_|\__,_|\___|_| |_|\___|_|\___||___/
#                                _/ |                         | |
#                               |__/                          |_|
#
# This test tests the following scenario:
#
#  - Create a new repository based on the PTE template with 5 projects and useProjectDependencies set to true
#    - P1/app1 with dependency to P1/app2
#    - P1/app2 with no dependencies
#    - P2/app3 with dependency to P1/app1 and P1/app2
#    - P3/app4 with dependency to P1/app1
#    - P4/app5 with dependency to P3/app4 and P2/app3
#    - P0/app6 with dependency to P3/app4 and P2/app3
#  - Run Update AL-Go System Files to apply useProjectDependencies
#  - Run the "CI/CD" workflow
#  - Run the Test Current Workflow
#  - Run the Test Next Minor Workflow
#  - Run the Test Next Major Workflow
#  - Test that runs were successful and artifacts were created
#  - Cleanup repositories
#
'@

$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0
$prevLocation = Get-Location
$repoPath = ""

Remove-Module e2eTestHelper -ErrorAction SilentlyContinue
Import-Module (Join-Path $PSScriptRoot "..\..\e2eTestHelper.psm1") -DisableNameChecking

$repository = "$githubOwner/$repoName"
$branch = "main"

$template = "https://github.com/$pteTemplate"

# Login
SetTokenAndRepository -github:$github -githubOwner $githubOwner -appId $e2eAppId -appKey $e2eAppKey -repository $repository

# Create repo
CreateAlGoRepository `
    -github:$github `
    -linux:$linux `
    -template $template `
    -repository $repository `
    -branch $branch `
    -projects @('P1','P2','P3','P4','P0') `
    -addRepoSettings @{ "useProjectDependencies" = $true } `
    -contentScript {
        Param([string] $path)
        $id2 = CreateNewAppInFolder -folder (Join-Path $path 'P1') -name app2 -objID 50002
        $id1 = CreateNewAppInFolder -folder (Join-Path $path 'P1') -name app1 -objID 50001 -dependencies @( @{ "id" = $id2; "name" = "app2"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path 'P1\.AL-Go\settings.json') -properties @{ "country" = "w1" }
        $id3 = CreateNewAppInFolder -folder (Join-Path $path 'P2') -name app3 -objID 50003 -dependencies @( @{ "id" = $id1; "name" = "app1"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" }, @{ "id" = $id2; "name" = "app2"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path 'P2\.AL-Go\settings.json') -properties @{ "country" = "w1" }
        $id4 = CreateNewAppInFolder -folder (Join-Path $path 'P3') -name app4 -objID 50004 -dependencies @( @{ "id" = $id1; "name" = "app1"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path 'P3\.AL-Go\settings.json') -properties @{ "country" = "w1" }
        $null = CreateNewAppInFolder -folder (Join-Path $path 'P4') -name app5 -objID 50005 -dependencies @( @{ "id" = $id4; "name" = "app4"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" }; @{ "id" = $id3; "name" = "app3"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path 'P4\.AL-Go\settings.json') -properties @{ "country" = "it" }
        $null = CreateNewAppInFolder -folder (Join-Path $path 'P0') -name app6 -objID 50006 -dependencies @( @{ "id" = $id4; "name" = "app4"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" }; @{ "id" = $id3; "name" = "app3"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path 'P0\.AL-Go\settings.json') -properties @{ "country" = "dk" }
    }

$repoPath = (Get-Location).Path

# Update AL-Go System Files to uptake UseProjectDependencies setting
RunUpdateAlGoSystemFiles -directCommit -wait -templateUrl $template -ghTokenWorkflow $algoauthapp -repository $repository -branch $branch | Out-Null

# Run CI/CD workflow
$run = RunCICD -branch $branch

# Launch Current, NextMinor and NextMajor builds
$runTestCurrent = RunTestCurrent -branch $branch
$runTestNextMinor = RunTestNextMinor -branch $branch
$runTestNextMajor = RunTestNextMajor -branch $branch

# Wait for all workflows to finish
WaitWorkflow -runid $run.id
Test-ArtifactsFromRun -runid $run.id -folder 'artifacts' -expectedArtifacts @{"Apps"=6;"thisbuild"=0} -repoVersion '1.0' -appVersion '1.0'

WaitWorkflow -runid $runTestCurrent.id -noDelay
Test-ArtifactsFromRun -runid $runTestCurrent.id -folder 'currentartifacts' -expectedArtifacts @{"Apps"=0;"thisbuild"=6} -repoVersion '1.0' -appVersion '1.0'

WaitWorkflow -runid $runTestNextMinor.id -noDelay
Test-ArtifactsFromRun -runid $runTestNextMinor.id -folder 'nextminorartifacts' -expectedArtifacts @{"Apps"=0;"thisbuild"=6} -repoVersion '1.0' -appVersion '1.0'

WaitWorkflow -runid $runTestNextMajor.id -noDelay
Test-ArtifactsFromRun -runid $runTestNextMajor.id -folder 'nextmajorartifacts' -expectedArtifacts @{"Apps"=0;"thisbuild"=6} -repoVersion '1.0' -appVersion '1.0'

Set-Location $prevLocation

RemoveRepository -repository $repository -path $repoPath
