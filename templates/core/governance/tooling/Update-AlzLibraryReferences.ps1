param(
    [Alias('LibraryRoot')]
    [string]$AlzLibraryRoot = (Join-Path $PSScriptRoot '../lib/alz'),
    [string]$CustomerLibraryRoot = (Join-Path $PSScriptRoot '../lib/customer'),
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

function Get-LibraryRootCandidates {
    param(
        [string[]]$BaseLibraryRoots
    )

    $candidates = @()

    foreach ($root in $BaseLibraryRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        $resolved = Resolve-Path -Path $root -ErrorAction SilentlyContinue
        if ($resolved) {
            if ($candidates -notcontains $resolved.Path) {
                $candidates += $resolved.Path
            }

            continue
        }

        if ($candidates -notcontains $root) {
            $candidates += $root
        }
    }

    return $candidates
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
        [Text.RegularExpressions.MatchEvaluator] { param($m) $replacement },
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
        [string[]]$BaseLibraryRoots,
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

    $libraryRootCandidates = @()
    $baseRootCandidates = Get-LibraryRootCandidates -BaseLibraryRoots $BaseLibraryRoots
    if (-not $baseRootCandidates -or $baseRootCandidates.Count -eq 0) {
        $baseRootCandidates = $BaseLibraryRoots
    }

    foreach ($candidateBaseRoot in $baseRootCandidates) {
        if ([string]::IsNullOrWhiteSpace($candidateBaseRoot)) {
            continue
        }

        $resolvedCandidate = Resolve-LibraryPath -BaseLibraryRoot $candidateBaseRoot -PrimarySegment $primarySegment -SubSegments $subSegments -AliasMap $AliasMap
        if ($resolvedCandidate -and (Test-Path -Path $resolvedCandidate) -and ($libraryRootCandidates -notcontains $resolvedCandidate)) {
            $libraryRootCandidates += $resolvedCandidate
        }
    }

    if (-not $libraryRootCandidates) {
        foreach ($candidateBaseRoot in $BaseLibraryRoots) {
            if ([string]::IsNullOrWhiteSpace($candidateBaseRoot)) {
                continue
            }

            $fallbackCandidate = Resolve-LibraryPath -BaseLibraryRoot $candidateBaseRoot -PrimarySegment $primarySegment -SubSegments $subSegments -AliasMap $AliasMap
            if ($fallbackCandidate -and ($libraryRootCandidates -notcontains $fallbackCandidate)) {
                $libraryRootCandidates += $fallbackCandidate
                break
            }
        }
    }

    if (-not $libraryRootCandidates) {
        throw "Unable to resolve library root for module path '$resolvedModulePath'."
    }

    [PSCustomObject]@{
        Name            = [string]$segments[-1]
        RelativePath    = ([string]::Join('/', $segments))
        ModulePath      = $resolvedModulePath
        ModuleDirectory = $moduleDirectory
        LibraryRoot     = $libraryRootCandidates | Select-Object -First 1
        LibraryRoots    = $libraryRootCandidates
    }
}

$baseLibraryRoots = @()
foreach ($root in @($AlzLibraryRoot, $CustomerLibraryRoot)) {
    if ([string]::IsNullOrWhiteSpace($root)) {
        continue
    }

    if ($baseLibraryRoots -notcontains $root) {
        $baseLibraryRoots += $root
    }
}

if (-not $baseLibraryRoots) {
    Write-Warning 'No library roots were provided. Nothing to do.'
    return
}
$mgmtGroupsRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '../mgmt-groups')).Path

$targets = @()

if ($ModulePath) {
    $targets += New-ModuleTarget -ModuleMainPath $ModulePath -MgmtGroupsRoot $mgmtGroupsRoot -BaseLibraryRoots $baseLibraryRoots -AliasMap $libraryAliasMap
} else {
    $moduleFiles = Get-ChildItem -Path $mgmtGroupsRoot -Recurse -Filter 'main.bicep' -File
    if (-not $moduleFiles) {
        Write-Warning 'No management group modules were found beneath the mgmt-groups directory.'
        return
    }

    $moduleEntries = @()
    foreach ($file in $moduleFiles) {
        try {
            $moduleEntries += New-ModuleTarget -ModuleMainPath $file.FullName -MgmtGroupsRoot $mgmtGroupsRoot -BaseLibraryRoots $baseLibraryRoots -AliasMap $libraryAliasMap
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
    $moduleDirectory = $target.ModuleDirectory

    if (-not (Test-Path -Path $moduleDirectory)) {
        Write-Warning "Skipping '$moduleName' because module directory '$moduleDirectory' was not found."
        continue
    }

    $libraryDirectories = if ($target.PSObject.Properties['LibraryRoots']) { $target.LibraryRoots } else { @($target.LibraryRoot) }
    $resolvedLibraryDirectories = @()

    $files = @()
    foreach ($libraryDirectory in $libraryDirectories) {
        if (-not (Test-Path -Path $libraryDirectory)) {
            Write-Warning "Skipping library root '$libraryDirectory' for module '$moduleName' because it was not found."
            continue
        }

        $libraryDirectoryResolved = (Resolve-Path -Path $libraryDirectory).Path
        $resolvedLibraryDirectories += $libraryDirectoryResolved
        $files += Get-LibraryFiles -LibraryRoot $libraryDirectoryResolved -ModuleDirectory $moduleDirectory
    }

    if (-not $resolvedLibraryDirectories) {
        Write-Warning "Skipping '$moduleName' because no library roots were available."
        continue
    }

    $roleDefinitionFiles = $files | Where-Object { $_.Name -match 'role_definition\.json$' }
    $policyDefinitionFiles = $files | Where-Object { $_.Name -match 'policy_definition\.json$' }
    $policySetDefinitionFiles = $files | Where-Object { $_.Name -match 'policy_set_definition\.json$' }
    $policyAssignmentFiles = $files | Where-Object { $_.Name -match 'policy_assignment\.json$' }

    $roleLines = Format-ArrayLines -Files $roleDefinitionFiles
    $policyLines = Format-ArrayLines -Files $policyDefinitionFiles
    $policySetLines = Format-ArrayLines -Files $policySetDefinitionFiles
    $policyAssignmentLines = Format-ArrayLines -Files $policyAssignmentFiles

    $originalContent = Get-Content -Path $modulePath -Raw

    $newContent = $originalContent
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzRbacRoleDefsJson' -Lines $roleLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyDefsJson' -Lines $policyLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicySetDefsJson' -Lines $policySetLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyAssignmentsJson' -Lines $policyAssignmentLines

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
        Write-Host "Updated module '$moduleName' using library roots: $([string]::Join(', ', $resolvedLibraryDirectories))."
    }
}
