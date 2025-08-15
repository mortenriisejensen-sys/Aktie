﻿Import-Module (Join-Path $PSScriptRoot 'TestActionsHelper.psm1') -Force

# Settings, which affects the behavior of DetermineArtifactUrl
# - artifact - specifies an artifactUrl (or pattern) to use
# - updateDependencies - when using updateDependencies, the resulting artifacts will be the first artifact higher than the applicationDependency
# - country - country to use
# - applicationDependency - specifies the applicationDependency of the app
# - additionalCountries - additional countries to use (artifact must exist for all)

Describe "DetermineArtifactUrl" {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath "../Actions/AL-Go-Helper.ps1" -Resolve)
        DownloadAndImportBcContainerHelper -baseFolder $([System.IO.Path]::GetTempPath())

        Mock -CommandName Get-BcArtifactUrl -MockWith { Param([string] $storageAccount, [string] $type = 'sandbox', [string] $version, [string] $country = '*', [string] $select = 'Latest')

            if ($select -eq 'nextmajor') { $storageAccount = 'bcinsider' }
            if (-not $storageAccount) { $storageAccount = 'bcartifacts' }
            if (-not $version) { $version = '*' }
            Write-Host "Get-BcArtifactUrl -storageAccount '$storageAccount' -type '$type' -version '$version' -country '$country' -select '$select'"

            $allArtifacts = @(
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '20.1.0.0'; "country" = 'at' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '20.1.0.0'; "country" = 'dk' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '20.1.0.0'; "country" = 'us' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '20.1.0.0'; "country" = 'w1' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '21.0.11111.0'; "country" = 'at' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '21.0.11111.0'; "country" = 'dk' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '21.0.11111.0'; "country" = 'us' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'onprem'; "version" = '21.0.11111.0'; "country" = 'w1' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.0.55555.44444'; "country" = 'at' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.0.55555.44444'; "country" = 'dk' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.0.55555.44444'; "country" = 'us' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.0.55555.44444'; "country" = 'w1' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12345'; "country" = 'at' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12345'; "country" = 'dk' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12345'; "country" = 'us' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12345'; "country" = 'w1' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12346'; "country" = 'dk' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12346'; "country" = 'us' }
                @{ "storageAccount" = 'bcartifacts'; "type" = 'sandbox'; "version" = '22.1.12345.12346'; "country" = 'w1' }
                @{ "storageAccount" = 'bcinsider'; "type" = 'sandbox'; "version" = '23.0.33333.0'; "country" = 'at' }
                @{ "storageAccount" = 'bcinsider'; "type" = 'sandbox'; "version" = '23.0.33333.0'; "country" = 'dk' }
                @{ "storageAccount" = 'bcinsider'; "type" = 'sandbox'; "version" = '23.0.33333.0'; "country" = 'us' }
                @{ "storageAccount" = 'bcinsider'; "type" = 'sandbox'; "version" = '23.0.33333.0'; "country" = 'w1' }
            )

            if ($version -ne '*') {
                $dots = ($version.ToCharArray() -eq '.').Count
                if ($dots -lt 3) {
                    # avoid 14.1 returning 14.10, 14.11 etc.
                    $version = "$($version.TrimEnd('.')).*"
                }
            }

            $artifacts = $allArtifacts | Where-Object { $storageAccount -eq $_.StorageAccount -and $type -eq $_.type -and $_.version -like "$version" -and $_.country -like $country }
            if ($select -eq 'latest') {
                $artifacts = $artifacts | Select-Object -Last 1
            }
            $artifacts | ForEach-Object {
                Write-Host "https://$($_.storageAccount)/$($_.type)/$($_.version)/$($_.country)"
                "https://$($_.storageAccount)/$($_.type)/$($_.version)/$($_.country)"
            }
        }
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'projectSettings', Justification = 'False positive.')]
        $projectSettings = @{
            'artifact' = ''
            'updateDependencies' = $false
            'country' = 'us'
            'applicationDependency' = '20.0.0.0'
            'additionalCountries' = @()
        }
    }

    It 'Default Artifact URL' {
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/sandbox/22.1.12345.12346/us'
    }

    It 'Default Artifact URL with additionalCountries' {
        $projectSettings.additionalCountries = @('dk')
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/sandbox/22.1.12345.12345/us'
    }

    It 'Default Artifact URL when using UpdateDependencies' {
        $projectSettings.UpdateDependencies = $true
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/sandbox/22.0.55555.44444/us'
    }

    It 'Fixed Artifact URL' {
        $projectSettings.artifact = 'https://bcartifacts/onprem/21.0.54157.55112/w1'
        $projectSettings.country = 'w1'
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/onprem/21.0.54157.55112/w1'
    }

    It 'Artifact setting' {
        $projectSettings.artifact = 'bcartifacts/onprem/20.1/us'
        $projectSettings.country = 'us'
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/onprem/20.1.0.0/us'
    }

    It 'NextMajor' {
        $projectSettings.country = 'dk'
        $projectSettings.artifact = "////nextmajor"
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcinsider/sandbox/23.0.33333.0/dk'
    }

    It 'Artifact setting wins over country setting' {
        $projectSettings.country = 'dk'
        $projectSettings.artifact = "///us/latest"
        DetermineArtifactUrl -projectSettings $projectSettings -doNotIssueWarnings | should -be 'https://bcartifacts/sandbox/22.1.12345.12345/us'
    }

    It 'Artifact setting when using version = * and first' {
        $projectSettings.applicationDependency = '22.1.0.0'
        $projectSettings.artifact = "//*/us/first"
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/sandbox/22.1.12345.12345/us'
    }

    It 'Artifact setting when using version = * and latest' {
        $projectSettings.applicationDependency = '22.1.0.0'
        $projectSettings.artifact = "//*/us/latest"
        DetermineArtifactUrl -projectSettings $projectSettings | should -be 'https://bcartifacts/sandbox/22.1.12345.12346/us'
    }
}


Describe "DetermineArtifactUrl Action Test" {
    BeforeAll {
        $actionName = "DetermineArtifactUrl"
        $scriptRoot = Join-Path $PSScriptRoot "..\Actions\$actionName" -Resolve
        $scriptName = "$actionName.ps1"
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'actionScript', Justification = 'False positive.')]
        $actionScript = GetActionScript -scriptRoot $scriptRoot -scriptName $scriptName
    }

    It 'Compile Action' {
        Invoke-Expression $actionScript
    }

    It 'Test action.yaml matches script' {
        $outputs = [ordered]@{
        }
        YamlTest -scriptRoot $scriptRoot -actionName $actionName -actionScript $actionScript -outputs $outputs
    }
}
