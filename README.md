# Azure Function App - Message API Deployment Task

## Architecture overview

This project deploys a private internal API in Azure using an Azure Function App behind a private endpoint, with mutual TLS (mTLS) enforced at the platform level. All traffic remains on the Azure private backbone via private endpoints and VNet integration.

```
Client (with cert) → Private Endpoint → Function App (mTLS enforced) → Python logic
```

### Resources deployed

| Resource | Purpose |
|---|---|
| Virtual Network | Isolates all resources from the public internet |
| snet-func-int (10.0.1.0/24) | Function App VNet integration subnet |
| snet-pe (10.0.2.0/24) | Private endpoints subnet |
| NSGs | Least-privilege rules on each subnet |
| Azure Function App (Flex Consumption) | API logic — POST /api/message |
| Private Endpoint (Function App) | Internal-only API entry point |
| Key Vault | Stores CA cert, client cert, and private keys |
| Private Endpoint (Key Vault) | Keeps Key Vault off the public internet |
| Storage Account | Function App backing store |
| Private Endpoint (Storage) | Keeps storage off the public internet |
| Private DNS Zones | Internal hostname resolution for all private endpoints |
| Log Analytics Workspace | Centralised logging |
| Application Insights | Function App telemetry |
| Monitor Alert Rule | HTTP 5xx alert |

---

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.7.0
- GitHub repository with Actions enabled
- An Azure subscription

---

## Setup

### 1. Bootstrap — one-time manual steps

These resources must exist before the pipeline can run, as they are required for authentication and cannot be created by Terraform itself.

**Create the App Registration for OIDC:**

```bash
az ad app create --display-name "github-actions-oidc"
az ad sp create --id <app-id>
az role assignment create --role Contributor \
  --assignee <sp-object-id> \
  --scope /subscriptions/<subscription-id>
az role assignment create --role "User Access Administrator" \
  --assignee <sp-object-id> \
  --scope /subscriptions/<subscription-id>
```

**Add a federated credential** in the Azure Portal:

```
App Registration → Certificates & secrets → Federated credentials → Add credential
Scenario:     GitHub Actions deploying Azure resources
Organisation: <your-github-username>
Repository:   <your-repo-name>
Entity type:  Branch
Branch:       main
```

> Note: the subject identifier is case-sensitive and must exactly match
> `repo:<org>/<repo>:ref:refs/heads/main`

**Add GitHub Actions secrets** in your repository settings under Settings → Secrets and variables → Actions:

```
AZURE_CLIENT_ID       → App Registration → Application (client) ID
AZURE_TENANT_ID       → App Registration → Directory (tenant) ID
AZURE_SUBSCRIPTION_ID → Your Azure subscription ID
```

### 2. Deploy

Push to the `main` branch. The pipeline will automatically run:

1. `terraform fmt -check`
2. `terraform init`
3. `terraform validate`
4. `terraform plan`

To apply, trigger the workflow manually from the Actions tab and select `apply`.

---

## Teardown

Navigate to your repository → **Actions** → **Terraform CI** → **Run workflow**, select `destroy`, and click **Run workflow**.

> **Important:** teardown via the pipeline requires remote state to be configured (see below).
> Without remote state the runner has no record of what was deployed and cannot destroy it.

---

## Remote state

Remote state is not implemented in this assessment but the intended approach is as follows.

**Create the bootstrap resources manually (once):**

```bash
az group create --name rg-terraform-state --location westeurope
az storage account create \
  --name tfstateabc12345 \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --allow-blob-public-access false
az storage container create \
  --name tfstate \
  --account-name tfstateabc12345
```

**Add the backend block to `main.tf`:**

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateabc12345"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
```

Run `terraform init` to migrate local state to the remote backend. The state storage account is intentionally separated from the application infrastructure so that `terraform destroy` does not delete the state itself.

---

## Assumptions and known limitations

**Key Vault firewall**
The Key Vault network ACL is set to `default_action = "Allow"` to permit the GitHub Actions runner to write secrets during deployment. In production this would be resolved by using a self-hosted runner deployed inside the VNet, with the ACL locked to the VNet subnet only.

**Service plan SKU**
EP1 (Elastic Premium) was the intended SKU as it is the standard plan for VNet-integrated Function Apps. However, the Azure free tier subscription has a quota of zero for Elastic Premium VMs. Flex Consumption (`FC1`) was used instead as it also supports VNet integration and does not share the same quota pool. The region was changed from `uksouth` to `westeurope` due to quota availability.

**mTLS enforcement**
`client_certificate_mode = "Required"` validates that a client certificate is presented before requests reach the function code. Full CA chain validation (confirming the certificate is signed by the specific CA generated in this project) would require additional configuration such as Application Gateway with a custom truststore, or thumbprint validation inside the function itself.

**Remote state**
Terraform state is currently stored locally. Without remote state the pipeline cannot reliably manage previously deployed resources across runs. See the remote state section above for the intended implementation.

**Flex Consumption resource**
`azurerm_function_app_flex_consumption` required `azurerm` provider `~> 4.21`. There are known open issues around Managed Identity stability on this resource type. This is noted as a limitation and would be monitored in a production deployment.

---

## AI usage and critique

This project was developed with assistance from Claude (Anthropic). The following patterns were identified and corrected during review:

- The initial output included both API Management and a Function App private endpoint simultaneously. The brief requires one or the other — APIM was removed in favour of the private endpoint approach for simplicity.
- `private_endpoint_network_policies_enabled` was used in the initial output but this argument is deprecated in `azurerm ~> 3.x`. Replaced with `private_endpoint_network_policies = "Disabled"`.
- Changed the SKU of the service plan from `EP1` to `FC1`.
- The initial `azurerm_linux_function_app` resource was not compatible with the `FC1` SKU. The correct resource type is `azurerm_function_app_flex_consumption`.
- `WEBSITE_CONTENTSHARE`, `WEBSITE_RUN_FROM_PACKAGE`, and other legacy app settings were included in the initial output but are unsupported on Flex Consumption and would cause deployment errors.
- The storage account access key is passed directly to the function app resource. In production this would be replaced with Managed Identity authentication to avoid credentials in Terraform state.
- CA and client private keys are stored in Terraform state in plaintext as a result of using the `tls` provider. In production these would be generated outside Terraform and imported, or managed via a dedicated secrets management workflow.
- This README file was also generated from notes that I had made throughout the process of this 