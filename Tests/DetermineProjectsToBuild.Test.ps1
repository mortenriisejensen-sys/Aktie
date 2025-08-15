﻿Import-Module (Join-Path $PSScriptRoot 'TestActionsHelper.psm1') -Force

Describe "Get-ProjectsToBuild" {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath "../Actions/AL-Go-Helper.ps1" -Resolve)
        DownloadAndImportBcContainerHelper -baseFolder $([System.IO.Path]::GetTempPath())

        Import-Module (Join-Path $PSScriptRoot "../Actions/DetermineProjectsToBuild/DetermineProjectsToBuild.psm1" -Resolve) -DisableNameChecking
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'baseFolder', Justification = 'False positive.')]
        $baseFolder = (New-Item -ItemType Directory -Path (Join-Path $([System.IO.Path]::GetTempPath()) $([System.IO.Path]::GetRandomFileName()))).FullName
    }

    It 'loads a single project in the root folder' {
        New-Item -Path "$baseFolder/.AL-Go/settings.json" -type File -Force

        # Add AL-Go settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $false }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @(".")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @(".")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['.'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "."
        #    ],
        #    "projectsCount":  1,
        #    "buildDimensions":  [
        #       {
    #             "buildMode": "Default",
        #         "project": "."
        #       }
        #    ]
        #  }
        #]
        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @(".")
        $buildOrder[0].projectsCount | Should -BeExactly 1
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "."
    }

    It 'loads two independent projects with no build modes set' {
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        # Add AL-Go settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $false }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Default",
        #         "project": "Project2"
        #    ]
        #  }
        #]
        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads two independent projects with build modes set' {
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -Value $(@{ buildModes = @("Default", "Clean") } | ConvertTo-Json ) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -Value $(@{ buildModes = @("Translated") } | ConvertTo-Json ) -type File -Force

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Clean",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Translated",
        #         "project": "Project2"
        #       },
        #    ]
        #  }
        #]
        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 3
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Clean"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[2].buildMode | Should -BeExactly "Translated"
        $buildOrder[0].buildDimensions[2].project | Should -BeExactly "Project2"
    }

    It 'loads correct projects, based on the modified files: single modified file in Project1' {
        # Setup project structure
        $appJson = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'My app'; publisher = 'Contoso'; version = '1.0.0.0' }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $appJson) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        $modifiedFiles = @('Project1/.AL-Go/settings.json')
        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder -modifiedFiles $modifiedFiles -buildAllProjects $false

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @("Project1")
        $projectsToBuild | Should -BeExactly @("Project1")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #    ],
        #    "projectsCount":  1,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       }
        #    ]
        #  }
        #]
        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1")
        $buildOrder[0].projectsCount | Should -BeExactly 1
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
    }

    It 'loads correct projects, based on the modified files: multiple modified files in Project1 and Project2' {
        # Setup project structure
        $appJson = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'My app'; publisher = 'Contoso'; version = '1.0.0.0' }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $appJson) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        $modifiedFiles = @('Project1/.AL-Go/settings.json', 'Project2/.AL-Go/settings.json')
        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder -modifiedFiles $modifiedFiles -buildAllProjects $false

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @("Project1", "Project2")
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Default",
        #         "project": "Project2"
        #       }
        #    ]
        #  }
        #]
        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads correct projects, based on the modified files: multiple modified files only in Project1' {
        # Setup project structure
        $appJson = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'My app'; publisher = 'Contoso'; version = '1.0.0.0' }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $appJson) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        $modifiedFiles = @('Project1/.AL-Go/settings.json', 'Project1/app/app.json')
        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder -modifiedFiles $modifiedFiles -buildAllProjects $false

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @("Project1")
        $projectsToBuild | Should -BeExactly @("Project1")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #    ],
        #    "projectsCount":  1,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       }
        #    ]
        #  }
        #]

        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1")
        $buildOrder[0].projectsCount | Should -BeExactly 1
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
    }

    It 'loads correct projects, based on the modified files: no modified files' {
        # Setup project structure
        $appJson = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'My app'; publisher = 'Contoso'; version = '1.0.0.0' }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $appJson) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        $modifiedFiles = @()
        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder -modifiedFiles $modifiedFiles -buildAllProjects $true

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Default",
        #         "project": "Project2"
        #       }
        #    ]
        #  }
        #]
        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads correct projects, based on the modified files: Project1 is modified, fullBuildPatterns is set to .github' {
        # Setup project structure
        $appJson = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'My app'; publisher = 'Contoso'; version = '1.0.0.0' }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $appJson) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        # Add AL-Go settings file
        $alGoSettings = @{ projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $false; fullBuildPatterns = @('.github') }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $modifiedFiles = @('Project1/.AL-Go/settings.json')
        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder -modifiedFiles $modifiedFiles -buildAllProjects $false

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @("Project1")
        $projectsToBuild | Should -BeExactly @("Project1")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1")
        $buildOrder[0].projectsCount | Should -BeExactly 1
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
    }

    It 'loads correct projects, based on the modified files: Project1 is modified, fullBuildPatterns is set to Project1/*' {
        # Setup project structure
        $appJson = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'My app'; publisher = 'Contoso'; version = '1.0.0.0' }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $appJson) -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        # Add AL-Go settings file
        $alGoSettings = @{ projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $false; fullBuildPatterns = @('Project1/*') }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $modifiedFiles = @('Project1/.AL-Go/settings.json')
        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder -modifiedFiles $modifiedFiles

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @("Project1")
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads independent projects correctly, if useProjectDependencies is set to false' {
        # Two independent projects, no dependencies
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        #Add settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $false }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       }
        #    ]
        #  }
        #]

        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads independent projects correctly, if useProjectDependencies is set to true' {
        # Two independent projects, no dependencies
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force

        #Add settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $true }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       }
        #    ]
        #  }
        #]

        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads dependent projects correctly, if useProjectDependencies is set to false' {
        # Two dependent projects
        $dependecyAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @() }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $dependecyAppFile -Depth 10) -type File -Force

        $dependantAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd2'; name = 'Second App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @(@{id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'} ) }
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/app/app.json" -Value (ConvertTo-Json $dependantAppFile -Depth 10) -type File -Force

        #Add settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $false }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1",
        #      "Project2"
        #    ],
        #    "projectsCount":  2,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       },
        #       {
        #         "buildMode": "Default",
        #         "project": "Project2"
        #       }
        #    ]
        #  }
        #]

        $buildOrder.Count | Should -BeExactly 1
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project2")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project2"
    }

    It 'loads dependent projects correctly, if useProjectDependencies is set to true' {
        # Two dependent projects
        $dependecyAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @() }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $dependecyAppFile -Depth 10) -type File -Force

        $dependantAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd2'; name = 'Second App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @(@{id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'} ) }
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/app/app.json" -Value (ConvertTo-Json $dependantAppFile -Depth 10) -type File -Force

        #Add settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $true }
        New-Item -Path "$baseFolder/.github" -type Directory -Force
        $alGoSettings | ConvertTo-Json -Depth 99 -Compress | Out-File (Join-Path $baseFolder ".github/AL-Go-Settings.json") -Encoding UTF8

        # Add settings as environment variable to simulate we've run ReadSettings
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @("Project1", "Project2")

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @("Project1")

        # Build order should have the following structure:
        #[
        #  {
        #    "projects":  [
        #      "Project1"
        #    ],
        #    "projectsCount":  1,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project1"
        #       }
        #    ]
        #  },
        #  {
        #    "projects":  [
        #      "Project2"
        #    ],
        #    "projectsCount":  1,
        #    "buildDimensions":  [
        #       {
        #         "buildMode": "Default",
        #         "project": "Project2"
        #       }
        #    ]
        #  }
        #]

        $buildOrder.Count | Should -BeExactly 2
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1")
        $buildOrder[0].projectsCount | Should -BeExactly 1
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"

        $buildOrder[1] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[1].projects | Should -BeExactly @("Project2")
        $buildOrder[1].projectsCount | Should -BeExactly 1
        $buildOrder[1].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[1].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[1].buildDimensions[0].project | Should -BeExactly "Project2"
    }

    It 'loads dependent projects correctly, if useProjectDependencies is set to false in a project setting' {
        # Add three dependent projects
        # Project 1
        # Project 2 depends on Project 1 - useProjectDependencies is set to true from the repo settings
        # Project 3 depends on Project 1, but has useProjectDependencies set to false in the project settings
        $dependecyAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @() }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $dependecyAppFile -Depth 10) -type File -Force

        $dependantAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd2'; name = 'Second App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @(@{id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'} ) }
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/app/app.json" -Value (ConvertTo-Json $dependantAppFile -Depth 10) -type File -Force

        # Third project that also depends on the first project, but has useProjectDependencies set to false
        $dependantAppFile3 = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd3'; name = 'Third App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @(@{id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'} ) }
        New-Item -Path "$baseFolder/Project3/.AL-Go/settings.json" -type File -Force
        @{ useProjectDependencies = $false } | ConvertTo-Json -Depth 99 -Compress | Out-File (Join-Path $baseFolder "Project3/.AL-Go/settings.json") -Encoding UTF8
        New-Item -Path "$baseFolder/Project3/app/app.json" -Value (ConvertTo-Json $dependantAppFile3 -Depth 10) -type File -Force

        #Add settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $true }
        New-Item -Path "$baseFolder/.github" -type Directory -Force
        $alGoSettings | ConvertTo-Json -Depth 99 -Compress | Out-File (Join-Path $baseFolder ".github/AL-Go-Settings.json") -Encoding UTF8

        # Add settings as environment variable to simulate we've run ReadSettings
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $allProjects, $modifiedProjects, $projectsToBuild, $projectDependencies, $buildOrder = Get-ProjectsToBuild -baseFolder $baseFolder

        $allProjects | Should -BeExactly @("Project1", "Project2", "Project3")
        $modifiedProjects | Should -BeExactly @()
        $projectsToBuild | Should -BeExactly @('Project1', 'Project2', 'Project3')

        $projectDependencies | Should -BeOfType System.Collections.Hashtable
        $projectDependencies['Project1'] | Should -BeExactly @()
        $projectDependencies['Project2'] | Should -BeExactly @("Project1")
        $projectDependencies['Project3'] | Should -BeExactly @()

        # Build order should have the following structure:
        #[
        #{
        #    "buildDimensions": [
        #    {
        #        "projectName": "Project1",
        #        "buildMode": "Default",
        #        "project": "Project1",
        #        "githubRunnerShell": "powershell",
        #        "gitHubRunner": "\"windows-latest\""
        #    },
        #    {
        #        "projectName": "Project3",
        #        "buildMode": "Default",
        #        "project": "Project3",
        #        "githubRunnerShell": "powershell",
        #        "gitHubRunner": "\"windows-latest\""
        #    }
        #    ],
        #    "projectsCount": 2,
        #    "projects": [
        #    "Project1",
        #    "Project3"
        #    ]
        #},
        #{
        #    "buildDimensions": [
        #    {
        #        "projectName": "Project2",
        #        "buildMode": "Default",
        #        "project": "Project2",
        #        "githubRunnerShell": "powershell",
        #        "gitHubRunner": "\"windows-latest\""
        #    }
        #    ],
        #    "projectsCount": 1,
        #    "projects": [
        #    "Project2"
        #    ]
        #}
        #]
        $buildOrder.Count | Should -BeExactly 2
        $buildOrder[0] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[0].projects | Should -BeExactly @("Project1", "Project3")
        $buildOrder[0].projectsCount | Should -BeExactly 2
        $buildOrder[0].buildDimensions.Count | Should -BeExactly 2
        $buildOrder[0].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[0].project | Should -BeExactly "Project1"
        $buildOrder[0].buildDimensions[1].buildMode | Should -BeExactly "Default"
        $buildOrder[0].buildDimensions[1].project | Should -BeExactly "Project3"

        $buildOrder[1] | Should -BeOfType System.Collections.Hashtable
        $buildOrder[1].projects | Should -BeExactly @("Project2")
        $buildOrder[1].projectsCount | Should -BeExactly 1
        $buildOrder[1].buildDimensions.Count | Should -BeExactly 1
        $buildOrder[1].buildDimensions[0].buildMode | Should -BeExactly "Default"
        $buildOrder[1].buildDimensions[0].project | Should -BeExactly "Project2"
    }

    It 'throws if the calculated build depth is more than the maximum supported' {
        # Two dependent projects
        $dependecyAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @() }
        New-Item -Path "$baseFolder/Project1/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project1/app/app.json" -Value (ConvertTo-Json $dependecyAppFile -Depth 10) -type File -Force

        $dependantAppFile = @{ id = '83fb8305-4079-415d-a25d-8132f0436fd2'; name = 'Second App'; publisher = 'Contoso'; version = '1.0.0.0'; dependencies = @(@{id = '83fb8305-4079-415d-a25d-8132f0436fd1'; name = 'First App'; publisher = 'Contoso'; version = '1.0.0.0'} ) }
        New-Item -Path "$baseFolder/Project2/.AL-Go/settings.json" -type File -Force
        New-Item -Path "$baseFolder/Project2/app/app.json" -Value (ConvertTo-Json $dependantAppFile -Depth 10) -type File -Force

        #Add settings file
        $alGoSettings = @{ fullBuildPatterns = @(); projects = @(); powerPlatformSolutionFolder = ''; useProjectDependencies = $true }
        New-Item -Path "$baseFolder/.github" -type Directory -Force
        $alGoSettings | ConvertTo-Json -Depth 99 -Compress | Out-File (Join-Path $baseFolder ".github/AL-Go-Settings.json") -Encoding UTF8

        # Add settings as environment variable to simulate we've run ReadSettings
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        { Get-ProjectsToBuild -baseFolder $baseFolder -maxBuildDepth 1 } | Should -Throw "The build depth is too deep, the maximum build depth is 1. You need to run 'Update AL-Go System Files' to update the workflows"
    }

    AfterEach {
        Remove-Item $baseFolder -Force -Recurse
    }
}

Describe "Get-BuildAllProjects" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot "../Actions/DetermineProjectsToBuild/DetermineProjectsToBuild.psm1" -Resolve) -DisableNameChecking
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'baseFolder', Justification = 'False positive.')]
        $baseFolder = (New-Item -ItemType Directory -Path (Join-Path $([System.IO.Path]::GetTempPath()) $([System.IO.Path]::GetRandomFileName()))).FullName
    }

    It ('returns false if there are no modified files') {
        # Add AL-Go settings
        $alGoSettings = @{ fullBuildPatterns = @() }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $buildAllProjects = Get-BuildAllProjects -baseFolder $baseFolder
        $buildAllProjects | Should -Be $false
    }

    It ('returns true if any of the modified files matches any of the patterns in fullBuildPatterns setting') {
        # Add AL-Go settings
        $alGoSettings = @{ fullBuildPatterns = @('Project1/*') }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $modifiedFiles = @('Project1/.AL-Go/settings.json', 'Project2/.AL-Go/settings.json')
        $buildAllProjects = Get-BuildAllProjects -baseFolder $baseFolder -modifiedFiles $modifiedFiles
        $buildAllProjects | Should -Be $true
    }

    It ('returns false if the modified files are less than 250 and none of them matches any of the patterns in fullBuildPatterns setting') {
        # Add AL-Go settings
        $alGoSettings = @{ fullBuildPatterns = @('Project1/*') }
        $env:Settings = ConvertTo-Json $alGoSettings -Depth 99 -Compress

        $modifiedFiles = @('Project2/.AL-Go/settings.json', 'Project3/.AL-Go/settings.json')
        $buildAllProjects = Get-BuildAllProjects -baseFolder $baseFolder -modifiedFiles $modifiedFiles
        $buildAllProjects | Should -Be $false
    }

    AfterEach {
        Remove-Item $baseFolder -Force -Recurse
    }
}
