# Platform health model

`core-healthmodels` (order `17`) deploys by default from `.config/ALZ-Powershell.config.json` as a subscription deployment (`templates/core/healthmodels/main.bicep` + `main.bicepparam`) in the management subscription. It creates one resource group, one discovery user-assigned identity, Reader on the subscription for that identity, one parent model (`ahm-alz-platform`), and five domain child models (`ahm-alz-security`, `ahm-alz-identity`, `ahm-alz-connectivity`, `ahm-alz-management`, `ahm-alz-landing-zones`). The parent has five top-level domain entities (Security, Identity, Connectivity, Management, Application Landing Zones), each linked to a narrow Resource Graph discovery rule that finds only its domain child model in the health-model resource group.

## Parameters

| Parameter | Purpose |
|---|---|
| `parHealthModelResourceGroup` | Resource group for all health-model resources. |
| `parHealthModelName` | Parent health model name (default design name: `ahm-alz-platform`). |
| `parHealthModelLocation` | Health model region (CloudHealth-supported subset, smaller than platform regions). |
| `parDiscoveryIdentityName` | User-assigned identity used by discovery rules. |
| `parLocations` | Accelerator locations array used for naming defaults. |
| `parTags` | Tags applied to created resources. |
| `parGlobalResourceLock` | Global lock applied to the resource group, discovery identity, and health models. |
| `parEnableTelemetry` | Enables accelerator telemetry resources for this deployment path. |

## Develop and test only the health models

Build and lint (uses the Bicep bundled with the Azure CLI; `az bicep build` also runs the linter):

```bash
az bicep build --file templates/core/healthmodels/main.bicep --stdout
az bicep build-params --file templates/core/healthmodels/main.bicepparam --outfile /dev/stdout
```

Deploy only this module (subscription scope):

```bash
az deployment sub what-if -l <region> -f templates/core/healthmodels/main.bicep -p templates/core/healthmodels/main.bicepparam
az deployment sub validate -l <region> -f templates/core/healthmodels/main.bicep -p templates/core/healthmodels/main.bicepparam
az deployment sub create -l <region> -f templates/core/healthmodels/main.bicep -p templates/core/healthmodels/main.bicepparam
```

`main.bicepparam` contains accelerator `{{tokens}}`. For isolated testing, pass inline `-p` overrides or use a rendered parameter file.

Register the provider first: `az provider register -n Microsoft.CloudHealth`.

Fresh-deploy-only (unreleased): incremental redeploys do not delete resources removed from the template. Test in a throwaway resource group or subscription.
