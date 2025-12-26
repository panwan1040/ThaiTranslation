# Add color and sprite tags to Thai translations
# Matches the formatting from original English descriptions

$originalPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\RawData\en-US\essences.json"
$thaiPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\essences.json"
$outputPath = $thaiPath

Write-Host "=== Adding Color and Sprite Tags ===" -ForegroundColor Cyan

# Read files
$originalJson = Get-Content -Path $originalPath -Raw -Encoding UTF8 | ConvertFrom-Json
$thaiJson = Get-Content -Path $thaiPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Process each essence
$output = [ordered]@{}

foreach ($key in $thaiJson.PSObject.Properties.Name) {
    $thaiData = $thaiJson.$key
    $newDesc = $thaiData.description
    
    if ($originalJson.PSObject.Properties.Name -contains $key) {
        $origDesc = $originalJson.$key.description
        
        # Check for sprite=1 (AP scaling) - add blue color to percentages
        if ($origDesc -match '<sprite=1>') {
            # Add sprite=1 and blue color to first percentage if not present
            $newDesc = $newDesc -replace '(\d+\.?\d*)%<sprite=5>', '<sprite=1><color=#16D7FF>$1%</color><sprite=5>'
        }
        
        # Check for sprite=2 (AD scaling) - add orange color
        if ($origDesc -match '<sprite=2>') {
            # For AD scaling, use orange color
            $newDesc = $newDesc -replace '(\d+\.?\d*)%<sprite=5>', '<sprite=2><color=#FF8A2D>$1%</color><sprite=5>'
        }
    }
    
    $output[$key] = @{
        name        = $thaiData.name
        description = $newDesc
    }
}

# Convert to JSON and save
$jsonString = $output | ConvertTo-Json -Depth 10

# Fix the escaped unicode back to proper tags
$jsonString = $jsonString -replace '\\u003c', '<'
$jsonString = $jsonString -replace '\\u003e', '>'

[System.IO.File]::WriteAllText($outputPath, $jsonString, [System.Text.Encoding]::UTF8)

Write-Host "Saved with color tags to: $outputPath" -ForegroundColor Green
