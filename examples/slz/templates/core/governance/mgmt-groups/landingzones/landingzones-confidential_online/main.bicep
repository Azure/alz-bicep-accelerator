metadata name = 'ALZ Bicep - Landing Zones-Confidential Online Module'
metadata description = 'ALZ Bicep Module used to deploy the Landing Zones-Confidential Online Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Landing Zones-Confidential Online.')
param landingZonesConfidentialOnlineConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

@description('Optional. Policy assignment parameter overrides. Specify only the policy parameter values you want to override (currently no policies assigned to this management group). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

var alzRbacRoleDefsJson = [
]

var alzPolicyDefsJson = [
]

var alzPolicySetDefsJson = [
]

var alzPolicyAssignmentsJson = [
  loadJsonContent('../../../lib/alz/landingzones/confidential_online/Enforce-Sov-L2-CMKM.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/confidential_online/Enforce-Sov-L2-CMKP.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/confidential_online/Enforce-Sov-L2-HTTPS.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/confidential_online/Enforce-Sov-L2-TLS.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/confidential_online/Enforce-Sov-L3-Conf.alz_policy_assignment.json')
]

var managementGroupFinalName = landingZonesConfidentialOnlineConfig.?managementGroupName ?? 'online'
var intRootManagementGroupFinalName = landingZonesConfidentialOnlineConfig.?managementGroupIntermediateRootName ?? 'alz'

var alzPolicyAssignmentsWithOverrides = [
  for policyAssignment in alzPolicyAssignmentsJson: union(
    policyAssignment,
    contains(parPolicyAssignmentParameterOverrides, policyAssignment.name)
      ? {
          location: parPolicyAssignmentParameterOverrides[policyAssignment.name].?location ?? parLocations[0]
          identity: policyAssignment.?identity
          properties: union(
            policyAssignment.properties,
            parPolicyAssignmentParameterOverrides[policyAssignment.name].?scope != null
              ? {
                  scope: parPolicyAssignmentParameterOverrides[policyAssignment.name].scope
                }
              : {
                  scope: '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}'
                },
            contains(parPolicyAssignmentParameterOverrides[policyAssignment.name], 'parameters')
              ? {
                  parameters: union(
                    policyAssignment.properties.?parameters ?? {},
                    parPolicyAssignmentParameterOverrides[policyAssignment.name].parameters
                  )
                }
              : {},
            contains(
                parPolicyAssignmentParameterOverrides[policyAssignment.name],
                'additionalSubscriptionIDsToAssignRbacTo'
              )
              ? {
                  additionalSubscriptionIDsToAssignRbacTo: parPolicyAssignmentParameterOverrides[policyAssignment.name].additionalSubscriptionIDsToAssignRbacTo
                }
              : {},
            {
              policyDefinitionId: replace(
                replace(
                  policyAssignment.properties.policyDefinitionId,
                  '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}/',
                  '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
                ),
                '/providers/Microsoft.Management/managementGroups/alz/',
                '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
              )
            }
          )
        }
      : {
          location: parLocations[0]
          identity: policyAssignment.?identity
          properties: union(
            policyAssignment.properties,
            {
              scope: '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}'
            },
            {
              policyDefinitionId: replace(
                replace(
                  policyAssignment.properties.policyDefinitionId,
                  '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}/',
                  '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
                ),
                '/providers/Microsoft.Management/managementGroups/alz/',
                '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
              )
            }
          )
        }
  )
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, landingZonesConfidentialOnlineConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, landingZonesConfidentialOnlineConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, landingZonesConfidentialOnlineConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(
  alzPolicyAssignmentsWithOverrides,
  landingZonesConfidentialOnlineConfig.?customerPolicyAssignments ?? []
)

var unionedPolicyAssignmentNames = [for policyAssignment in unionedPolicyAssignments: policyAssignment.name]

var deduplicatedPolicyAssignments = filter(
  unionedPolicyAssignments,
  (policyAssignment, index) => index == indexOf(unionedPolicyAssignmentNames, policyAssignment.name)
)

var allRbacRoleDefs = [
  for roleDef in unionedRbacRoleDefs: {
    name: roleDef.name
    roleName: replace(roleDef.properties.roleName, '(alz)', '(${managementGroup().name})')
    description: roleDef.properties.description
    actions: roleDef.properties.permissions[0].actions
    notActions: roleDef.properties.permissions[0].notActions
    dataActions: roleDef.properties.permissions[0].dataActions
    notDataActions: roleDef.properties.permissions[0].notDataActions
  }
]

var allPolicyDefs = [
  for policy in unionedPolicyDefs: {
    name: policy.name
    properties: {
      description: policy.properties.description
      displayName: policy.properties.displayName
      metadata: policy.properties.metadata
      parameters: policy.properties.parameters
      policyType: policy.properties.policyType
    }
  }
]

var allPolicySetDefinitions = [
  for policySet in unionedPolicySetDefs: {
    name: policySet.name
    properties: {
      description: policySet.properties.description
      displayName: policySet.properties.displayName
      metadata: policySet.properties.metadata
      parameters: policySet.properties.parameters
      policyType: policySet.properties.policyType
      version: policySet.properties.version
      policyDefinitions: policySet.properties.policyDefinitions
    }
  }
]

var allPolicyAssignments = [
  for policyAssignment in deduplicatedPolicyAssignments: {
    name: policyAssignment.name
    displayName: policyAssignment.properties.?displayName
    description: policyAssignment.properties.?description
    policyDefinitionId: policyAssignment.properties.policyDefinitionId
    parameters: policyAssignment.properties.?parameters
    parameterOverrides: policyAssignment.properties.?parameterOverrides
    identity: policyAssignment.identity.?type ?? 'None'
    userAssignedIdentityId: policyAssignment.properties.?userAssignedIdentityId
    roleDefinitionIds: policyAssignment.properties.?roleDefinitionIds
    nonComplianceMessages: policyAssignment.properties.?nonComplianceMessages
    metadata: policyAssignment.properties.?metadata
    enforcementMode: policyAssignment.properties.?enforcementMode ?? 'Default'
    notScopes: policyAssignment.properties.?notScopes
    location: policyAssignment.?location
    overrides: policyAssignment.properties.?overrides
    resourceSelectors: policyAssignment.properties.?resourceSelectors
    definitionVersion: policyAssignment.properties.?definitionVersion
    additionalManagementGroupsIDsToAssignRbacTo: policyAssignment.properties.?additionalManagementGroupsIDsToAssignRbacTo
    additionalSubscriptionIDsToAssignRbacTo: policyAssignment.properties.?additionalSubscriptionIDsToAssignRbacTo
    additionalResourceGroupResourceIDsToAssignRbacTo: policyAssignment.properties.?additionalResourceGroupResourceIDsToAssignRbacTo
  }
]

// ============ //
//   Resources  //
// ============ //

module landingZonesConfidentialOnline 'br/public:avm/ptn/alz/empty:0.3.6' = {
  params: {
    createOrUpdateManagementGroup: landingZonesConfidentialOnlineConfig.?createOrUpdateManagementGroup
    managementGroupName: managementGroupFinalName
    managementGroupDisplayName: landingZonesConfidentialOnlineConfig.?managementGroupDisplayName ?? 'Online'
    managementGroupDoNotEnforcePolicyAssignments: landingZonesConfidentialOnlineConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: landingZonesConfidentialOnlineConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: landingZonesConfidentialOnlineConfig.?managementGroupParentId ?? 'landingzones'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: landingZonesConfidentialOnlineConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: landingZonesConfidentialOnlineConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: landingZonesConfidentialOnlineConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: landingZonesConfidentialOnlineConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: landingZonesConfidentialOnlineConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: landingZonesConfidentialOnlineConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: landingZonesConfidentialOnlineConfig.?waitForConsistencyCounterBeforeRoleAssignments
    waitForConsistencyCounterBeforeSubPlacement: landingZonesConfidentialOnlineConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../../alzCoreType.bicep'

