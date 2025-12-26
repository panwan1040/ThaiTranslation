# Export memories to CSV for translation
# Run this in PowerShell

$inputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\RawData\en-US\memories.json"
$outputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translation_memories.csv"

$json = Get-Content $inputPath -Raw -Encoding UTF8 | ConvertFrom-Json

$output = @()

foreach ($prop in $json.PSObject.Properties) {
    $key = $prop.Name
    $val = $prop.Value
    
    # Clean up description - remove rich text tags
    $desc = $val.description
    if ($desc) {
        $desc = $desc -replace '<[^>]+>', ''
        $desc = $desc -replace '\r?\n', ' [NEWLINE] '
    }
    
    # Clean up lore
    $lore = $val.lore
    if ($lore) {
        $lore = $lore -replace '\r?\n', ' [NEWLINE] '
    }
    
    $item = [PSCustomObject]@{
        Key = $key
        Name_EN = $val.name
        Name_TH = ""
        ShortDesc_EN = $val.shortDescription
        ShortDesc_TH = ""
        Desc_EN = $desc
        Desc_TH = ""
        Lore_EN = $lore
        Lore_TH = ""
        AchievementName_EN = $val.achievementName
        AchievementName_TH = ""
        AchievementDesc_EN = $val.achievementDescription
        AchievementDesc_TH = ""
    }
    
    $output += $item
}

$output | Export-Csv -Path $outputPath -Encoding UTF8 -NoTypeInformation

Write-Host "Exported $($output.Count) items to: $outputPath"
