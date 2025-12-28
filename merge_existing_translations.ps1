# ============================================================================
# MERGE EXISTING TRANSLATIONS into new CSV format
# Version 1.0 - Merges existing Thai translations into new full CSV
# ============================================================================
# This script takes the old translation CSVs and merges them into the new
# comprehensive format, so you don't lose any existing translations.
# ============================================================================

param(
    [string]$NewCsvPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\translations",
    [string]$OldCsvPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation"
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Merge Existing Thai Translations         " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# MERGE MEMORIES
# ============================================================================
Write-Host "[1/4] Merging MEMORIES translations..." -ForegroundColor Yellow

$newMemoriesPath = Join-Path $NewCsvPath "memories_full.csv"
$oldMemoriesPath = Join-Path $OldCsvPath "translation_memories.csv"

if ((Test-Path $newMemoriesPath) -and (Test-Path $oldMemoriesPath)) {
    $newMemories = Import-Csv $newMemoriesPath -Encoding UTF8
    $oldMemories = Import-Csv $oldMemoriesPath -Encoding UTF8
    
    # Create lookup from old translations
    $oldLookup = @{}
    foreach ($row in $oldMemories) {
        $key = $row.Key
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $oldLookup[$key] = $row
        }
    }
    
    $merged = 0
    foreach ($row in $newMemories) {
        $key = $row.Key
        if ($oldLookup.ContainsKey($key)) {
            $oldRow = $oldLookup[$key]
            
            # Merge Name
            if ($oldRow.PSObject.Properties.Name -contains "Name_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Name_TH)) {
                $row.Name_TH = $oldRow.Name_TH
            }
            # Merge ShortDesc
            if ($oldRow.PSObject.Properties.Name -contains "ShortDesc_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.ShortDesc_TH)) {
                $row.ShortDesc_TH = $oldRow.ShortDesc_TH
            }
            # Merge Desc - try multiple column names
            $descCol = $null
            if ($oldRow.PSObject.Properties.Name -contains "Desc_TH") { $descCol = "Desc_TH" }
            elseif ($oldRow.PSObject.Properties.Name -contains "Description_TH") { $descCol = "Description_TH" }
            if ($descCol -and -not [string]::IsNullOrWhiteSpace($oldRow.$descCol)) {
                $row.Desc_TH = $oldRow.$descCol
                $merged++
            }
            # Merge Lore
            if ($oldRow.PSObject.Properties.Name -contains "Lore_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Lore_TH)) {
                $row.Lore_TH = $oldRow.Lore_TH
            }
        }
    }
    
    $newMemories | Export-Csv $newMemoriesPath -Encoding UTF8 -NoTypeInformation
    Write-Host "   -> Merged $merged existing translations" -ForegroundColor Green
}
else {
    Write-Host "   -> Skipped (files not found)" -ForegroundColor Gray
}

# ============================================================================
# MERGE ESSENCES
# ============================================================================
Write-Host "[2/4] Merging ESSENCES translations..." -ForegroundColor Yellow

$newEssencesPath = Join-Path $NewCsvPath "essences_full.csv"
$oldEssencesPath = Join-Path $OldCsvPath "translation_essences.csv"

if ((Test-Path $newEssencesPath) -and (Test-Path $oldEssencesPath)) {
    $newEssences = Import-Csv $newEssencesPath -Encoding UTF8
    $oldEssences = Import-Csv $oldEssencesPath -Encoding UTF8
    
    $oldLookup = @{}
    foreach ($row in $oldEssences) {
        $key = $row.Key
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            # Handle key format with or without Gem_ prefix
            $fullKey = if ($key.StartsWith("Gem_")) { $key } else { "Gem_$key" }
            $oldLookup[$fullKey] = $row
            $oldLookup[$key] = $row
        }
    }
    
    $merged = 0
    foreach ($row in $newEssences) {
        $key = $row.Key
        if ($oldLookup.ContainsKey($key)) {
            $oldRow = $oldLookup[$key]
            
            if ($oldRow.PSObject.Properties.Name -contains "Name_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Name_TH)) {
                $row.Name_TH = $oldRow.Name_TH
            }
            $descCol = $null
            if ($oldRow.PSObject.Properties.Name -contains "Desc_TH") { $descCol = "Desc_TH" }
            elseif ($oldRow.PSObject.Properties.Name -contains "Description_TH") { $descCol = "Description_TH" }
            if ($descCol -and -not [string]::IsNullOrWhiteSpace($oldRow.$descCol)) {
                $row.Desc_TH = $oldRow.$descCol
                $merged++
            }
            if ($oldRow.PSObject.Properties.Name -contains "Lore_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Lore_TH)) {
                $row.Lore_TH = $oldRow.Lore_TH
            }
        }
    }
    
    $newEssences | Export-Csv $newEssencesPath -Encoding UTF8 -NoTypeInformation
    Write-Host "   -> Merged $merged existing translations" -ForegroundColor Green
}
else {
    Write-Host "   -> Skipped (files not found)" -ForegroundColor Gray
}

# ============================================================================
# MERGE STARS
# ============================================================================
Write-Host "[3/4] Merging STARS translations..." -ForegroundColor Yellow

$newStarsPath = Join-Path $NewCsvPath "stars_full.csv"
$oldStarsPath = Join-Path $OldCsvPath "translation_stars.csv"

if ((Test-Path $newStarsPath) -and (Test-Path $oldStarsPath)) {
    $newStars = Import-Csv $newStarsPath -Encoding UTF8
    $oldStars = Import-Csv $oldStarsPath -Encoding UTF8
    
    $oldLookup = @{}
    foreach ($row in $oldStars) {
        $key = $row.Key
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $oldLookup[$key] = $row
        }
    }
    
    $merged = 0
    foreach ($row in $newStars) {
        $key = $row.Key
        if ($oldLookup.ContainsKey($key)) {
            $oldRow = $oldLookup[$key]
            
            if ($oldRow.PSObject.Properties.Name -contains "Name_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Name_TH)) {
                $row.Name_TH = $oldRow.Name_TH
            }
            $descCol = $null
            if ($oldRow.PSObject.Properties.Name -contains "Desc_TH") { $descCol = "Desc_TH" }
            elseif ($oldRow.PSObject.Properties.Name -contains "Description_TH") { $descCol = "Description_TH" }
            if ($descCol -and -not [string]::IsNullOrWhiteSpace($oldRow.$descCol)) {
                $row.Desc_TH = $oldRow.$descCol
                $merged++
            }
            if ($oldRow.PSObject.Properties.Name -contains "Lore_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Lore_TH)) {
                $row.Lore_TH = $oldRow.Lore_TH
            }
        }
    }
    
    $newStars | Export-Csv $newStarsPath -Encoding UTF8 -NoTypeInformation
    Write-Host "   -> Merged $merged existing translations" -ForegroundColor Green
}
else {
    Write-Host "   -> Skipped (files not found)" -ForegroundColor Gray
}

# ============================================================================
# MERGE ACHIEVEMENTS
# ============================================================================
Write-Host "[4/4] Merging ACHIEVEMENTS translations..." -ForegroundColor Yellow

$newAchPath = Join-Path $NewCsvPath "achievements_full.csv"
$oldAchPath = Join-Path $OldCsvPath "translation_achievements.csv"

if ((Test-Path $newAchPath) -and (Test-Path $oldAchPath)) {
    $newAch = Import-Csv $newAchPath -Encoding UTF8
    $oldAch = Import-Csv $oldAchPath -Encoding UTF8
    
    $oldLookup = @{}
    foreach ($row in $oldAch) {
        $key = $row.Key
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $oldLookup[$key] = $row
        }
    }
    
    $merged = 0
    foreach ($row in $newAch) {
        $key = $row.Key
        if ($oldLookup.ContainsKey($key)) {
            $oldRow = $oldLookup[$key]
            
            if ($oldRow.PSObject.Properties.Name -contains "Name_TH" -and -not [string]::IsNullOrWhiteSpace($oldRow.Name_TH)) {
                $row.Name_TH = $oldRow.Name_TH
            }
            $descCol = $null
            if ($oldRow.PSObject.Properties.Name -contains "Desc_TH") { $descCol = "Desc_TH" }
            elseif ($oldRow.PSObject.Properties.Name -contains "Description_TH") { $descCol = "Description_TH" }
            if ($descCol -and -not [string]::IsNullOrWhiteSpace($oldRow.$descCol)) {
                $row.Desc_TH = $oldRow.$descCol
                $merged++
            }
        }
    }
    
    $newAch | Export-Csv $newAchPath -Encoding UTF8 -NoTypeInformation
    Write-Host "   -> Merged $merged existing translations" -ForegroundColor Green
}
else {
    Write-Host "   -> Skipped (files not found)" -ForegroundColor Gray
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "           MERGE COMPLETE                  " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your existing translations have been merged into the new CSV format." -ForegroundColor Green
Write-Host "CSV files in: $NewCsvPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open CSV files and fill in *_TH columns for missing translations" -ForegroundColor Gray
Write-Host "  2. Run 'master_import_csv.ps1' to generate JSON files" -ForegroundColor Gray
Write-Host "  3. Rebuild mod DLL if needed" -ForegroundColor Gray
