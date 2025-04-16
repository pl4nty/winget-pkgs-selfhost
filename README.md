# winget-pkgs-selfhost

Host your own WinGet packages directly from GitHub.

## Getting Started

WinGet preindexed sources are packaged in MSIX files, which need to be signed by a trusted certificate. You can bring your own by modifying `[main.yml](.github/workflows/main.yml)`, or use Azure Trusted Signing (currently closed to new users).

1. [Click here](https://github.com/new?template_name=winget-pkgs-selfhost&template_owner=pl4nty) to create a repository
2. [Create an app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
3. [Add a federated credential for the repository](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions)
4. [Setup an Azure Trusted Signing certificate profile](https://learn.microsoft.com/en-us/azure/trusted-signing/quickstart)
5. [Assign Trusted Signing Certificate Profile Signer to the app](https://learn.microsoft.com/en-us/azure/trusted-signing/tutorial-assign-roles)
6. [Create the following variables](https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-a-repository)

| Name | Value |
| ---- | ----- |
| `AZURE_SIGNING_ENDPOINT` | Trusted Signing endpoint, like `https://eus.codesigning.azure.net/` |
| `AZURE_SIGNING_ACCOUNT` | Trusted Signing account name |
| `AZURE_SIGNING_PROFILE` | Trusted Signing certificate profile name |

## Usage

In an administrative shell, run

`winget source add --name selfhost --type Microsoft.PreIndexed.Package --Argument https://github.com/pl4nty/winget-pkgs-selfhost/raw/main/cache`
