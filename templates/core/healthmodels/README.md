# Platform health model

`core-healthmodels` runs at order `19` as a subscription deployment in the management subscription, after the hub networking and Virtual WAN modules. It has its own `Health Models` deployment group, so you can select it without selecting the rest of `Core`. `.config/ALZ-Powershell.config.json` points to `templates/core/healthmodels/main.bicep` and `main.bicepparam`.

The deployment creates a resource group, a discovery user-assigned identity, a Reader assignment on the deployment subscription, the `ahm-alz-platform` parent model, and five child models.

See the [ALZ platform health model guide](docs/health-model-alz-guide.md) for the topology diagram and rollup examples.

## Why these five domains

The child models follow the management-group deployments the accelerator already creates, so the health model mirrors a hierarchy you have deployed rather than a new grouping you have to learn.

| Domain | Child model | Accelerator deployment |
|---|---|---|
| Security | `ahm-alz-security` | `governance-platform-security` |
| Identity | `ahm-alz-identity` | `governance-platform-identity` |
| Connectivity | `ahm-alz-connectivity` | `governance-platform-connectivity` |
| Management | `ahm-alz-management` | `governance-platform-management` |
| Application Landing Zones | `ahm-alz-landing-zones` | `governance-landingzones` |

## How the parent reaches its children

The parent model holds one entity and one discovery rule per domain. Each rule is a Resource Graph query over the health-model resource group that filters on the tags the child module writes: `alzHealthModelRole=domain`, `alzHealthModelDomain=<domain key>`, and `alzHealthModelParent=<parent model name>`.

No child resource ID reaches the parent. The parent resolves the link at runtime from tag values, which has three consequences:

- Rewriting those tags outside this module detaches the child from the parent.
- A child deployed into another resource group falls outside the parent's query.
- The parent returns nothing until the discovery identity holds Reader on the queried scope.

## What a default deployment gives you

Each child model contains one placeholder entity with no signal definitions. The default is a deployable topology, not a populated model:

- The templates define no signals, thresholds, or alert rules.
- Nothing describes your platform's operational health until you add your own entities, signals, and relationships to each child model.
- A domain branch without signals stays Unknown. Parent domain entities aggregate with `WorstOf`, so add signals before relying on the parent state.

Child discovery rules set `addRecommendedSignals` to `Enabled`, so signals appear for resources a rule actually returns at runtime. That depends on the effective resource-type list and on Reader access, both of which are worth reviewing before you rely on any result. The parent's own domain rules keep `addRecommendedSignals` and `discoverRelationships` disabled, so the parent branch adds no signals of its own.

Treat the placeholder entity as the slot to replace once you know which workloads and signals the platform team wants to track.

## Parameters

| Parameter | Purpose |
|---|---|
| `parHealthModelResourceGroup` | Resource group for all health-model resources. The parent scopes its discovery queries to this group, so child models must land here. |
| `parHealthModelName` | Parent health model name (default `ahm-alz-platform`). Child models carry this value in their `alzHealthModelParent` tag. |
| `parHealthModelLocation` | Region for the health models. Microsoft.CloudHealth validates regional availability during deployment. |
| `parDiscoveryIdentityName` | User-assigned identity used by discovery rules. |
| `parLocations` | Accelerator locations array. The first location places the resource group and discovery identity and contributes to deployment names. |
| `parTags` | Tags applied to created resources. |
| `parGlobalResourceLock` | Global lock applied to the resource group, discovery identity, and health models. |
| `parEnableTelemetry` | Enables accelerator telemetry resources for this deployment path. |
| `parManagementSubscriptionId` | Subscription queried by the Management domain rule. Defaults to the deployment subscription. |
| `parConnectivitySubscriptionId` | Subscription queried by the Connectivity domain rule. Empty by default, which omits the rule. |
| `parIdentitySubscriptionId` | Subscription queried by the Identity domain rule. Empty by default, which omits the rule. |
| `parSecuritySubscriptionId` | Subscription queried by the Security domain rule. Empty by default, which omits the rule. |
| `parDomainResourceTypes` | Per-domain override of the built-in resource-type lists. An omitted domain keeps its default list; an explicit `[]` omits that domain's rule unless the domain also appears in `parSubscriptionWideDiscoveryDomains`. |
| `parSubscriptionWideDiscoveryDomains` | Domains that fall back to a subscription-wide query when their resource-type list is empty. Empty by default, so clearing a list narrows discovery instead of widening it. |
| `parLandingZoneDiscoveryManagementGroupIds` | Management groups the Application Landing Zones rule searches. Empty by default, which omits the rule. |
| `parEnableCrossScopeDiscoveryReader` | Grants the discovery identity Reader on domain subscriptions outside the deployment subscription. `false` by default, so cross-subscription discovery returns nothing until you opt in. Management-group Reader is a separate deployment of `discoveryReaderMg.bicep`. |

## Discovery behavior

Each child model has a Resource Graph discovery rule attached to its root entity. Management, Connectivity, Identity, and Security query by resource type inside their domain subscription. Application Landing Zones queries the management groups you list for health models outside this platform hierarchy.

The subscription parameters below default to empty in the template, but `main.bicepparam` fills them from the accelerator's platform subscription tokens, so a normal accelerator run creates all four resource-type rules.

The four resource-type domains ship with default lists, and the two halves differ in how much you should trust them:

- **Management and Connectivity** list resource types this accelerator produces: the workspace and automation account from `templates/core/logging`, the hub, gateway, and private DNS resources from `templates/networking`, the data collection rules created by the platform monitoring policy assignments, and the discovery identity this module deploys.
- **Identity and Security** list resource types common in ALZ identity and security subscriptions. The accelerator does not deploy their contents, so read both lists against what you actually run there and override them through `parDomainResourceTypes` before you draw conclusions from the result.

An empty effective list omits that domain's rule unless `parSubscriptionWideDiscoveryDomains` names the domain, in which case the domain uses a subscription-wide query with no type filter.

## Discovery identity access

Discovery only returns results from scopes where the shared discovery identity holds Reader.

- Reader is granted on the deployment (management) subscription by default.
- Set `parEnableCrossScopeDiscoveryReader` to `true` to also grant Reader on domain subscriptions outside the deployment subscription. Without it, those rules return nothing.
- The Application Landing Zones rule needs Reader at each target management group. This subscription-scoped deployment cannot assign management-group roles, so grant it separately:

```bash
az deployment mg create --management-group-id <mgId> --location <region> \
  -f templates/core/healthmodels/discoveryReaderMg.bicep \
  -p parPrincipalId=<outDiscoveryIdentityPrincipalId> parRoleDefinitionId=acdd72a7-3385-48ef-bd42-f606fba81ae7
```

## Build and test

Use the Bicep version bundled with the Azure CLI. `az bicep build` also runs the linter:

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

This unreleased module supports fresh deployments only. Incremental redeployments do not delete resources removed from the template. For example, clearing `parDiscoveryRules` leaves existing discovery rules, authentication settings, and relationships in place while the identity changes to `SystemAssigned`. Test in a throwaway resource group or subscription, then delete those child resources or redeploy into a new resource group.
