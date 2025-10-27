param(
    [string]$LibraryRoot = (Join-Path $PSScriptRoot '../lib/alz'),
    [string]$ModulePath,
    [string[]]$ModuleNames,
    [switch]$All,
    [switch]$WhatIf
)

function Get-RelativePath {
    param(
        [string]$From,
        [string]$To
    )

    $relative = [System.IO.Path]::GetRelativePath($From, $To)
    return ($relative -replace '\\', '/')
}

function Get-LibraryFiles {
    param(
        [string]$LibraryRoot,
        [string]$ModuleDirectory
    )

    Get-ChildItem -Path $LibraryRoot -File -Recurse -Filter '*.json' | ForEach-Object {
        [PSCustomObject]@{
            FullName     = $_.FullName
            Name         = $_.Name
            RelativePath = Get-RelativePath -From $ModuleDirectory -To $_.FullName
        }
    }
}

function Format-ArrayLines {
    param(
        [array]$Files
    )

    $Files | Sort-Object RelativePath | ForEach-Object {
        "  loadJsonContent('$($_.RelativePath)')"
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
        [Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement },
        [Text.RegularExpressions.RegexOptions]::Singleline
    )
}

$libraryAliasMap = @{
    platform = @{
        mgmt = 'management'
    }
}

function Resolve-LibraryPath {
    param(
        [string]$BaseLibraryRoot,
        [string]$PrimarySegment,
        [string[]]$SubSegments,
        [hashtable]$AliasMap
    )

    if ($PrimarySegment -eq 'int-root') {
        $currentPath = $BaseLibraryRoot
    } else {
        $currentPath = Join-Path $BaseLibraryRoot $PrimarySegment
    }

    $currentPrefixBase = $PrimarySegment

    foreach ($segment in $SubSegments) {
        $normalized = [string]$segment
        $prefix = "$currentPrefixBase-"
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $normalized = $normalized.Substring($prefix.Length)
        }

        $normalizedLower = $normalized.ToLowerInvariant()
        if ($AliasMap.ContainsKey($PrimarySegment) -and $AliasMap[$PrimarySegment].ContainsKey($normalizedLower)) {
            $normalized = $AliasMap[$PrimarySegment][$normalizedLower]
            $normalizedLower = $normalized.ToLowerInvariant()
        }

        $currentPath = Join-Path $currentPath $normalized
        $currentPrefixBase = $normalized
    }

    return $currentPath
}

function New-ModuleTarget {
    param(
        [string]$ModuleMainPath,
        [string]$MgmtGroupsRoot,
        [string]$BaseLibraryRoot,
        [hashtable]$AliasMap
    )

    $resolvedModulePath = (Resolve-Path -Path $ModuleMainPath).Path
    $moduleDirectory = Split-Path -Parent $resolvedModulePath

    $relativeDirectory = Get-RelativePath -From $MgmtGroupsRoot -To $moduleDirectory
    if ($relativeDirectory.StartsWith('..')) {
        throw "Module path '$resolvedModulePath' is not within the management groups directory."
    }

    $segments = @()
    foreach ($part in ($relativeDirectory -split '[\\/]')) {
        if ([string]::IsNullOrWhiteSpace($part)) {
            continue
        }

        $segments += [string]$part
    }

    if (($segments.Count -gt 0) -and (([string]$segments[-1]).ToLowerInvariant() -eq 'main')) {
        if ($segments.Count -eq 1) {
            throw "Unable to derive module name from '$resolvedModulePath'."
        }

        $segments = $segments[0..($segments.Count - 2)]
    }

    if (-not $segments -or $segments.Count -eq 0) {
        throw "Unable to determine module hierarchy for '$resolvedModulePath'."
    }

    $primarySegment = [string]$segments[0]
    $subSegments = @()
    if ($segments.Count -gt 1) {
        $subSegments = $segments[1..($segments.Count - 1)]
    }

    $libraryRootCandidate = Resolve-LibraryPath -BaseLibraryRoot $BaseLibraryRoot -PrimarySegment $primarySegment -SubSegments $subSegments -AliasMap $AliasMap

    [PSCustomObject]@{
        Name          = [string]$segments[-1]
        RelativePath  = ([string]::Join('/', $segments))
        ModulePath    = $resolvedModulePath
        ModuleDirectory = $moduleDirectory
        LibraryRoot   = $libraryRootCandidate
    }
}

$baseLibraryRoot = (Resolve-Path -Path $LibraryRoot).Path
$mgmtGroupsRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '../mgmt-groups')).Path

$targets = @()

if ($ModulePath) {
    $targets += New-ModuleTarget -ModuleMainPath $ModulePath -MgmtGroupsRoot $mgmtGroupsRoot -BaseLibraryRoot $baseLibraryRoot -AliasMap $libraryAliasMap
} else {
    $moduleFiles = Get-ChildItem -Path $mgmtGroupsRoot -Recurse -Filter 'main.bicep' -File
    if (-not $moduleFiles) {
        Write-Warning 'No management group modules were found beneath the mgmt-groups directory.'
        return
    }

    $moduleEntries = @()
    foreach ($file in $moduleFiles) {
        try {
            $moduleEntries += New-ModuleTarget -ModuleMainPath $file.FullName -MgmtGroupsRoot $mgmtGroupsRoot -BaseLibraryRoot $baseLibraryRoot -AliasMap $libraryAliasMap
        } catch {
            Write-Warning $_.Exception.Message
        }
    }

    if (-not $moduleEntries) {
        Write-Warning 'No management group modules were selected after processing.'
        return
    }

    if ($ModuleNames -and -not $All) {
        $selectedEntries = @()

        foreach ($requestedName in $ModuleNames) {
            $normalizedRequest = ([string]($requestedName -replace '\\', '/')).ToLowerInvariant()
            $moduleMatches = $moduleEntries | Where-Object {
                ([string]$_.Name).ToLowerInvariant() -eq $normalizedRequest -or
                ([string]$_.RelativePath).ToLowerInvariant() -eq $normalizedRequest
            }

            if (-not $moduleMatches) {
                Write-Warning "Skipping '$requestedName' because no matching management group module was found."
                continue
            }

            $selectedEntries += $moduleMatches
        }

        $targets = $selectedEntries | Sort-Object RelativePath -Unique
    } else {
        $targets = $moduleEntries | Sort-Object RelativePath -Unique
    }
}

if (-not $targets -or $targets.Count -eq 0) {
    Write-Warning 'No management group modules were selected. Nothing to do.'
    return
}

foreach ($target in $targets) {
    $modulePath = $target.ModulePath
    $moduleName = $target.Name
    $libraryDirectory = $target.LibraryRoot
    $moduleDirectory = $target.ModuleDirectory

    if (-not (Test-Path -Path $moduleDirectory)) {
        Write-Warning "Skipping '$moduleName' because module directory '$moduleDirectory' was not found."
        continue
    }

    if (-not (Test-Path -Path $libraryDirectory)) {
        Write-Warning "Skipping '$moduleName' because library root '$libraryDirectory' was not found."
        continue
    }

    $libraryDirectoryResolved = (Resolve-Path -Path $libraryDirectory).Path

    $files = Get-LibraryFiles -LibraryRoot $libraryDirectoryResolved -ModuleDirectory $moduleDirectory

    $roleDefinitionFiles = $files | Where-Object { $_.Name -like '*.alz_role_definition.json' }
    $policyDefinitionFiles = $files | Where-Object { $_.Name -like '*.alz_policy_definition.json' }
    $policySetDefinitionFiles = $files | Where-Object { $_.Name -like '*.alz_policy_set_definition.json' }
    $policyAssignmentFiles = $files | Where-Object { $_.Name -like '*.alz_policy_assignment.json' }

    $roleLines = Format-ArrayLines -Files $roleDefinitionFiles
    $policyLines = Format-ArrayLines -Files $policyDefinitionFiles
    $policySetLines = Format-ArrayLines -Files $policySetDefinitionFiles
    $policyAssignmentLines = Format-ArrayLines -Files $policyAssignmentFiles

    $originalContent = Get-Content -Path $modulePath -Raw

    $newContent = $originalContent
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzRbacRoleDefsJson' -Lines $roleLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyDefsJson' -Lines $policyLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicySetDefsJson' -Lines $policySetLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyAssignmentsDefs' -Lines $policyAssignmentLines

    if ($WhatIf) {
        Write-Host "--- Module: $moduleName (WhatIf) ---"
        $diff = Compare-Object -ReferenceObject ($originalContent -split "`r`n") -DifferenceObject ($newContent -split "`r`n") -PassThru
        if ($diff) {
            $diff
        } else {
            Write-Host 'No changes detected.'
        }
    } else {
        Set-Content -Path $modulePath -Value $newContent
        Write-Host "Updated module '$moduleName' using library '$libraryDirectoryResolved'."
    }
}
