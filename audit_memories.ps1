$jsonPath = "RawData\th-TH\memories.json"
if (-not (Test-Path $jsonPath)) {
    Write-Error "File not found: $jsonPath"
    exit
}

$jsonInfo = Get-Content $jsonPath -Raw | ConvertFrom-Json
$missingTranslations = @()

# Function to check if text has Thai characters
function Has-Thai($text) {
    return $text -match "[\u0E00-\u0E7F]"
}

# Iterate through all keys
foreach ($key in $jsonInfo.PSObject.Properties.Name) {
    # Skip St_ keys to focus on what the game uses (since we synced them)
    # Actually, let's check EVERYTHING just in case
    
    $item = $jsonInfo.$key
    
    $fieldsToCheck = @("name", "description", "shortDescription", "lore", "achievementName", "achievementDescription")
    
    foreach ($field in $fieldsToCheck) {
        if ($item.PSObject.Properties.Name -contains $field) {
            $value = $item.$field
            
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                # If it has NO Thai characters AND has English characters (to avoid signs/numbers)
                if (-not (Has-Thai $value) -and ($value -match "[a-zA-Z]")) {
                    $missingTranslations += "[Key: $key] [Field: $field] -> $value"
                }
            }
        }
    }
}

if ($missingTranslations.Count -eq 0) {
    Write-Host "Great! No untranslated entries found (based on Thai character check)." -ForegroundColor Green
}
else {
    Write-Host "Found $($missingTranslations.Count) potentially untranslated entries:" -ForegroundColor Yellow
    $missingTranslations | ForEach-Object { Write-Host $_ }
}
