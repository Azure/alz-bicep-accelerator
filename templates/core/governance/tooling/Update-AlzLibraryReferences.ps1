#Requires -Version 7.0

<#
.SYNOPSIS
    Dynamically updates ALZ library references in Bicep modules based on the ALZ library directory structure.

.DESCRIPTION
    This script scans the ALZ library directory and updates the four key variables in main.bicep files:
    - alzRbacRoleDefsJson
    - alzPolicyDefsJson
    - alzPolicySetDefsJson
    - alzPolicyAssignmentsJson

    The script provides detailed, color-coded output showing exactly what files and variables will be updated.
    It dynamically maps directory structures:
    - lib/alz/ (root) → mgmt-groups/int-root/
    - lib/alz/platform/ → mgmt-groups/platform/
    - lib/alz/platform/identity/ → mgmt-groups/platform/platform-identity/
    - lib/alz/landingzones/ → mgmt-groups/landingzones/
    - lib/alz/sandbox/ → mgmt-groups/sandbox/

.PARAMETER AlzLibraryRoot
    Path to the ALZ library root directory. Defaults to '../lib/alz' relative to the script location.

.PARAMETER MgmtGroupsRoot
    Path to the management groups root directory. Defaults to '../mgmt-groups' relative to the script location.

.PARAMETER ModulePath
    Optional. Specific module path to update. If not specified, all modules will be processed.

.PARAMETER WhatIf
    Show what changes would be made without actually making them.

.EXAMPLE
    .\Update-AlzLibraryReferences.ps1
    Updates all modules using default paths with dynamic directory mapping.

.EXAMPLE
    .\Update-AlzLibraryReferences.ps1 -WhatIf
    Shows what would be updated without making changes.

.EXAMPLE
    .\Update-AlzLibraryReferences.ps1 -AlzLibraryRoot "C:\Custom\ALZ\Path" -WhatIf
    Uses a custom ALZ library path and shows changes.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$AlzLibraryRoot = (Join-Path $PSScriptRoot '../lib/alz'),

    [Parameter()]
    [string]$MgmtGroupsRoot = (Join-Path $PSScriptRoot '../mgmt-groups'),

    [Parameter()]
    [string]$ModulePath,

    [Parameter()]
    [switch]$WhatIf
)

# Color configuration for output
$ColorConfig = @{
    Header    = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
    Variable  = 'Magenta'
    FileName  = 'Blue'
    Unchanged = 'Gray'
    Changed   = 'Green'
    Added     = 'Green'
    Removed   = 'Red'
}

function Write-ColoredMessage {
    param(
        [string]$Message,
        [string]$Color = 'White',
        [switch]$NoNewline
    )

    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-RelativePath {
    param(
        [string]$From,
        [string]$To
    )

    $relative = [System.IO.Path]::GetRelativePath($From, $To)
    return ($relative -replace '\\', '/')
}

function Get-ModuleLibraryPath {
    param(
        [string]$ModulePath,
        [string]$AlzLibraryRoot,
        [string]$MgmtGroupsRoot
    )

    $moduleDirectory = Split-Path -Parent $ModulePath
    $relativePath = Get-RelativePath -From $MgmtGroupsRoot -To $moduleDirectory

    # Parse the relative path segments
    $splitParts = $relativePath -split '[\\/]'
    $segments = @($splitParts | Where-Object { $_ -and $_ -ne '.' })

    if (-not $segments -or $segments.Count -eq 0) {
        throw "Unable to determine module hierarchy for '$ModulePath'"
    }

    # Map management group structure to ALZ library structure
    $libraryPath = $AlzLibraryRoot

    switch ($segments[0]) {
        'int-root' {
            # int-root maps to the root ALZ library directory
            $libraryPath = $AlzLibraryRoot
        }
        'platform' {
            if ($segments.Count -eq 1) {
                # platform root maps to platform directory
                $libraryPath = Join-Path $AlzLibraryRoot 'platform'
            } else {
                # platform subdirectories: platform-identity -> platform/identity
                $subModule = $segments[1] -replace '^platform-', ''
                $libraryPath = Join-Path $AlzLibraryRoot "platform/$subModule"
            }
        }
        'landingzones' {
            if ($segments.Count -eq 1) {
                # landingzones root maps to landingzones directory
                $libraryPath = Join-Path $AlzLibraryRoot 'landingzones'
            } else {
                # landingzones subdirectories: landingzones-corp -> landingzones/corp
                $subModule = $segments[1] -replace '^landingzones-', ''
                $libraryPath = Join-Path $AlzLibraryRoot "landingzones/$subModule"
            }
        }
        'sandbox' {
            $libraryPath = Join-Path $AlzLibraryRoot 'sandbox'
        }
        'decommissioned' {
            $libraryPath = Join-Path $AlzLibraryRoot 'decommissioned'
        }
        default {
            Write-ColoredMessage "  ⚠ Unknown module type '$($segments[0])' - using root ALZ library" $ColorConfig.Warning
            $libraryPath = $AlzLibraryRoot
        }
    }

    return $libraryPath
}

function Get-AlzLibraryFiles {
    param(
        [string]$ModulePath,
        [string]$AlzLibraryRoot,
        [string]$MgmtGroupsRoot
    )

    $moduleDirectory = Split-Path -Parent $ModulePath

    # Get the specific library path for this module
    $libraryPath = Get-ModuleLibraryPath -ModulePath $ModulePath -AlzLibraryRoot $AlzLibraryRoot -MgmtGroupsRoot $MgmtGroupsRoot

    Write-ColoredMessage "  📁 Library Path: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$libraryPath" $ColorConfig.FileName

    if (-not (Test-Path $libraryPath)) {
        Write-ColoredMessage "  ⚠ ALZ library path not found: $libraryPath" $ColorConfig.Warning
        return @{
            RoleDefinitions      = @()
            PolicyDefinitions    = @()
            PolicySetDefinitions = @()
            PolicyAssignments    = @()
        }
    }

    $files = @{
        RoleDefinitions      = @()
        PolicyDefinitions    = @()
        PolicySetDefinitions = @()
        PolicyAssignments    = @()
    }

    # Get JSON files in the library path (no subdirectories)
    Get-ChildItem -Path $libraryPath -File -Filter '*.json' | ForEach-Object {
        $relativePath = Get-RelativePath -From $moduleDirectory -To $_.FullName
        $fileInfo = @{
            FullName     = $_.FullName
            Name         = $_.Name
            RelativePath = $relativePath
        }

        switch -Regex ($_.Name) {
            '\.alz_role_definition\.json$' {
                $files.RoleDefinitions += $fileInfo
            }
            '\.alz_policy_definition\.json$' {
                $files.PolicyDefinitions += $fileInfo
            }
            '\.alz_policy_set_definition\.json$' {
                $files.PolicySetDefinitions += $fileInfo
            }
            '\.alz_policy_assignment\.json$' {
                $files.PolicyAssignments += $fileInfo
            }
        }
    }

    # Sort files by relative path for consistent ordering
    $files.RoleDefinitions = $files.RoleDefinitions | Sort-Object RelativePath
    $files.PolicyDefinitions = $files.PolicyDefinitions | Sort-Object RelativePath
    $files.PolicySetDefinitions = $files.PolicySetDefinitions | Sort-Object RelativePath
    $files.PolicyAssignments = $files.PolicyAssignments | Sort-Object RelativePath

    # Display file counts for transparency
    Write-ColoredMessage "  📊 Files Found: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "Roles: $($files.RoleDefinitions.Count)" $ColorConfig.Success -NoNewline
    Write-ColoredMessage " | " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "Policies: $($files.PolicyDefinitions.Count)" $ColorConfig.Success -NoNewline
    Write-ColoredMessage " | " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "PolicySets: $($files.PolicySetDefinitions.Count)" $ColorConfig.Success -NoNewline
    Write-ColoredMessage " | " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "Assignments: $($files.PolicyAssignments.Count)" $ColorConfig.Success

    return $files
}

function Format-ArrayLines {
    param(
        [array]$Files
    )

    if (-not $Files -or $Files.Count -eq 0) {
        return @()
    }

    return $Files | Where-Object { $_.RelativePath } | ForEach-Object {
        "  loadJsonContent('$($_.RelativePath)')"
    }
}

function Get-ArrayBlock {
    param(
        [string]$Content,
        [string]$VariableName
    )

    $pattern = "(?s)var\s+$([Regex]::Escape($VariableName))\s*=\s*\[(.*?)\]"
    $match = [Regex]::Match($Content, $pattern)

    if (-not $match.Success) {
        return $null
    }

    $arrayContent = $match.Groups[1].Value.TrimEnd()
    $lines = @()

    if (-not [string]::IsNullOrWhiteSpace($arrayContent)) {
        $lines = $arrayContent -split "`r?`n" | ForEach-Object {
            $_.TrimEnd()
        } | Where-Object { $_ -and $_ -ne '' }
    }

    return @{
        FullMatch  = $match.Value
        Lines      = $lines
        StartIndex = $match.Index
        Length     = $match.Length
    }
}

function Set-ArrayBlock {
    param(
        [string]$Content,
        [string]$VariableName,
        [array]$Lines
    )

    $pattern = "(?s)var\s+$([Regex]::Escape($VariableName))\s*=\s*\[(.*?)\]"
    if (-not [Regex]::IsMatch($Content, $pattern)) {
        throw "Unable to locate array declaration for '$VariableName'."
    }

    $replacement = "var $VariableName = [`r`n"
    if ($Lines.Count -gt 0) {
        $replacement += ($Lines -join "`r`n") + "`r`n"
    }
    $replacement += "]"

    return [Regex]::Replace(
        $Content,
        $pattern,
        [Text.RegularExpressions.MatchEvaluator] { param($m) $replacement },
        [Text.RegularExpressions.RegexOptions]::Singleline
    )
}

function Compare-ArrayContent {
    param(
        [array]$Original,
        [array]$New,
        [string]$VariableName
    )

    $changes = @{
        HasChanges = $false
        Added      = @()
        Removed    = @()
        Unchanged  = @()
    }

    # Find added items
    $changes.Added = $New | Where-Object { $_ -notin $Original }

    # Find removed items
    $changes.Removed = $Original | Where-Object { $_ -notin $New }

    # Find unchanged items
    $changes.Unchanged = $Original | Where-Object { $_ -in $New }

    $changes.HasChanges = ($changes.Added.Count -gt 0) -or ($changes.Removed.Count -gt 0)

    return $changes
}

function Show-VariableChanges {
    param(
        [object]$Changes,
        [string]$VariableName,
        [string]$ModuleName
    )

    if (-not $Changes.HasChanges) {
        Write-ColoredMessage "    ✓ " $ColorConfig.Success -NoNewline
        Write-ColoredMessage "$VariableName" $ColorConfig.Variable -NoNewline
        Write-ColoredMessage " - No changes needed" $ColorConfig.Unchanged
        return
    }

    Write-ColoredMessage "    ● " $ColorConfig.Changed -NoNewline
    Write-ColoredMessage "$VariableName" $ColorConfig.Variable -NoNewline
    Write-ColoredMessage " - Changes detected:" $ColorConfig.Info

    if ($Changes.Added.Count -gt 0) {
        Write-ColoredMessage "      + Added ($($Changes.Added.Count) items):" $ColorConfig.Added
        $Changes.Added | ForEach-Object {
            $line = $_ -replace "^\s*loadJsonContent\('([^']+)'\).*", '$1'
            Write-ColoredMessage "        $line" $ColorConfig.Added
        }
    }

    if ($Changes.Removed.Count -gt 0) {
        Write-ColoredMessage "      - Removed ($($Changes.Removed.Count) items):" $ColorConfig.Removed
        $Changes.Removed | ForEach-Object {
            $line = $_ -replace "^\s*loadJsonContent\('([^']+)'\).*", '$1'
            Write-ColoredMessage "        $line" $ColorConfig.Removed
        }
    }

    if ($Changes.Unchanged.Count -gt 0) {
        Write-ColoredMessage "      = Unchanged ($($Changes.Unchanged.Count) items)" $ColorConfig.Unchanged
    }
}

function Update-ModuleReferences {
    param(
        [string]$ModulePath,
        [object]$LibraryFiles,
        [bool]$WhatIfMode
    )

    $moduleName = Split-Path -Leaf (Split-Path -Parent $ModulePath)

    Write-ColoredMessage "`n═══════════════════════════════════════════════════════════════" $ColorConfig.Header
    Write-ColoredMessage " Processing Module: " $ColorConfig.Header -NoNewline
    Write-ColoredMessage "$moduleName" $ColorConfig.FileName
    Write-ColoredMessage " Path: " $ColorConfig.Header -NoNewline
    Write-ColoredMessage "$ModulePath" $ColorConfig.Info
    Write-ColoredMessage "═══════════════════════════════════════════════════════════════" $ColorConfig.Header

    if (-not (Test-Path $ModulePath)) {
        Write-ColoredMessage "  ✗ Module file not found!" $ColorConfig.Error
        return $false
    }

    try {
        $originalContent = Get-Content -Path $ModulePath -Raw

        # Generate new content for each variable
        $roleLines = Format-ArrayLines -Files $LibraryFiles.RoleDefinitions
        $policyLines = Format-ArrayLines -Files $LibraryFiles.PolicyDefinitions
        $policySetLines = Format-ArrayLines -Files $LibraryFiles.PolicySetDefinitions
        $policyAssignmentLines = Format-ArrayLines -Files $LibraryFiles.PolicyAssignments

        # Get current content for each variable
        $currentRoles = Get-ArrayBlock -Content $originalContent -VariableName 'alzRbacRoleDefsJson'
        $currentPolicies = Get-ArrayBlock -Content $originalContent -VariableName 'alzPolicyDefsJson'
        $currentPolicySets = Get-ArrayBlock -Content $originalContent -VariableName 'alzPolicySetDefsJson'
        $currentPolicyAssignments = Get-ArrayBlock -Content $originalContent -VariableName 'alzPolicyAssignmentsJson'

        if (-not ($currentRoles -and $currentPolicies -and $currentPolicySets -and $currentPolicyAssignments)) {
            Write-ColoredMessage "  ✗ Unable to locate all required variable declarations in the module." $ColorConfig.Error
            return $false
        }

        # Compare changes for each variable
        $roleChanges = Compare-ArrayContent -Original $currentRoles.Lines -New $roleLines -VariableName 'alzRbacRoleDefsJson'
        $policyChanges = Compare-ArrayContent -Original $currentPolicies.Lines -New $policyLines -VariableName 'alzPolicyDefsJson'
        $policySetChanges = Compare-ArrayContent -Original $currentPolicySets.Lines -New $policySetLines -VariableName 'alzPolicySetDefsJson'
        $policyAssignmentChanges = Compare-ArrayContent -Original $currentPolicyAssignments.Lines -New $policyAssignmentLines -VariableName 'alzPolicyAssignmentsJson'

        $hasAnyChanges = $roleChanges.HasChanges -or $policyChanges.HasChanges -or $policySetChanges.HasChanges -or $policyAssignmentChanges.HasChanges

        # Show changes for each variable
        Write-ColoredMessage "  Variable Analysis:" $ColorConfig.Info
        Show-VariableChanges -Changes $roleChanges -VariableName 'alzRbacRoleDefsJson' -ModuleName $moduleName
        Show-VariableChanges -Changes $policyChanges -VariableName 'alzPolicyDefsJson' -ModuleName $moduleName
        Show-VariableChanges -Changes $policySetChanges -VariableName 'alzPolicySetDefsJson' -ModuleName $moduleName
        Show-VariableChanges -Changes $policyAssignmentChanges -VariableName 'alzPolicyAssignmentsJson' -ModuleName $moduleName

        if (-not $hasAnyChanges) {
            Write-ColoredMessage "`n  ✓ No changes needed - module is already up to date!" $ColorConfig.Success
            return $true
        }

        if ($WhatIfMode) {
            Write-ColoredMessage "`n  ▶ " $ColorConfig.Warning -NoNewline
            Write-ColoredMessage "WhatIf Mode: Module would be updated" $ColorConfig.Warning
        } else {
            # Apply changes
            $newContent = $originalContent
            $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzRbacRoleDefsJson' -Lines $roleLines
            $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyDefsJson' -Lines $policyLines
            $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicySetDefsJson' -Lines $policySetLines
            $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyAssignmentsJson' -Lines $policyAssignmentLines

            Set-Content -Path $ModulePath -Value $newContent -Encoding UTF8
            Write-ColoredMessage "`n  ✓ Module successfully updated!" $ColorConfig.Success
        }

        return $true

    } catch {
        Write-ColoredMessage "`n  ✗ Error processing module: $($_.Exception.Message)" $ColorConfig.Error
        return $false
    }
}

# Main script execution
try {
    $scriptStartTime = Get-Date

    Write-ColoredMessage "╔═══════════════════════════════════════════════════════════════╗" $ColorConfig.Header
    Write-ColoredMessage "║              ALZ Library Reference Update Tool              ║" $ColorConfig.Header
    Write-ColoredMessage "║              (Dynamic Directory Mapping)                    ║" $ColorConfig.Header
    Write-ColoredMessage "╚═══════════════════════════════════════════════════════════════╝" $ColorConfig.Header

    if ($WhatIf) {
        Write-ColoredMessage "`n🔍 Running in WhatIf mode - no changes will be made`n" $ColorConfig.Warning
    }

    # Resolve and validate paths
    $alzLibraryPath = Resolve-Path -Path $AlzLibraryRoot -ErrorAction SilentlyContinue
    if (-not $alzLibraryPath) {
        Write-ColoredMessage "Error: ALZ library root not found: $AlzLibraryRoot" $ColorConfig.Error
        exit 1
    }

    $mgmtGroupsPath = Resolve-Path -Path $MgmtGroupsRoot -ErrorAction SilentlyContinue
    if (-not $mgmtGroupsPath) {
        Write-ColoredMessage "Error: Management groups root not found: $MgmtGroupsRoot" $ColorConfig.Error
        exit 1
    }

    Write-ColoredMessage "Configuration:" $ColorConfig.Info
    Write-ColoredMessage "  ALZ Library Root: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$alzLibraryPath" $ColorConfig.FileName
    Write-ColoredMessage "  Mgmt Groups Root: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$mgmtGroupsPath" $ColorConfig.FileName
    Write-ColoredMessage "  Dynamic Mapping: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "Enabled" $ColorConfig.Success

    # Find all main.bicep files or use specific module path
    $moduleFiles = @()
    if ($ModulePath) {
        if (Test-Path $ModulePath) {
            $moduleFiles = @(Get-Item $ModulePath)
        } else {
            Write-ColoredMessage "Error: Specified module path not found: $ModulePath" $ColorConfig.Error
            exit 1
        }
    } else {
        $moduleFiles = Get-ChildItem -Path $mgmtGroupsPath -Recurse -Filter 'main.bicep' -File
    }

    if (-not $moduleFiles -or $moduleFiles.Count -eq 0) {
        Write-ColoredMessage "No main.bicep files found to process." $ColorConfig.Warning
        exit 0
    }

    Write-ColoredMessage "  Modules Found: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$($moduleFiles.Count)" $ColorConfig.Success

    # Process each module
    $processedCount = 0
    $updatedCount = 0
    $errorCount = 0

    foreach ($moduleFile in $moduleFiles) {
        # Get library files for this specific module using dynamic path mapping
        $libraryFiles = Get-AlzLibraryFiles -ModulePath $moduleFile.FullName -AlzLibraryRoot $alzLibraryPath -MgmtGroupsRoot $mgmtGroupsPath

        $success = Update-ModuleReferences -ModulePath $moduleFile.FullName -LibraryFiles $libraryFiles -WhatIfMode $WhatIf

        $processedCount++
        if ($success) {
            $updatedCount++
        } else {
            $errorCount++
        }
    }

    # Summary
    $scriptEndTime = Get-Date
    $duration = $scriptEndTime - $scriptStartTime

    Write-ColoredMessage "`n╔═══════════════════════════════════════════════════════════════╗" $ColorConfig.Header
    Write-ColoredMessage "║                           SUMMARY                           ║" $ColorConfig.Header
    Write-ColoredMessage "╚═══════════════════════════════════════════════════════════════╝" $ColorConfig.Header

    Write-ColoredMessage "  Modules Processed: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$processedCount" $ColorConfig.Success

    Write-ColoredMessage "  Modules Updated: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$updatedCount" $ColorConfig.Success

    if ($errorCount -gt 0) {
        Write-ColoredMessage "  Modules with Errors: " $ColorConfig.Info -NoNewline
        Write-ColoredMessage "$errorCount" $ColorConfig.Error
    }

    Write-ColoredMessage "  Duration: " $ColorConfig.Info -NoNewline
    Write-ColoredMessage "$([math]::Round($duration.TotalSeconds, 2)) seconds" $ColorConfig.Success

    if ($WhatIf) {
        Write-ColoredMessage "`n💡 Run without -WhatIf to apply these changes." $ColorConfig.Warning
    }

    Write-ColoredMessage "`n🎯 Dynamic Directory Mapping Applied Successfully!" $ColorConfig.Success

} catch {
    Write-ColoredMessage "Fatal error: $($_.Exception.Message)" $ColorConfig.Error
    exit 1
}
