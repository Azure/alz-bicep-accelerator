# Define input directories (relative to script location)
$baseDir = Join-Path $PSScriptRoot "..\..\templates\core\lib"
$policyDefDir = Join-Path $baseDir "policy_definitions"
$policySetDefDir = Join-Path $baseDir "policy_set_definitions"

# Define output files (alongside the script)
$policyDefOut = Join-Path $PSScriptRoot "alzCustomPolicyDefsJson.bicep"
$policySetDefOut = Join-Path $PSScriptRoot "alzCustomPolicySetDefsJson.bicep"

# Function to generate a Bicep list
function New-PolicyVarList {
    param (
        [string]$inputDir,
        [string]$outputFile,
        [string]$relativePathPrefix,
        [string]$varName
    )

    $files = Get-ChildItem -Path $inputDir -Filter "*.json"
    $lines = @()
    $lines += "var $varName = ["

    foreach ($file in $files) {
        $relativePath = "$relativePathPrefix/$($file.Name)".Replace("\", "/")
        $lines += "  loadJsonContent('$relativePath')"
    }

    $lines += "]"

    $lines | Set-Content -Path $outputFile -Encoding UTF8
    Write-Host "✅ Bicep block written to $outputFile"
}

# Generate output files
New-PolicyVarList -inputDir $policyDefDir -outputFile $policyDefOut -relativePathPrefix "../lib/policy_definitions" -varName "alzCustomPolicyDefsJson"
New-PolicyVarList -inputDir $policySetDefDir -outputFile $policySetDefOut -relativePathPrefix "../lib/policy_set_definitions" -varName "alzCustomPolicySetDefsJson"
