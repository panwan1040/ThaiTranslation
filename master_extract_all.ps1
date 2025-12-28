# ============================================================================
# MASTER CSV EXTRACTOR for Shape of Dreams Thai Translation
# Version 2.0 - Extracts ALL translatable content to CSV files
# ============================================================================
# This script extracts all translatable text from the game's JSON files
# and creates CSV files ready for translation.
# ============================================================================

param(
    [string]$GamePath = "d:\SteamLibrary\steamapps\common\Shape of Dreams",
    [string]$OutputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translations"
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Shape of Dreams - Master CSV Extractor   " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to escape CSV fields
function Escape-CsvField {
    param([string]$field)
    if ([string]::IsNullOrEmpty($field)) { return "" }
    # Replace newlines with \n for CSV storage
    $field = $field -replace "`r`n", "\n"
    $field = $field -replace "`n", "\n"
    # If contains comma, quote, or newline marker, wrap in quotes
    if ($field -match '[,"\n]' -or $field.Contains('\n')) {
        $field = '"' + ($field -replace '"', '""') + '"'
    }
    return $field
}

# Helper function to preserve rich text tags
function Get-CleanDesc {
    param([string]$desc)
    if ([string]::IsNullOrEmpty($desc)) { return "" }
    return $desc
}

# ============================================================================
# EXTRACT MEMORIES
# ============================================================================
Write-Host "[1/5] Extracting MEMORIES..." -ForegroundColor Yellow

$memoriesPath = Join-Path $GamePath "RawData\en-US\memories.json"
$memoriesJson = Get-Content $memoriesPath -Raw -Encoding UTF8 | ConvertFrom-Json

$memoriesCsv = @()
$memoriesCsv += "Key,Name_EN,Name_TH,ShortDesc_EN,ShortDesc_TH,Desc_EN,Desc_TH,RawDesc_EN,RawDesc_TH,Lore_EN,Lore_TH,Rarity,Type,Tags,Traveler,CooldownTime,AchievementName_EN,AchievementName_TH,AchievementDesc_EN,AchievementDesc_TH"

$memoryCount = 0
foreach ($prop in $memoriesJson.PSObject.Properties) {
    $key = $prop.Name
    $data = $prop.Value
    
    $name = Escape-CsvField $data.name
    $shortDesc = Escape-CsvField $data.shortDescription
    $desc = Escape-CsvField $data.description
    $rawDesc = Escape-CsvField $data.rawDesc
    $lore = Escape-CsvField $data.lore
    $rarity = $data.rarity
    $type = $data.type
    $tags = if ($data.tags) { ($data.tags -join ";") } else { "" }
    $traveler = $data.traveler
    $cooldown = $data.cooldownTime
    $achName = Escape-CsvField $data.achievementName
    $achDesc = Escape-CsvField $data.achievementDescription
    
    $memoriesCsv += "$key,$name,,$shortDesc,,$desc,,$rawDesc,,$lore,,$rarity,$type,$tags,$traveler,$cooldown,$achName,,$achDesc,"
    $memoryCount++
}

$memoriesCsv | Out-File (Join-Path $OutputPath "memories_full.csv") -Encoding UTF8
Write-Host "   -> Extracted $memoryCount memories" -ForegroundColor Green

# ============================================================================
# EXTRACT ESSENCES
# ============================================================================
Write-Host "[2/5] Extracting ESSENCES..." -ForegroundColor Yellow

$essencesPath = Join-Path $GamePath "RawData\en-US\essences.json"
$essencesJson = Get-Content $essencesPath -Raw -Encoding UTF8 | ConvertFrom-Json

$essencesCsv = @()
$essencesCsv += "Key,Name_EN,Name_TH,Desc_EN,Desc_TH,RawDesc_EN,RawDesc_TH,Lore_EN,Lore_TH,Rarity,Tags,AchievementName_EN,AchievementName_TH,AchievementDesc_EN,AchievementDesc_TH"

$essenceCount = 0
foreach ($prop in $essencesJson.PSObject.Properties) {
    $key = $prop.Name
    $data = $prop.Value
    
    $name = Escape-CsvField $data.name
    $desc = Escape-CsvField $data.description
    $rawDesc = Escape-CsvField $data.rawDesc
    $lore = Escape-CsvField $data.lore
    $rarity = $data.rarity
    $tags = if ($data.tags) { ($data.tags -join ";") } else { "" }
    $achName = Escape-CsvField $data.achievementName
    $achDesc = Escape-CsvField $data.achievementDescription
    
    $essencesCsv += "$key,$name,,$desc,,$rawDesc,,$lore,,$rarity,$tags,$achName,,$achDesc,"
    $essenceCount++
}

$essencesCsv | Out-File (Join-Path $OutputPath "essences_full.csv") -Encoding UTF8
Write-Host "   -> Extracted $essenceCount essences" -ForegroundColor Green

# ============================================================================
# EXTRACT STARS
# ============================================================================
Write-Host "[3/5] Extracting STARS..." -ForegroundColor Yellow

$starsPath = Join-Path $GamePath "RawData\en-US\stars.json"
$starsJson = Get-Content $starsPath -Raw -Encoding UTF8 | ConvertFrom-Json

$starsCsv = @()
$starsCsv += "Key,Name_EN,Name_TH,Desc_EN,Desc_TH,RawDesc_EN,RawDesc_TH,Lore_EN,Lore_TH,Category,HeroType,MaxLevel"

$starCount = 0
foreach ($prop in $starsJson.PSObject.Properties) {
    $key = $prop.Name
    $data = $prop.Value
    
    $name = Escape-CsvField $data.name
    $desc = Escape-CsvField $data.description
    $rawDesc = Escape-CsvField $data.rawDesc
    $lore = Escape-CsvField $data.lore
    $category = $data.category
    $heroType = $data.heroType
    $maxLevel = $data.maxLevel
    
    $starsCsv += "$key,$name,,$desc,,$rawDesc,,$lore,,$category,$heroType,$maxLevel"
    $starCount++
}

$starsCsv | Out-File (Join-Path $OutputPath "stars_full.csv") -Encoding UTF8
Write-Host "   -> Extracted $starCount stars" -ForegroundColor Green

# ============================================================================
# EXTRACT TRAVELERS
# ============================================================================
Write-Host "[4/5] Extracting TRAVELERS..." -ForegroundColor Yellow

$travelersPath = Join-Path $GamePath "RawData\en-US\travelers.json"
$travelersJson = Get-Content $travelersPath -Raw -Encoding UTF8 | ConvertFrom-Json

$travelersCsv = @()
$travelersCsv += "Key,Name_EN,Name_TH,Subtitle_EN,Subtitle_TH,Desc_EN,Desc_TH,AchievementName_EN,AchievementName_TH,AchievementDesc_EN,AchievementDesc_TH"

$travelerCount = 0
foreach ($prop in $travelersJson.PSObject.Properties) {
    $key = $prop.Name
    $data = $prop.Value
    
    $name = Escape-CsvField $data.name
    $subtitle = Escape-CsvField $data.subtitle
    $desc = Escape-CsvField $data.description
    $achName = Escape-CsvField $data.achievementName
    $achDesc = Escape-CsvField $data.achievementDescription
    
    $travelersCsv += "$key,$name,,$subtitle,,$desc,,$achName,,$achDesc,"
    $travelerCount++
}

$travelersCsv | Out-File (Join-Path $OutputPath "travelers_full.csv") -Encoding UTF8
Write-Host "   -> Extracted $travelerCount travelers" -ForegroundColor Green

# ============================================================================
# EXTRACT ACHIEVEMENTS
# ============================================================================
Write-Host "[5/5] Extracting ACHIEVEMENTS..." -ForegroundColor Yellow

$achievementsPath = Join-Path $GamePath "RawData\en-US\achievements.json"
$achievementsJson = Get-Content $achievementsPath -Raw -Encoding UTF8 | ConvertFrom-Json

$achievementsCsv = @()
$achievementsCsv += "Key,Name_EN,Name_TH,Desc_EN,Desc_TH,MaxCount,Unlocks"

$achievementCount = 0
foreach ($prop in $achievementsJson.PSObject.Properties) {
    $key = $prop.Name
    $data = $prop.Value
    
    $name = Escape-CsvField $data.name
    $desc = Escape-CsvField $data.description
    $max = $data.max
    $unlocked = $data.unlocked
    
    $achievementsCsv += "$key,$name,,$desc,,$max,$unlocked"
    $achievementCount++
}

$achievementsCsv | Out-File (Join-Path $OutputPath "achievements_full.csv") -Encoding UTF8
Write-Host "   -> Extracted $achievementCount achievements" -ForegroundColor Green

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "            EXTRACTION COMPLETE            " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total items extracted:" -ForegroundColor White
Write-Host "  - Memories:     $memoryCount" -ForegroundColor Gray
Write-Host "  - Essences:     $essenceCount" -ForegroundColor Gray
Write-Host "  - Stars:        $starCount" -ForegroundColor Gray
Write-Host "  - Travelers:    $travelerCount" -ForegroundColor Gray
Write-Host "  - Achievements: $achievementCount" -ForegroundColor Gray
Write-Host ""
Write-Host "CSVs saved to: $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: CSV columns with '_TH' suffix are for Thai translations." -ForegroundColor Yellow
Write-Host "Fill in those columns and run 'master_import_csv.ps1' to generate JSON." -ForegroundColor Yellow
