﻿Describe "ResolveProjectFolders" {
    BeforeAll {
        . (Join-Path $PSScriptRoot '../Actions/AL-Go-Helper.ps1')

        Mock Write-Host { }
        Mock Out-Host { }

        $baseFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item $baseFolder -ItemType Directory | Out-Null

        Push-Location -Path $baseFolder

        # Create the following folder structure in $baseFolder
        <#
        ├───.github
        └───AL-GoProject
            ├───.AL-Go
            │       settings.json
            │
            ├───app1
            │       app.json
            │
            ├───nestedApp
            │   ├───app2
            │           app.json
            │
            ├───bcptApp1
            │       app.json
            │
            ├───bcptApp2
            │       app.json
            │
            ├───testApp1
            │       app.json
            │
            └───testApp2
                    app.json
        #>
        $ALGoProject =  'AL-GoProject'
        $ALGoProjectFolder = Join-Path $baseFolder $ALGoProject
        $ALGoSettingsFile = Join-Path $ALGoProjectFolder '.AL-Go/settings.json'

        # Create the AL-Go project folder
        New-Item $ALGoProjectFolder -ItemType Directory | Out-Null

        # Create AL-Go settings file
        $ALGoSettings = @{
            "appFolders" = @(
                "app1",
                "nestedApp\app2"
            );
            "testFolders" = @(
                "testApp1",
                "testApp2"
            );
            "bcptTestFolders" = @(
                "bcptApp1",
                "bcptApp2"
            )
        }

        $alGoSettingsContent = $ALGoSettings | ConvertTo-Json -Depth 99
        New-Item -Path $ALGoSettingsFile -Value $alGoSettingsContent -Force

        # Create the app folders
        $appFolders = @(
            "app1",
            "nestedApp\app2",
            "bcptApp1",
            "bcptApp2",
            "testApp1",
            "testApp2"
        )
        $apps = @{}

        $appFolders | ForEach-Object {
            $appFolder = Join-Path $ALGoProjectFolder $_
            New-Item $appFolder -ItemType Directory | Out-Null
            $appJson = Join-Path $appFolder 'app.json'

            # Create the app.json file with random ID and no dependencies
            $app = [ordered]@{
                "id" = [Guid]::NewGuid().ToString()
                "name" = $_
                "dependencies" = @()
            }
            $appJsonContent = $app | ConvertTo-Json -Depth 99
            New-Item -Path $appJson -Value $appJsonContent -Force

            $apps.Add($_, $app)
        }

        function AddDependency($app, $dependencyAppId, $dependencyAppName) {
            $appFolder = Join-Path $ALGoProjectFolder $app
            $appJsonFile = Join-Path $appFolder 'app.json'
            $appJson = Get-Content $appJsonFile | ConvertFrom-Json
            $appJson.dependencies += @(
                @{
                    "id" = $dependencyAppId
                    "name" = $dependencyAppName
                }
            )
            $appJson | ConvertTo-Json -Depth 99 | Out-File $appJsonFile -Force
        }

        AddDependency -app 'testApp1' -dependencyAppId $apps['app1'].id -dependencyAppName $apps['app1'].name
        AddDependency -app 'testApp1' -dependencyAppId $anyAppId -dependencyAppName 'Any'

        AddDependency -app 'testApp2' -dependencyAppId $apps['app1'].id -dependencyAppName $apps['app1'].name
        AddDependency -app 'testApp2' -dependencyAppId $apps['nestedApp\app2'].id -dependencyAppName $apps['nestedApp\app2'].name
        AddDependency -app 'testApp2' -dependencyAppId $anyAppId -dependencyAppName 'Any'

        AddDependency -app 'bcptApp1' -dependencyAppId $apps['app1'].id -dependencyAppName $apps['app1'].name
        AddDependency -app 'bcptApp1' -dependencyAppId $performanceToolkitAppId -dependencyAppName 'Performance ToolKit'

        AddDependency -app 'bcptApp2' -dependencyAppId $apps['app1'].id -dependencyAppName $apps['app1'].name
        AddDependency -app 'bcptApp2' -dependencyAppId $apps['nestedApp\app2'].id -dependencyAppName $apps['nestedApp\app2'].name
        AddDependency -app 'bcptApp2' -dependencyAppId $performanceToolkitAppId -dependencyAppName 'Performance ToolKit'
    }

    It 'When no app folders specified, scans all folders and finds all apps' {
        $projectSettings = @{ 'appFolders' = @(); 'testFolders' = @(); 'bcptTestFolders' = @()}
        ResolveProjectFolders -baseFolder $baseFolder -project $ALGoProject -projectSettings ([ref] $projectSettings)

        $projectSettings.appFolders | Should -HaveCount 2
        $projectSettings.appFolders | Should -Contain $(Join-Path '.' 'app1')
        $projectSettings.appFolders | Should -Contain $(Join-Path '.' 'nestedApp\app2')

        $projectSettings.testFolders | Should -HaveCount 2
        $projectSettings.testFolders | Should -Contain $(Join-Path '.' 'testApp1')
        $projectSettings.testFolders | Should -Contain $(Join-Path '.' 'testApp2')

        $projectSettings.bcptTestFolders | Should -HaveCount 2
        $projectSettings.bcptTestFolders | Should -Contain $(Join-Path '.' 'bcptApp1')
        $projectSettings.bcptTestFolders | Should -Contain $(Join-Path '.' 'bcptApp2')
    }

    It 'When only appFolders specified, scan only app folders and resolves them' {
        $projectSettings = @{ 'appFolders' = @('app1'); 'testFolders' = @(); 'bcptTestFolders' = @()}

        ResolveProjectFolders -baseFolder $baseFolder -project $ALGoProject -projectSettings ([ref] $projectSettings)

        $projectSettings.appFolders | Should -HaveCount 1
        $projectSettings.appFolders | Should -Contain $(Join-Path '.' 'app1')

        $projectSettings.testFolders | Should -HaveCount 0

        $projectSettings.bcptTestFolders | Should -HaveCount 0
    }

    It 'When appFolders contains non-existing apps, they are not resolved' {
        $projectSettings = @{ 'appFolders' = @('nonExistingApp', 'app1'); 'testFolders' = @('nonExistingTestApp'); 'bcptTestFolders' = @('nonExistingBCPTApp')}

        ResolveProjectFolders -baseFolder $baseFolder -project $ALGoProject -projectSettings ([ref] $projectSettings)

        $projectSettings.appFolders | Should -HaveCount 1
        $projectSettings.appFolders | Should -Contain $(Join-Path '.' 'app1')

        $projectSettings.testFolders | Should -HaveCount 0

        $projectSettings.bcptTestFolders | Should -HaveCount 0
    }

    It 'When only non-existing apps are specified, no app folders are resolved' {
        $projectSettings = @{ 'appFolders' = @('nonExistingApp'); 'testFolders' = @('nonExistingTestApp'); 'bcptTestFolders' = @()}

        ResolveProjectFolders -baseFolder $baseFolder -project $ALGoProject -projectSettings ([ref] $projectSettings)

        $projectSettings.appFolders | Should -HaveCount 0

        $projectSettings.testFolders | Should -HaveCount 0

        $projectSettings.bcptTestFolders | Should -HaveCount 0
    }

    It 'When app folders are specified, only the specified app folders are resolved' {
        $projectSettings = @{ 'appFolders' = @('nestedApp\app2'); 'testFolders' = @('testApp1'); 'bcptTestFolders' = @('bcptApp2')}
        ResolveProjectFolders -baseFolder $baseFolder -project $ALGoProject -projectSettings ([ref] $projectSettings)

        $projectSettings.appFolders | Should -HaveCount 1
        $projectSettings.appFolders | Should -Contain $(Join-Path '.' 'nestedApp\app2')

        $projectSettings.testFolders | Should -HaveCount 1
        $projectSettings.testFolders | Should -Contain $(Join-Path '.' 'testApp1')

        $projectSettings.bcptTestFolders | Should -HaveCount 1
        $projectSettings.bcptTestFolders | Should -Contain $(Join-Path '.' 'bcptApp2')
    }

    AfterAll {
        Pop-Location
        Remove-Item -Path $baseFolder -Recurse -Force
    }
}
