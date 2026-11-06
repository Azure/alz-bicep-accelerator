# ALZ platform health model guide

The deployment creates the `ahm-alz-platform` parent model and five domain child models in one resource group. `templates/core/healthmodels/main.bicep` creates every box below, but the link from a parent entity to its child model is not a deploy-time reference. Each parent entity points at a discovery rule, and that rule resolves the child at runtime by matching the tags the child module wrote.

<!-- diagrammo:sync alz-platform-health-model-guide -->
![ALZ platform parent model with five domain child health models discovered by tags](media/alz-platform-health-model-guide.svg)

<!-- diagrammo:source
```mermaid
%%| renderer: swimlane
%%| theme: portal
%%| title: ALZ platform health model
%%| subtitle: The parent discovers five child health models by matching their tags.
%%| name: alz-platform-health-model-guide
%%| alt: ALZ platform parent model with five domain child health models discovered by tags
%%| lanes: [Platform parent, Domain entities, Child health models]
flowchart BT
  securityModel["ahm-alz-security<br/>child health model"] --&gt;|"tag discovery"| security["Security<br/>domain entity"]
  identityModel["ahm-alz-identity<br/>child health model"] --&gt;|"tag discovery"| identity["Identity<br/>domain entity"]
  connectivityModel["ahm-alz-connectivity<br/>child health model"] --&gt;|"tag discovery"| connectivity["Connectivity<br/>domain entity"]
  managementModel["ahm-alz-management<br/>child health model"] --&gt;|"tag discovery"| management["Management<br/>domain entity"]
  landingZonesModel["ahm-alz-landing-zones<br/>child health model"] --&gt;|"tag discovery"| landingZones["Application Landing Zones<br/>domain entity"]

  security --&gt; platform["ahm-alz-platform<br/>parent model"]
  identity --&gt; platform
  connectivity --&gt; platform
  management --&gt; platform
  landingZones --&gt; platform

  classDef purple fill:#f4f0fb,stroke:#8661c5;
  class securityModel,identityModel,connectivityModel,managementModel,landingZonesModel purple;
```
-->
<!-- /diagrammo:sync alz-platform-health-model-guide -->

## Domains

Each domain follows a management-group deployment the accelerator already creates.

| Display | Key | Child model | Accelerator deployment |
|---|---|---|---|
| Security | `security` | `ahm-alz-security` | `governance-platform-security` |
| Identity | `identity` | `ahm-alz-identity` | `governance-platform-identity` |
| Connectivity | `connectivity` | `ahm-alz-connectivity` | `governance-platform-connectivity` |
| Management | `management` | `ahm-alz-management` | `governance-platform-management` |
| Application Landing Zones | `landing-zones` | `ahm-alz-landing-zones` | `governance-landingzones` |

## What ships inside a child model

One placeholder entity, linked to the model root, with no signal definitions. The templates define no thresholds and no alert rules, so a fresh deployment gives you the shape of the model and nothing about the state of your platform. Add your own entities, signals, and relationships per domain before reading anything into the result.

## Rollup examples for inspiration

Use these examples as starting points when you replace the placeholder entities. The templates do not deploy these entities, signals, thresholds, or relationships. Adapt them to the dependencies and failure modes of your platform.

### WorstOf aggregation

The module applies `WorstOf` to parent domain entities. Once you add signals, the worst child state propagates along its parent path.

<!-- diagrammo:sync scenario-1-flat-worstof-blast-radius -->
![Degraded workspace ingestion signal propagating through Management to the platform](media/scenario-1-flat-worstof-blast-radius.svg)

<!-- diagrammo:source
```mermaid
%%| renderer: swimlane
%%| theme: portal
%%| title: WorstOf blast radius
%%| subtitle: Inspiration only. One degraded leaf propagates through its parent path.
%%| name: scenario-1-flat-worstof-blast-radius
%%| alt: Degraded workspace ingestion signal propagating through Management to the platform
%%| lanes: [Platform, Domains, Components]
flowchart BT
  leaf["Workspace ingestion signal<br/>state: Degraded"] --&gt; management["Management<br/>state: Degraded"]
  management --&gt; root["ahm-alz-platform<br/>state: Degraded"]
  identity["Identity<br/>state: Healthy"] --&gt; root
  connectivity["Connectivity<br/>state: Healthy"] --&gt; root

  classDef blue fill:#eff6fc,stroke:#0078D4;
  classDef green fill:#f2f8f2,stroke:#a0d8a0;
  classDef amber fill:#fbf2e7,stroke:#db7500;
  class leaf blue;
  class identity,connectivity green;
  class management,root amber;
```
-->
<!-- /diagrammo:sync scenario-1-flat-worstof-blast-radius -->

Docs: [Health model concepts](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/concepts) and [Configure health rollup](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/rollup).

### Shared dependency

A shared service can affect more than one platform flow. This example models both flows as dependent on the same Key Vault entity.

<!-- diagrammo:sync scenario-4-shared-key-vault-dependency -->
![Degraded shared Key Vault propagating through identity and landing zone flows](media/scenario-4-shared-key-vault-dependency.svg)

<!-- diagrammo:source
```mermaid
%%| renderer: swimlane
%%| theme: portal
%%| title: Shared Key Vault dependency
%%| subtitle: Inspiration only. One shared dependency affects two platform flows.
%%| name: scenario-4-shared-key-vault-dependency
%%| alt: Degraded shared Key Vault propagating through identity and landing zone flows
%%| lanes: [Platform, Flows, Shared services]
flowchart BT
  vaultSignal["Key Vault availability signal<br/>state: Degraded"] --&gt; vault["Shared Key Vault<br/>state: Degraded"]
  vault --&gt; identityFlow["Identity secrets flow<br/>state: Degraded"]
  vault --&gt; landingZoneFlow["Landing zone secrets flow<br/>state: Degraded"]
  identityFlow --&gt; platform["Platform<br/>state: Degraded"]
  landingZoneFlow --&gt; platform

  classDef blue fill:#eff6fc,stroke:#0078D4;
  classDef amber fill:#fbf2e7,stroke:#db7500;
  class vaultSignal blue;
  class vault,identityFlow,landingZoneFlow,platform amber;
```
-->
<!-- /diagrammo:sync scenario-4-shared-key-vault-dependency -->

### Limited impact

Set a dependency to `Limited` when its failure reduces service without stopping the platform. Azure treats a degraded child as Healthy and an unhealthy child as Degraded for propagation.

<!-- diagrammo:sync scenario-7-impact-lever-standard-to-limited -->
![Degraded Automation dependency with Limited impact while Management stays healthy](media/scenario-7-impact-lever-standard-to-limited.svg)

<!-- diagrammo:source
```mermaid
%%| renderer: swimlane
%%| theme: portal
%%| title: Limited impact
%%| subtitle: Inspiration only. A degraded optional dependency does not reduce the parent state.
%%| name: scenario-7-impact-lever-standard-to-limited
%%| alt: Degraded Automation dependency with Limited impact while Management stays healthy
%%| lanes: [Platform, Domains, Components]
flowchart BT
  runbookSignal["Runbook success signal<br/>state: Degraded"] --&gt; automation["Automation<br/>state: Degraded"]
  automation -. "Limited impact" .-> management["Management<br/>state: Healthy"]
  workspace["Log Analytics<br/>state: Healthy"] --&gt; management
  management --&gt; platform["Platform<br/>state: Healthy"]

  classDef blue fill:#eff6fc,stroke:#0078D4;
  classDef green fill:#f2f8f2,stroke:#a0d8a0;
  classDef amber fill:#fbf2e7,stroke:#db7500;
  class runbookSignal blue;
  class automation amber;
  class workspace,management,platform green;
```
-->
<!-- /diagrammo:sync scenario-7-impact-lever-standard-to-limited -->

## Learn more

Azure Monitor health models documentation on Microsoft Learn:

- [Health models overview](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/overview)
- [Health model concepts](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/concepts)
- [Signals](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/signals)
- [Configure health rollup](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/rollup)
- [Create discovery rules](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/discoveries)
- [Create a health model](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/create)
- [Configure a health model with the designer](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/designer)
- [Monitor a health model](https://learn.microsoft.com/en-us/azure/azure-monitor/health-models/monitoring)
