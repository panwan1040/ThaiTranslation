# Import all translated CSVs and create JSON files
# Run this script to generate all translation JSON files

$basePath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation"

# Function to import and create JSON
function Import-TranslationCSV {
    param(
        [string]$CsvPath,
        [string]$JsonPath,
        [string]$Type
    )
    
    Write-Host "Processing: $Type" -ForegroundColor Cyan
    
    $csv = Import-Csv -Path $CsvPath -Encoding UTF8
    $output = @{}
    
    foreach ($row in $csv) {
        $key = $row.Key
        
        # Skip if no Thai translation at all
        $hasTranslation = $false
        foreach ($prop in $row.PSObject.Properties) {
            if ($prop.Name -like "*_TH" -and $prop.Value) {
                $hasTranslation = $true
                break
            }
        }
        
        if (-not $hasTranslation) { continue }
        
        $entry = @{}
        
        # Handle different file types
        switch ($Type) {
            "memories" {
                if ($row.Name_TH) { $entry["name"] = $row.Name_TH }
                if ($row.ShortDesc_TH) { $entry["shortDescription"] = $row.ShortDesc_TH }
                if ($row.Desc_TH) { 
                    $desc = $row.Desc_TH -replace ' \[NEWLINE\] ', "`n"
                    $entry["description"] = $desc 
                }
                if ($row.Lore_TH) { 
                    $lore = $row.Lore_TH -replace ' \[NEWLINE\] ', "`n"
                    $entry["lore"] = $lore 
                }
                if ($row.AchievementName_TH) { $entry["achievementName"] = $row.AchievementName_TH }
                if ($row.AchievementDesc_TH) { $entry["achievementDescription"] = $row.AchievementDesc_TH }
            }
            "essences" {
                if ($row.Name_TH) { $entry["name"] = $row.Name_TH }
                if ($row.Desc_TH) { 
                    $desc = $row.Desc_TH -replace ' \[NEWLINE\] ', "`n"
                    $entry["description"] = $desc 
                }
            }
            "stars" {
                if ($row.Name_TH) { $entry["name"] = $row.Name_TH }
                if ($row.Desc_TH) { 
                    $desc = $row.Desc_TH -replace ' \[NEWLINE\] ', "`n"
                    $entry["description"] = $desc 
                }
                if ($row.Lore_TH) { 
                    $lore = $row.Lore_TH -replace ' \[NEWLINE\] ', "`n"
                    $entry["lore"] = $lore 
                }
            }
            "achievements" {
                if ($row.Name_TH) { $entry["name"] = $row.Name_TH }
                if ($row.Desc_TH) { 
                    $desc = $row.Desc_TH -replace ' \[NEWLINE\] ', "`n"
                    $entry["description"] = $desc 
                }
            }
        }
        
        if ($entry.Count -gt 0) {
            # Add with original key
            $output[$key] = $entry.Clone()
            
            # For memories: also add without St_ prefix (for GetSkillDescription)
            if ($Type -eq "memories" -and $key.StartsWith("St_")) {
                $keyNoPrefix = $key.Substring(3)
                $output[$keyNoPrefix] = $entry.Clone()
            }
        }
    }
    
    # Convert to JSON with proper formatting
    $jsonString = $output | ConvertTo-Json -Depth 10
    
    # Write to file with UTF8 encoding
    [System.IO.File]::WriteAllText($JsonPath, $jsonString, [System.Text.Encoding]::UTF8)
    
    Write-Host "  Created: $JsonPath" -ForegroundColor Green
    Write-Host "  Entries: $($output.Count)" -ForegroundColor Yellow
}

# Process each file
Import-TranslationCSV -CsvPath "$basePath\translation_memories.csv" -JsonPath "$basePath\RawData\th-TH\memories.json" -Type "memories"
Import-TranslationCSV -CsvPath "$basePath\translation_essences.csv" -JsonPath "$basePath\RawData\th-TH\essences.json" -Type "essences"
Import-TranslationCSV -CsvPath "$basePath\translation_stars.csv" -JsonPath "$basePath\RawData\th-TH\stars.json" -Type "stars"
Import-TranslationCSV -CsvPath "$basePath\translation_achievements.csv" -JsonPath "$basePath\RawData\th-TH\achievements.json" -Type "achievements"

Write-Host "`nAll translations imported successfully!" -ForegroundColor Green
