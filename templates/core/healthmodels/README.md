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
| `parManagementSubscriptionId` | Subscription ID queried by the Management domain discovery rule. |
| `parConnectivitySubscriptionId` | Subscription ID queried by the Connectivity domain discovery rule. |
| `parIdentitySubscriptionId` | Subscription ID queried by the Identity domain discovery rule. |
| `parSecuritySubscriptionId` | Subscription ID queried by the Security domain discovery rule. |
| `parDomainResourceTypes` | Optional per-domain override for the built-in platform-domain resource-type discovery defaults. |
| `parSubscriptionWideDiscoveryDomains` | Domains that should emit a subscription-wide (no type filter) discovery rule, effective only when that domain's effective type list is empty (i.e. overridden to `[]` via `parDomainResourceTypes`). |
| `parLandingZoneDiscoveryManagementGroupIds` | Management group IDs used by the Application Landing Zones domain discovery rule. Empty means no landing-zone discovery rule is created. |
| `parEnableCrossScopeDiscoveryReader` | When `true`, also grants the shared discovery identity Reader on the Connectivity, Identity, and Security subscriptions. Management-group Reader for the landing-zone rule is NOT granted here (a subscription-scoped deployment cannot assign at management-group scope); use a separate deployment of `discoveryReaderMg.bicep`. |

## Discovery behavior

- Each domain child health model has a Resource Graph discovery rule attached to its model root entity.
- The Management, Connectivity, Identity, and Security domains discover resources by resource type in their domain subscription.
- All four platform domains ship built-in default resource-type lists (Management and Connectivity mirror the types this accelerator deploys under `templates/core/logging` and `templates/networking`; Identity and Security carry canonical ALZ identity/security types). Override any of them with `parDomainResourceTypes`.
- A domain emits no rule only when its effective type list is overridden to empty AND it is not listed in `parSubscriptionWideDiscoveryDomains`; listing an empty-typed domain there makes it emit a subscription-wide (no type filter) rule instead.
- The Application Landing Zones domain discovers other (non-platform/domain) health models across the management groups listed in `parLandingZoneDiscoveryManagementGroupIds`. An empty list creates no landing-zone discovery rule.
- Domain child-model discovery rules set `addRecommendedSignals` to `Enabled`; `addResourceHealthSignal` defaults to `Disabled`. (The parent model's domain-discovery rules keep `addRecommendedSignals` `Disabled`.)

## Discovery identity access caveat

- Discovery only returns results from scopes where the shared discovery identity has Reader.
- By default, Reader is granted only on the deployment (management) subscription.
- Set `parEnableCrossScopeDiscoveryReader` to `true` to also grant Reader on the Connectivity, Identity, and Security subscriptions.
- The Application Landing Zones rule needs Reader at each target management group. A subscription-scoped deployment cannot assign at management-group scope, so grant it with a separate management-group deployment of `discoveryReaderMg.bicep`, for example:

```bash
az deployment mg create --management-group-id <mgId> --location <region> \
  -f templates/core/healthmodels/discoveryReaderMg.bicep \
  -p parPrincipalId=<outDiscoveryIdentityPrincipalId> parRoleDefinitionId=acdd72a7-3385-48ef-bd42-f606fba81ae7
```
- Without that extra Reader access, Connectivity, Identity, Security, and Application Landing Zones discovery rules are still created but return no data for those scopes.

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

Fresh-deploy-only (unreleased): incremental redeploys do not delete resources removed from the template. Test in a throwaway resource group or subscription. In particular, emptying `parDiscoveryRules` for a domain (or removing discovery inputs) does not delete already-created `discoveryrules`, `authenticationsettings`, or `relationships`; the identity also reverts to `SystemAssigned`, leaving orphaned rules. Remove those children manually or redeploy into a fresh resource group.
