# Sync essences.json - add missing keys from original English file

$originalPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\RawData\en-US\essences.json"
$thaiPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\essences.json"
$csvPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translation_essences.csv"
$outputPath = $thaiPath

Write-Host "=== Syncing Essences ===" -ForegroundColor Cyan

# Read original English file
$originalJson = Get-Content -Path $originalPath -Raw -Encoding UTF8 | ConvertFrom-Json
$originalKeys = $originalJson.PSObject.Properties.Name
Write-Host "Original English keys: $($originalKeys.Count)" -ForegroundColor Yellow

# Read current Thai file
$thaiJson = Get-Content -Path $thaiPath -Raw -Encoding UTF8 | ConvertFrom-Json
$thaiKeys = $thaiJson.PSObject.Properties.Name
Write-Host "Current Thai keys: $($thaiKeys.Count)" -ForegroundColor Yellow

# Read CSV translations if available
$csvTranslations = @{}
if (Test-Path $csvPath) {
    $csv = Import-Csv -Path $csvPath -Encoding UTF8
    foreach ($row in $csv) {
        if ($row.Key -and ($row.Name_TH -or $row.Desc_TH)) {
            $csvTranslations[$row.Key] = @{
                name        = $row.Name_TH
                description = $row.Desc_TH -replace '\[NEWLINE\]', "`n"
            }
        }
    }
    Write-Host "CSV translations loaded: $($csvTranslations.Count)" -ForegroundColor Yellow
}

# Create output hashtable (ordered)
$output = [ordered]@{}

# Process all original keys
$added = 0
$updated = 0
$skipped = 0

foreach ($key in $originalKeys) {
    $original = $originalJson.$key
    
    # Check if we have Thai translation
    if ($thaiJson.PSObject.Properties.Name -contains $key) {
        # Keep existing Thai translation
        $output[$key] = @{
            name        = $thaiJson.$key.name
            description = $thaiJson.$key.description
        }
        $skipped++
    }
    elseif ($csvTranslations.ContainsKey($key)) {
        # Use CSV translation
        $output[$key] = @{
            name        = $csvTranslations[$key].name
            description = $csvTranslations[$key].description
        }
        $added++
        Write-Host "  Added from CSV: $key" -ForegroundColor Green
    }
    else {
        # Use English as fallback
        $output[$key] = @{
            name        = $original.name
            description = $original.description
        }
        $added++
        Write-Host "  Added (English fallback): $key" -ForegroundColor DarkYellow
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Kept existing: $skipped" -ForegroundColor Green
Write-Host "Added new: $added" -ForegroundColor Yellow
Write-Host "Total keys: $($output.Count)" -ForegroundColor Cyan

# Convert to JSON and save
$jsonString = $output | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outputPath, $jsonString, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Saved to: $outputPath" -ForegroundColor Green
