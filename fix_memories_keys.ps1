# Fix duplicated keys (St_ prefix mismatch) in memories.json (Fixed Iteration)
# Copies colored translation from "St_Key" to "Key" so the game picks up the correct one.

$thPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\memories.json"

Write-Host "Syncing St_ prefixed entries..." -ForegroundColor Cyan

if (-not (Test-Path $thPath)) { Write-Error "File not found"; exit }

$json = Get-Content -Path $thPath -Raw -Encoding UTF8 | ConvertFrom-Json
$output = [ordered]@{}

# First pass: Copy all existing data to a mutable dictionary
foreach ($key in $json.PSObject.Properties.Name) {
    # Manual copy to ordered dictionary
    $entry = $json.$key
    $newEntry = [ordered]@{}
    foreach ($prop in $entry.PSObject.Properties) {
        $newEntry[$prop.Name] = $prop.Value
    }
    $output[$key] = $newEntry
}

$syncCount = 0

# Second pass: Sync data
# Create a static list of keys to iterate over to avoid modification errors
$keys = @($output.Keys)

foreach ($key in $keys) {
    if ($key -like "St_*") {
        $shortKey = $key.Substring(3) # Remove "St_"
        
        # Check if the short key exists in the dataset
        if ($output.Contains($shortKey)) {
            # Copy data from St_Key to ShortKey
            
            $source = $output[$key]
            $target = $output[$shortKey]
            
            # Sync key fields
            if ($source.Contains("description") -and $source.description) { $target["description"] = $source.description }
            if ($source.Contains("shortDescription") -and $source.shortDescription) { $target["shortDescription"] = $source.shortDescription }
            if ($source.Contains("name") -and $source.name) { $target["name"] = $source.name }
            if ($source.Contains("lore") -and $source.lore) { $target["lore"] = $source.lore }
            
            # Update the output dictionary with the modified target
            $output[$shortKey] = $target
            
            Write-Host "Synced: $key -> $shortKey" -ForegroundColor Gray
            $syncCount++
        }
    }
}

Write-Host "Synced $syncCount entries." -ForegroundColor Green

# Verify St_C_GlacialStomp sync
if ($output.Contains("C_GlacialStomp")) {
    $desc = $output["C_GlacialStomp"]["description"]
    if ($desc -match "<color=") {
        Write-Host "Verification PASSED: C_GlacialStomp now has color tags." -ForegroundColor Green
    }
    else {
        Write-Warning "Verification FAILED: C_GlacialStomp still has no color tags!"
        Write-Warning "Current value: $desc"
    }
}
else {
    Write-Warning "Key C_GlacialStomp not found in output."
}

# Save
$jsonString = $output | ConvertTo-Json -Depth 10
$jsonString = $jsonString -replace '\\u003c', '<'
$jsonString = $jsonString -replace '\\u003e', '>'

[System.IO.File]::WriteAllText($thPath, $jsonString, [System.Text.Encoding]::UTF8)
