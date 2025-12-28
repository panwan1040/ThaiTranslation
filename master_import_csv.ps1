# ============================================================================
# MASTER CSV IMPORTER for Shape of Dreams Thai Translation
# Version 2.0 - Imports translated CSV files back to JSON format
# ============================================================================
# This script reads CSV files with Thai translations and generates
# JSON files for the mod to use.
# ============================================================================

param(
    [string]$CsvPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translations",
    [string]$GamePath = "d:\SteamLibrary\steamapps\common\Shape of Dreams",
    [string]$OutputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH"
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Shape of Dreams - Master CSV Importer    " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to unescape CSV fields
function Unescape-CsvField {
    param([string]$field)
    if ([string]::IsNullOrEmpty($field)) { return $null }
    # Restore newlines
    $field = $field -replace '\\n', "`n"
    return $field
}

# Helper function to build JSON with proper escaping
function ConvertTo-JsonManual {
    param([hashtable]$data, [int]$indent = 0)
    
    $json = "{"
    $first = $true
    $indentStr = "  " * $indent
    $innerIndent = "  " * ($indent + 1)
    
    foreach ($key in $data.Keys | Sort-Object) {
        if (-not $first) { $json += "," }
        $first = $false
        $json += "`n$innerIndent`"$key`": "
        
        $value = $data[$key]
        if ($null -eq $value) {
            $json += "null"
        }
        elseif ($value -is [hashtable]) {
            $json += (ConvertTo-JsonManual $value ($indent + 1))
        }
        elseif ($value -is [array]) {
            $json += (ConvertTo-Json $value -Compress)
        }
        elseif ($value -is [bool]) {
            $json += $value.ToString().ToLower()
        }
        elseif ($value -is [int] -or $value -is [double]) {
            $json += $value
        }
        else {
            # String - escape special chars
            $escaped = $value.ToString() -replace '\\', '\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`t", '\t'
            $json += "`"$escaped`""
        }
    }
    
    $json += "`n$indentStr}"
    return $json
}

# ============================================================================
# IMPORT MEMORIES
# ============================================================================
Write-Host "[1/5] Importing MEMORIES..." -ForegroundColor Yellow

$memoriesCsvFile = Join-Path $CsvPath "memories_full.csv"
$memoriesEnPath = Join-Path $GamePath "RawData\en-US\memories.json"

if (Test-Path $memoriesCsvFile) {
    $memoriesEn = Get-Content $memoriesEnPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $memoriesCsv = Import-Csv $memoriesCsvFile -Encoding UTF8
    
    $memoriesOut = @{}
    $memTranslated = 0
    $memTotal = 0
    
    foreach ($row in $memoriesCsv) {
        $key = $row.Key
        $memTotal++
        
        # Check if we have Thai translations
        $hasTranslation = $false
        $entry = @{}
        
        # Name
        if (-not [string]::IsNullOrWhiteSpace($row.Name_TH)) {
            $entry["name"] = Unescape-CsvField $row.Name_TH
            $hasTranslation = $true
        }
        else {
            $entry["name"] = $row.Name_EN
        }
        
        # Short Description
        if (-not [string]::IsNullOrWhiteSpace($row.ShortDesc_TH)) {
            $entry["shortDescription"] = Unescape-CsvField $row.ShortDesc_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.ShortDesc_EN)) {
            $entry["shortDescription"] = $row.ShortDesc_EN
        }
        
        # Description - use translated version if available
        if (-not [string]::IsNullOrWhiteSpace($row.Desc_TH)) {
            $entry["description"] = Unescape-CsvField $row.Desc_TH
            $hasTranslation = $true
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Desc_EN)) {
            $entry["description"] = Unescape-CsvField $row.Desc_EN
        }
        
        # RawDesc with placeholders - IMPORTANT for dynamic values
        if (-not [string]::IsNullOrWhiteSpace($row.RawDesc_TH)) {
            $entry["rawDesc"] = Unescape-CsvField $row.RawDesc_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.RawDesc_EN)) {
            $entry["rawDesc"] = Unescape-CsvField $row.RawDesc_EN
        }
        
        # Copy rawDescVars from original (these are the dynamic calculation values)
        if ($memoriesEn.$key -and $memoriesEn.$key.rawDescVars) {
            $entry["rawDescVars"] = $memoriesEn.$key.rawDescVars
        }
        
        # Lore
        if (-not [string]::IsNullOrWhiteSpace($row.Lore_TH)) {
            $entry["lore"] = Unescape-CsvField $row.Lore_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Lore_EN)) {
            $entry["lore"] = Unescape-CsvField $row.Lore_EN
        }
        else {
            $entry["lore"] = $null
        }
        
        if ($hasTranslation) { $memTranslated++ }
        $memoriesOut[$key] = $entry
    }
    
    $memoriesJson = $memoriesOut | ConvertTo-Json -Depth 10
    $memoriesJson | Out-File (Join-Path $OutputPath "memories.json") -Encoding UTF8
    Write-Host "   -> Imported $memTotal memories ($memTranslated translated)" -ForegroundColor Green
}
else {
    Write-Host "   -> memories_full.csv not found, skipping" -ForegroundColor Gray
}

# ============================================================================
# IMPORT ESSENCES
# ============================================================================
Write-Host "[2/5] Importing ESSENCES..." -ForegroundColor Yellow

$essencesCsvFile = Join-Path $CsvPath "essences_full.csv"
$essencesEnPath = Join-Path $GamePath "RawData\en-US\essences.json"

if (Test-Path $essencesCsvFile) {
    $essencesEn = Get-Content $essencesEnPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $essencesCsv = Import-Csv $essencesCsvFile -Encoding UTF8
    
    $essencesOut = @{}
    $essTranslated = 0
    $essTotal = 0
    
    foreach ($row in $essencesCsv) {
        $key = $row.Key
        $essTotal++
        
        $hasTranslation = $false
        $entry = @{}
        
        # Name
        if (-not [string]::IsNullOrWhiteSpace($row.Name_TH)) {
            $entry["name"] = Unescape-CsvField $row.Name_TH
            $hasTranslation = $true
        }
        else {
            $entry["name"] = $row.Name_EN
        }
        
        # Description
        if (-not [string]::IsNullOrWhiteSpace($row.Desc_TH)) {
            $entry["description"] = Unescape-CsvField $row.Desc_TH
            $hasTranslation = $true
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Desc_EN)) {
            $entry["description"] = Unescape-CsvField $row.Desc_EN
        }
        
        # RawDesc
        if (-not [string]::IsNullOrWhiteSpace($row.RawDesc_TH)) {
            $entry["rawDesc"] = Unescape-CsvField $row.RawDesc_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.RawDesc_EN)) {
            $entry["rawDesc"] = Unescape-CsvField $row.RawDesc_EN
        }
        
        # Copy rawDescVars from original
        if ($essencesEn.$key -and $essencesEn.$key.rawDescVars) {
            $entry["rawDescVars"] = $essencesEn.$key.rawDescVars
        }
        
        # Lore
        if (-not [string]::IsNullOrWhiteSpace($row.Lore_TH)) {
            $entry["lore"] = Unescape-CsvField $row.Lore_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Lore_EN)) {
            $entry["lore"] = Unescape-CsvField $row.Lore_EN
        }
        else {
            $entry["lore"] = $null
        }
        
        if ($hasTranslation) { $essTranslated++ }
        $essencesOut[$key] = $entry
    }
    
    $essencesJson = $essencesOut | ConvertTo-Json -Depth 10
    $essencesJson | Out-File (Join-Path $OutputPath "essences.json") -Encoding UTF8
    Write-Host "   -> Imported $essTotal essences ($essTranslated translated)" -ForegroundColor Green
}
else {
    Write-Host "   -> essences_full.csv not found, skipping" -ForegroundColor Gray
}

# ============================================================================
# IMPORT STARS
# ============================================================================
Write-Host "[3/5] Importing STARS..." -ForegroundColor Yellow

$starsCsvFile = Join-Path $CsvPath "stars_full.csv"
$starsEnPath = Join-Path $GamePath "RawData\en-US\stars.json"

if (Test-Path $starsCsvFile) {
    $starsEn = Get-Content $starsEnPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $starsCsv = Import-Csv $starsCsvFile -Encoding UTF8
    
    $starsOut = @{}
    $starTranslated = 0
    $starTotal = 0
    
    foreach ($row in $starsCsv) {
        $key = $row.Key
        $starTotal++
        
        $hasTranslation = $false
        $entry = @{}
        
        # Name
        if (-not [string]::IsNullOrWhiteSpace($row.Name_TH)) {
            $entry["name"] = Unescape-CsvField $row.Name_TH
            $hasTranslation = $true
        }
        else {
            $entry["name"] = $row.Name_EN
        }
        
        # Description
        if (-not [string]::IsNullOrWhiteSpace($row.Desc_TH)) {
            $entry["description"] = Unescape-CsvField $row.Desc_TH
            $hasTranslation = $true
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Desc_EN)) {
            $entry["description"] = Unescape-CsvField $row.Desc_EN
        }
        
        # RawDesc
        if (-not [string]::IsNullOrWhiteSpace($row.RawDesc_TH)) {
            $entry["rawDesc"] = Unescape-CsvField $row.RawDesc_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.RawDesc_EN)) {
            $entry["rawDesc"] = Unescape-CsvField $row.RawDesc_EN
        }
        
        # Copy rawDescVars from original
        if ($starsEn.$key -and $starsEn.$key.rawDescVars) {
            $entry["rawDescVars"] = $starsEn.$key.rawDescVars
        }
        
        # Lore
        if (-not [string]::IsNullOrWhiteSpace($row.Lore_TH)) {
            $entry["lore"] = Unescape-CsvField $row.Lore_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Lore_EN)) {
            $entry["lore"] = Unescape-CsvField $row.Lore_EN
        }
        else {
            $entry["lore"] = $null
        }
        
        if ($hasTranslation) { $starTranslated++ }
        $starsOut[$key] = $entry
    }
    
    $starsJson = $starsOut | ConvertTo-Json -Depth 10
    $starsJson | Out-File (Join-Path $OutputPath "stars.json") -Encoding UTF8
    Write-Host "   -> Imported $starTotal stars ($starTranslated translated)" -ForegroundColor Green
}
else {
    Write-Host "   -> stars_full.csv not found, skipping" -ForegroundColor Gray
}

# ============================================================================
# IMPORT TRAVELERS
# ============================================================================
Write-Host "[4/5] Importing TRAVELERS..." -ForegroundColor Yellow

$travelersCsvFile = Join-Path $CsvPath "travelers_full.csv"

if (Test-Path $travelersCsvFile) {
    $travelersCsv = Import-Csv $travelersCsvFile -Encoding UTF8
    
    $travelersOut = @{}
    $travTranslated = 0
    $travTotal = 0
    
    foreach ($row in $travelersCsv) {
        $key = $row.Key
        $travTotal++
        
        $hasTranslation = $false
        $entry = @{}
        
        # Name
        if (-not [string]::IsNullOrWhiteSpace($row.Name_TH)) {
            $entry["name"] = Unescape-CsvField $row.Name_TH
            $hasTranslation = $true
        }
        else {
            $entry["name"] = $row.Name_EN
        }
        
        # Subtitle
        if (-not [string]::IsNullOrWhiteSpace($row.Subtitle_TH)) {
            $entry["subtitle"] = Unescape-CsvField $row.Subtitle_TH
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Subtitle_EN)) {
            $entry["subtitle"] = Unescape-CsvField $row.Subtitle_EN
        }
        
        # Description
        if (-not [string]::IsNullOrWhiteSpace($row.Desc_TH)) {
            $entry["description"] = Unescape-CsvField $row.Desc_TH
            $hasTranslation = $true
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Desc_EN)) {
            $entry["description"] = Unescape-CsvField $row.Desc_EN
        }
        
        if ($hasTranslation) { $travTranslated++ }
        $travelersOut[$key] = $entry
    }
    
    $travelersJson = $travelersOut | ConvertTo-Json -Depth 10
    $travelersJson | Out-File (Join-Path $OutputPath "travelers.json") -Encoding UTF8
    Write-Host "   -> Imported $travTotal travelers ($travTranslated translated)" -ForegroundColor Green
}
else {
    Write-Host "   -> travelers_full.csv not found, skipping" -ForegroundColor Gray
}

# ============================================================================
# IMPORT ACHIEVEMENTS
# ============================================================================
Write-Host "[5/5] Importing ACHIEVEMENTS..." -ForegroundColor Yellow

$achievementsCsvFile = Join-Path $CsvPath "achievements_full.csv"

if (Test-Path $achievementsCsvFile) {
    $achievementsCsv = Import-Csv $achievementsCsvFile -Encoding UTF8
    
    $achievementsOut = @{}
    $achTranslated = 0
    $achTotal = 0
    
    foreach ($row in $achievementsCsv) {
        $key = $row.Key
        $achTotal++
        
        $hasTranslation = $false
        $entry = @{}
        
        # Name
        if (-not [string]::IsNullOrWhiteSpace($row.Name_TH)) {
            $entry["name"] = Unescape-CsvField $row.Name_TH
            $hasTranslation = $true
        }
        else {
            $entry["name"] = $row.Name_EN
        }
        
        # Description
        if (-not [string]::IsNullOrWhiteSpace($row.Desc_TH)) {
            $entry["description"] = Unescape-CsvField $row.Desc_TH
            $hasTranslation = $true
        }
        elseif (-not [string]::IsNullOrWhiteSpace($row.Desc_EN)) {
            $entry["description"] = Unescape-CsvField $row.Desc_EN
        }
        
        if ($hasTranslation) { $achTranslated++ }
        $achievementsOut[$key] = $entry
    }
    
    $achievementsJson = $achievementsOut | ConvertTo-Json -Depth 10
    $achievementsJson | Out-File (Join-Path $OutputPath "achievements.json") -Encoding UTF8
    Write-Host "   -> Imported $achTotal achievements ($achTranslated translated)" -ForegroundColor Green
}
else {
    Write-Host "   -> achievements_full.csv not found, skipping" -ForegroundColor Gray
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "             IMPORT COMPLETE               " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "JSON files saved to: $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Rebuild the mod DLL (if structure changed)" -ForegroundColor Gray
Write-Host "  2. Test in game!" -ForegroundColor Gray
