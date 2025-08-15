# AL-Go for GitHub

AL-Go for GitHub is a set of GitHub templates and actions, which can be used to setup and maintain professional DevOps processes for your Business Central AL projects.

The goal is that people who have created their GitHub repositories based on the AL-Go templates, can maintain these repositories and stay current just by running a workflow, which updates their repositories. This includes necessary changes to scripts and workflows to cope with new features and functions in Business Central.

The roadmap for AL-Go for GitHub can be found here: [https://aka.ms/ALGoRoadmap](https://aka.ms/ALGoRoadmap)

Release notes for all versions of AL-Go for GitHub can be found [here](./RELEASENOTES.md).

Deprecations for all versions of AL-Go for GitHub can be found [here](./DEPRECATIONS.md).

The template repositories to use as starting point are:

- [https://github.com/microsoft/AL-Go-PTE](https://github.com/microsoft/AL-Go-PTE) or [https://aka.ms/algopte](https://aka.ms/algopte) is the GitHub repository template for Per Tenant Extensions. When creating a Per Tenant Extensions, this is your starting point.
- [https://github.com/microsoft/AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) or [https://aka.ms/algoappsource](https://aka.ms/algoappsource) is the GitHub repository template for AppSource apps. When creating an AppSource App, this is your starting point.

## AL-Go Workshop

Try out the [AL-Go workshop](https://aka.ms/algoworkshop) for an in-depth workshop on AL-Go for GitHub functionality or examine the below usage scenarios, which explains how to get started and how to perform the most common tasks.

## Usage scenarios

1. [Create a new per-tenant extension (like AL Go) and start developing in VS Code](Scenarios/GetStarted.md)
1. [Add a test app to an existing project](Scenarios/AddATestApp.md)
1. [Register a customer sandbox environment for Continuous Deployment using S2S](Scenarios/RegisterSandboxEnvironment.md)
1. [Create a release of your application](Scenarios/CreateRelease.md)
1. [Register a customer production environment for Manual Deployment](Scenarios/RegisterProductionEnvironment.md)
1. [Create a GhTokenWorkflow secret](Scenarios/GhTokenWorkflow.md)
1. [Update AL-Go system files](Scenarios/UpdateAlGoSystemFiles.md)
1. [Use Azure KeyVault for secrets with AL-Go](Scenarios/UseAzureKeyVault.md)
1. [Create Online Development Environment from VS Code](Scenarios/CreateOnlineDevEnv.md)
1. [Create Online Development Environment from GitHub](Scenarios/CreateOnlineDevEnv2.md)
1. [Set up CI/CD for an existing per tenant extension (BingMaps)](Scenarios/SetupCiCdForExistingPTE.md)
1. [Set up CI/CD for an existing AppSource App](Scenarios/SetupCiCdForExistingAppSourceApp.md)
1. [Enable KeyVault access for your AppSource App during development and/or tests](Scenarios/EnableKeyVaultForAppSourceApp.md)
1. [Set up your own GitHub runner to increase build performance](Scenarios/SelfHostedGitHubRunner.md)
1. [Introducing a dependency to another GitHub repository](Scenarios/AppDependencies.md)
1. [DeliveryTargets and NuGet/GitHub Packages](Scenarios/DeliveryTargets.md)
1. [Enabling Telemetry for AL-Go workflows and actions](Scenarios/EnablingTelemetry.md)
1. [Add a performance test app to an existing project](Scenarios/AddAPerformanceTestApp.md)
1. [Publish your app to AppSource](Scenarios/PublishToAppSource.md)
1. [Connect your GitHub repository to Power Platform](Scenarios/SetupPowerPlatform.md)
1. [How to set up Service Principal for Power Platform](Scenarios/SetupServicePrincipalForPowerPlatform.md)
1. [Try one of the Business Central and Power Platform samples](Scenarios/TryPowerPlatformSamples.md)
1. [Customizing AL-Go for GitHub](Scenarios/CustomizingALGoForGitHub.md)

## Migration scenarios

A. [Migrate a repository from Azure DevOps to AL-Go for GitHub without history](Scenarios/MigrateFromAzureDevOpsWithoutHistory.md)<br />
B. [Migrate a repository from Azure DevOps to AL-Go for GitHub with history](Scenarios/MigrateFromAzureDevOpsWithHistory.md)

> [!NOTE]
> Please refer to [this description](Scenarios/settings.md) to learn about the settings file and how you can modify default behaviors.

# This project

This project in the main source repository for AL-Go for GitHub. This project is deployed on every release to a branch in the following repositories:

- [https://github.com/microsoft/AL-Go-PTE](https://github.com/microsoft/AL-Go-PTE) is the GitHub repository template for Per Tenant Extenstions. For creating a Per Tenant Extensions, this is your starting point.
- [https://github.com/microsoft/AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) is the GitHub repository template for AppSource apps. For creating an AppSource App, this is your starting point.
- [https://github.com/microsoft/AL-Go-Actions](https://github.com/microsoft/AL-Go-Actions) is the GitHub repository containing the GitHub Actions used by the templates above.

# Contributing

Please read [this document](Scenarios/Contribute.md) to understand how to contribute to AL-Go for GitHub.

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## See also

- [Developing Extensions in AL](https://go.microsoft.com/fwlink/?linkid=2216858&clcid=0x409)
- [AL-Go for GitHub](https://freddysblog.com/2022/04/26/al-go-for-github/)
- [Migrating to AL-Go for GitHub](https://freddysblog.com/2022/04/27/migrating-to-al-go-for-github/)
- [Structuring your AL-Go for GitHub repositories](https://freddysblog.com/2022/04/28/structuring-your-github-repositories/)
- [Preview of future AL-Go for GitHub functionality](https://freddysblog.com/2022/05/02/al-go-for-github-preview-bits/)
- [Branching strategies for your AL-Go for GitHub repo](https://freddysblog.com/2022/05/03/branching-strategies-for-your-al-go-for-github-repo/)
- [Deployment strategies and AL-Go for GitHub](https://freddysblog.com/2022/05/06/deployment-strategies-and-al-go-for-github/)
- [Secrets in AL-Go for GitHub](https://freddysblog.com/2022/05/14/secrets-in-al-go-for-github/)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
