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
#   _____ _ _   _    _       _     _____           _
#  / ____(_) | | |  | |     | |   |  __ \         | |
# | |  __ _| |_| |__| |_   _| |__ | |__) |_ _  ___| | ____ _  __ _  ___  ___
# | | |_ | | __|  __  | | | | '_ \|  ___/ _` |/ __| |/ / _` |/ _` |/ _ \/ __|
# | |__| | | |_| |  | | |_| | |_) | |  | (_| | (__|   < (_| | (_| |  __/\__ \
#  \_____|_|\__|_|  |_|\__,_|_.__/|_|   \__,_|\___|_|\_\__,_|\__, |\___||___/
#                                                             __/ |
#                                                            |___/
# This test tests the following scenario:
#
#  - Create a new repository (repository1) based on the PTE template with 3 apps
#    - app1 with dependency to app2
#    - app2 with no dependencies
#    - app3 with dependency to app1 and app2
#  - Set GitHubPackagesContext secret in repository1
#  - Run the "CI/CD" workflow in repository1
#  - Create a new repository (repository2) based on the PTE template with 1 app (using CompilerFolder)
#    - app4 with dependency to app1
#  - Set GitHubPackagesContext secret in repository2
#  - Create a new repository (repository) based on the PTE template with 1 app
#    - app5 with dependencies to app4 and app3
#  - Set GitHubPackagesContext secret in repository
#  - Wait for "CI/CD" workflow from repository1 to complete
#  - Check artifacts generated in repository1
#  - Run the "CI/CD" workflow from repository2 and wait for completion
#  - Check artifacts generated in repository2
#  - Run the "CI/CD" workflow from repository and wait for completion
#  - Check artifacts generated in repository
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

$repository1 = "$repository.1"
$repository2 = "$repository.2"
# TODO: PAT is still needed here as GitHub packages only supports authentication using classic PATs
# https://docs.github.com/en/packages/learn-github-packages/about-permissions-for-github-packages#about-scopes-and-permissions-for-package-registries
$githubPackagesContext = @{
    "serverUrl"="https://nuget.pkg.github.com/$($githubOwner.ToLowerInvariant())/index.json"
    "token"=$githubPackagesToken
}
$githubPackagesContextJson = ($githubPackagesContext | ConvertTo-Json -Compress)

# Create repository1
CreateAlGoRepository `
    -github:$github `
    -linux:$linux `
    -template $template `
    -repository $repository1 `
    -branch $branch `
    -contentScript {
        Param([string] $path)
        $script:id2 = CreateNewAppInFolder -folder $path -name app2 -objID 50002
        $script:id1 = CreateNewAppInFolder -folder $path -name app1 -objID 50001 -dependencies @( @{ "id" = $script:id2; "name" = "app2"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        $script:id3 = CreateNewAppInFolder -folder $path -name app3 -objID 50003 -dependencies @( @{ "id" = $script:id1; "name" = "app1"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" }, @{ "id" = $script:id2; "name" = "app2"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path '.AL-Go\settings.json') -properties @{ "country" = "w1" }
    }
SetRepositorySecret -repository $repository1 -name 'GitHubPackagesContext' -value $githubPackagesContextJson
$repoPath1 = (Get-Location).Path
$run1 = RunCICD -repository $repository1 -branch $branch

CreateAlGoRepository `
    -github:$github `
    -linux:$linux `
    -template $template `
    -repository $repository2 `
    -branch $branch `
    -addRepoSettings @{ "useCompilerFolder" = $true; "doNotPublishApps" = $true } `
    -contentScript {
        Param([string] $path)
        $script:id4 = CreateNewAppInFolder -folder $path -name app4 -objID 50004 -dependencies @( @{ "id" = $script:id1; "name" = "app1"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path '.AL-Go\settings.json') -properties @{ "country" = "dk" }
    }
SetRepositorySecret -repository $repository2 -name 'GitHubPackagesContext' -value $githubPackagesContextJson
$repoPath2 = (Get-Location).Path

CreateAlGoRepository `
    -github:$github `
    -linux:$linux `
    -template $template `
    -repository $repository `
    -branch $branch `
    -addRepoSettings @{ "generateDependencyArtifact" = $true } `
    -contentScript {
        Param([string] $path)
        $script:id5 = CreateNewAppInFolder -folder $path -name app5 -objID 50005 -dependencies @( @{ "id" = $script:id4; "name" = "app4"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" }; @{ "id" = $script:id3; "name" = "app3"; "publisher" = (GetDefaultPublisher); "version" = "1.0.0.0" } )
        Add-PropertiesToJsonFile -path (Join-Path $path '.AL-Go\settings.json') -properties @{ "country" = "dk"; "nuGetFeedSelectMode" = "EarliestMatching" }
    }
SetRepositorySecret -repository $repository -name 'GitHubPackagesContext' -value $githubPackagesContextJson
$repoPath = (Get-Location).Path

# Wait for CI/CD workflow of repository1 to finish
Set-Location $repoPath1
WaitWorkflow -repository $repository1 -runid $run1.id

# Run a second time with wait (to have at least two versions in the feed 1.0.2 and 1.0.3 - RUN_NUMBER 1 was initial commit)
$run1 = RunCICD -repository $repository1 -branch $branch -wait

# test artifacts generated in repository1
Test-ArtifactsFromRun -runid $run1.id -folder 'artifacts' -expectedArtifacts @{"Apps"=3;"TestApps"=0;"Dependencies"=0} -repoVersion '1.0' -appVersion '1.0'

# Wait for CI/CD workflow of repository2 to finish
Set-Location $repoPath2
$run2 = RunCICD -repository $repository2 -branch $branch -wait

# Run a second time with wait (due to GitHubPackages error with our organization?)
$run2 = RunCICD -repository $repository2 -branch $branch -wait

# test artifacts generated in repository2
Test-ArtifactsFromRun -runid $run2.id -folder 'artifacts' -expectedArtifacts @{"Apps"=1;"TestApps"=0;"Dependencies"=0} -repoVersion '1.0' -appVersion '1.0'

# Wait for CI/CD workflow of main repo to finish
Set-Location $repoPath
$run = RunCICD -repository $repository -branch $branch -wait

# test artifacts generated in main repo
Test-ArtifactsFromRun -runid $run.id -folder 'artifacts' -expectedArtifacts @{"Apps"=1;"TestApps"=0;"Dependencies"=4} -repoVersion '1.0' -appVersion '1.0'

# Check that the dependencies are version 1.0.2.0 due to the nuGetFeedSelectMode = EarliestMatching
(Get-ChildItem -Path 'artifacts/*-main-Dependencies-*/*_1.0.2.0.app').Count | Should -Be 4 -Because "There should be 4 dependencies with version 1.0.2.0 due to the nuGetFeedSelectMode = EarliestMatching"

Set-Location $prevLocation

RemoveRepository -repository $repository -path $repoPath
RemoveRepository -repository $repository2 -path $repoPath2
RemoveRepository -repository $repository1 -path $repoPath1
