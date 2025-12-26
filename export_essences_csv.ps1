# Export all Essences from original English file to CSV for translation

$originalPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\RawData\en-US\essences.json"
$thaiPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\essences.json"
$csvOutputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translation_essences_full.csv"

Write-Host "=== Exporting Essences to CSV ===" -ForegroundColor Cyan

# Read original English file
$originalJson = Get-Content -Path $originalPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Read Thai file if exists
$thaiJson = $null
if (Test-Path $thaiPath) {
    $thaiJson = Get-Content -Path $thaiPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

# Create CSV data
$csvData = @()

foreach ($key in $originalJson.PSObject.Properties.Name) {
    $original = $originalJson.$key
    
    # Get Thai translation if exists
    $thaiName = ""
    $thaiDesc = ""
    if ($thaiJson -and $thaiJson.PSObject.Properties.Name -contains $key) {
        $thaiName = $thaiJson.$key.name
        $thaiDesc = $thaiJson.$key.description
    }
    
    # Clean description - remove color tags and sprite tags for easier reading
    $cleanDesc = $original.description
    
    $csvData += [PSCustomObject]@{
        Key     = $key
        Name_EN = $original.name
        Name_TH = $thaiName
        Desc_EN = $cleanDesc
        Desc_TH = $thaiDesc
    }
}

# Export to CSV
$csvData | Export-Csv -Path $csvOutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Exported $($csvData.Count) essences to:" -ForegroundColor Green
Write-Host $csvOutputPath -ForegroundColor Yellow
