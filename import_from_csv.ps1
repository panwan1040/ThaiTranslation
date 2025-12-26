# Import translated CSV and create JSON
# Run this after filling in the _TH columns in the CSV

$inputCsv = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translation_memories.csv"
$outputJson = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\memories.json"

$csv = Import-Csv -Path $inputCsv -Encoding UTF8

$output = @{}

foreach ($row in $csv) {
    $key = $row.Key
    
    # Skip if no Thai translation
    if (-not $row.Name_TH -and -not $row.ShortDesc_TH -and -not $row.Desc_TH) {
        continue
    }
    
    # Create entry with St_ prefix (for GetSkillName)
    $entry = @{}
    
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
    
    if ($entry.Count -gt 0) {
        # Add with original key (for GetSkillName)
        $output[$key] = $entry.Clone()
        
        # Also add without St_ prefix (for GetSkillDescription)
        if ($key.StartsWith("St_")) {
            $keyNoPrefix = $key.Substring(3)
            $output[$keyNoPrefix] = $entry.Clone()
        }
    }
}

# Convert to JSON with proper formatting
$jsonString = $output | ConvertTo-Json -Depth 10

# Write to file
$jsonString | Out-File -FilePath $outputJson -Encoding UTF8

Write-Host "Created JSON with $($output.Count) entries at: $outputJson"
