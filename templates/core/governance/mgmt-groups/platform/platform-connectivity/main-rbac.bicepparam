using './main-rbac.bicep'

param parCorpManagementGroupName = '{{management_group_id_prefix}}{{management_group_corp_id||corp}}{{management_group_id_postfix}}'
param parConnectivityManagementGroupName = '{{management_group_id_prefix}}{{management_group_connectivity_id||connectivity}}{{management_group_id_postfix}}'
param parManagementGroupExcludedPolicyAssignments = []
param parEnableTelemetry = true
