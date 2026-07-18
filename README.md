# winget-pkgs-selfhost

A template repository for hosting your own WinGet source — the same automation that powers [pl4nty/winget-extras](https://github.com/pl4nty/winget-extras).

## Features

- **Automated package updates** with [Anthelion](https://github.com/UnownPlain/anthelion-external) and [Komac](https://github.com/russellbanks/Komac) — declare an update strategy per package in `shards/`, and new versions are detected and submitted as pull requests automatically
- **Automated validation** — changed manifests are installed on GitHub-hosted Windows runners (x64 and arm64), with [Attack Surface Analyzer](https://github.com/microsoft/AttackSurfaceAnalyzer) reports, screenshots, and installer logs
- **Preindexed source builds** — manifests are merged and indexed into a signed MSIX source package that the WinGet client consumes directly, including cross-source dependency resolution from [winget-pkgs](https://github.com/microsoft/winget-pkgs)
- **Pluggable storage backends** — serve the source from GitHub, Azure Blob Storage, or any S3-compatible bucket (AWS S3, Cloudflare R2, MinIO...)
- **Pluggable signing backends** — sign the source package with Azure Trusted Signing or an Azure Key Vault certificate via AzureSignTool
- **Linting** — manifest hygiene checks, plus zizmor/actionlint/shellcheck for the workflows themselves

## Getting started

1. [Create a repository from this template](https://github.com/new?template_name=winget-pkgs-selfhost&template_owner=pl4nty)
2. Update the `Identity`, `Properties`, and display names in [`index/AppxManifest.xml`](./index/AppxManifest.xml). The `Publisher` must exactly match the subject of your signing certificate. Optionally replace the logos in [`index/Assets`](./index/Assets)
3. Configure a [signing backend](#signing-backends) — WinGet requires preindexed sources to be signed by a certificate the client trusts
4. Configure a [storage backend](#storage-backends) (defaults to GitHub, no setup required)
5. [Add packages](#adding-packages)
6. Add the source on your machines:

```sh
winget source add --name selfhost --type Microsoft.PreIndexed.Package --arg <cache URL for your storage backend>
```

## Signing backends

Both backends authenticate to Azure with OIDC — no stored credentials:

1. [Create an app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
2. [Add a federated credential for the repository](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions) (entity type `Branch`, branch `main`)
3. [Create these repository variables](https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-a-repository):

| Variable                | Value                                                |
| ----------------------- | ---------------------------------------------------- |
| `AZURE_TENANT_ID`       | App registration tenant ID                           |
| `AZURE_CLIENT_ID`       | App registration client ID                           |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID (only needed for Azure Blob Storage) |

### Azure Trusted Signing

1. [Set up an Azure Trusted Signing certificate profile](https://learn.microsoft.com/en-us/azure/trusted-signing/quickstart) (currently closed to new users)
2. [Assign Trusted Signing Certificate Profile Signer to the app registration](https://learn.microsoft.com/en-us/azure/trusted-signing/tutorial-assign-roles)
3. Create these repository variables:

| Variable                 | Value                                                               |
| ------------------------ | ------------------------------------------------------------------- |
| `SIGNING_BACKEND`        | `trusted-signing`                                                   |
| `AZURE_SIGNING_ENDPOINT` | Trusted Signing endpoint, like `https://eus.codesigning.azure.net/` |
| `AZURE_SIGNING_ACCOUNT`  | Trusted Signing account name                                        |
| `AZURE_SIGNING_PROFILE`  | Certificate profile name                                            |

### AzureSignTool (Azure Key Vault)

1. Import or generate a code signing certificate in an [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/certificates/certificate-scenarios)
2. Assign the app registration the `Key Vault Crypto User` and `Key Vault Certificate User` roles (or equivalent access policies) on the vault
3. Create these repository variables:

| Variable          | Value                                                  |
| ----------------- | ------------------------------------------------------ |
| `SIGNING_BACKEND` | `azuresigntool`                                        |
| `KEY_VAULT_URL`   | Key Vault URL, like `https://myvault.vault.azure.net/` |
| `KEY_VAULT_CERT`  | Certificate name in the vault                          |

> [!NOTE]
> If the certificate isn't from a public CA (e.g. self-signed), it must be deployed to the `Local Machine\Trusted People` or `Trusted Root Certification Authorities` store on client machines.

## Storage backends

### GitHub (default)

No configuration needed. The generated `cache` directory is committed back to the repository and served from `raw.githubusercontent.com`:

```sh
winget source add --name selfhost --type Microsoft.PreIndexed.Package --arg https://github.com/OWNER/REPO/raw/main/cache
```

Best for small sources — every rebuild adds the source package to the repository's history, and GitHub raw serving isn't a CDN.

### Azure Blob Storage

1. Create a storage account and a blob container with anonymous read access for blobs (or front it with Azure CDN / Front Door)
2. Assign the app registration the `Storage Blob Data Contributor` role on the container
3. Create these repository variables:

| Variable                  | Value                                       |
| ------------------------- | ------------------------------------------- |
| `STORAGE_BACKEND`         | `azure-blob`                                |
| `AZURE_STORAGE_ACCOUNT`   | Storage account name                        |
| `AZURE_STORAGE_CONTAINER` | Container name (defaults to `cache`)        |
| `AZURE_SUBSCRIPTION_ID`   | Subscription containing the storage account |

```sh
winget source add --name selfhost --type Microsoft.PreIndexed.Package --arg https://ACCOUNT.blob.core.windows.net/CONTAINER
```

### S3-compatible (AWS S3, Cloudflare R2, MinIO...)

The cache is synced with [rclone](https://rclone.org/s3/), so any S3-compatible provider works. Serve the bucket over HTTPS (e.g. an R2 custom domain, CloudFront, or public bucket hosting).

1. Create a bucket and an access key with write permission
2. Create these repository variables and secrets:

| Variable          | Value                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------ |
| `STORAGE_BACKEND` | `s3`                                                                                                               |
| `S3_BUCKET`       | Bucket name                                                                                                        |
| `S3_ENDPOINT`     | Endpoint URL for non-AWS providers, like `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`                           |
| `S3_PROVIDER`     | [rclone provider name](https://rclone.org/s3/#providers), like `AWS`, `Cloudflare`, or `Minio` (defaults to `AWS`) |

| Secret                  | Value             |
| ----------------------- | ----------------- |
| `AWS_ACCESS_KEY_ID`     | Access key ID     |
| `AWS_SECRET_ACCESS_KEY` | Secret access key |

```sh
winget source add --name selfhost --type Microsoft.PreIndexed.Package --arg https://your-domain.example.com/cache
```

## Adding packages

### Manifests

Add standard [WinGet manifests](https://learn.microsoft.com/en-us/windows/package-manager/package/manifest) under `manifests/<first letter>/<Publisher>/<Package>/<version>/`, the same layout as [winget-pkgs](https://github.com/microsoft/winget-pkgs). [Komac](https://github.com/russellbanks/Komac) or [wingetcreate](https://github.com/microsoft/winget-create) can generate them for you. Font packages can live in an optional `fonts/` directory with the same layout.

On merge to `main`, the [publish workflow](./.github/workflows/publish.yml) merges the manifests, resolves [winget-pkgs](https://github.com/microsoft/winget-pkgs) dependencies, builds the preindexed source package with `IndexCreationTool`, signs it, and uploads it to your storage backend.

### Automated updates (Anthelion)

Add a shard at `shards/json/<PackageIdentifier>.json` describing how to detect new versions. The [update workflow](./.github/workflows/update-packages.yml) runs Anthelion on a schedule, and it opens a pull request via Komac when a new version is found. For example, a package released on GitHub:

```json
{
	"$schema": "https://anthelion.unownplain.dev/schema.json",
	"strategy": "github-release",
	"github": { "owner": "rustdesk", "repo": "rustdesk" },
	"urls": [
		"https://github.com/rustdesk/rustdesk/releases/download/{version}/rustdesk-{version}-x86_64.exe"
	]
}
```

Other strategies include `json` (poll a JSON endpoint) and `page-match` (regex over a web page) — see the [schema](https://anthelion.unownplain.dev/schema.json) and the shards in [winget-extras](https://github.com/pl4nty/winget-extras/tree/main/shards/json) for examples. Suffix a shard filename with `.disabled` to skip it.

Anthelion authenticates as a GitHub App so its pull requests trigger CI:

1. [Create a GitHub App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app) with `Contents` and `Pull requests` write permissions, and install it on your repository
2. Create the `GH_CLIENT_ID` repository variable (the app's client ID) and the `GH_PRIVATE_KEY` repository secret (a private key for the app)

## Validation

Changed manifests in pull requests are validated automatically by the [validate workflow](./.github/workflows/validate.yml): each installer is installed on a GitHub-hosted runner matching its architecture, with logs, an Attack Surface Analyzer SARIF report, and a desktop screenshot attached to the job summary. Limitations:

- Interactive installation is only tested if silent installation fails
- The `arm` architecture (32-bit ARM) is not tested

You can also validate manually with `SandboxTest` from winget-pkgs:

```sh
git clone https://github.com/microsoft/winget-pkgs
cd winget-pkgs\Tools
.\SandboxTest.ps1 -Manifest ..\..\REPO\manifests\p\Publisher\Package\1.0\
```

## Enterprise deployment

The source can be deployed to managed devices via the [`EnableAdditionalSources`](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-desktopappinstaller#enableadditionalsources) policy.

The `Identifier` is the package family name of your source package: the `Identity Name` from `index/AppxManifest.xml` plus a hash of the publisher, e.g. `Winget.Source.Selfhost_ggk937h18f62r`. Get it from a machine with the source installed via `Get-AppxPackage` in PowerShell.

### Intune

In the Settings Catalog, enable **Administrative Templates > Windows Components > Desktop App Installer > Enable App Installer Additional Sources** and set the value to:

<!-- prettier-ignore -->
```json
{"Arg":"<cache URL>","Data":"<Identifier>","Explicit":false,"Identifier":"<Identifier>","Name":"selfhost","TrustLevel":["Trusted"],"Type":"Microsoft.PreIndexed.Package"}
```

### Group Policy

Enable **Computer Configuration > Administrative Templates > Windows Components > Desktop App Installer > Enable App Installer Additional Sources** and set the same value as above.

## Credits

Inspired by [ScoopInstaller/Extras](https://github.com/ScoopInstaller/Extras). See a real deployment at [pl4nty/winget-extras](https://github.com/pl4nty/winget-extras).
