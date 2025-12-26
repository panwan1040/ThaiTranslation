# Sync Tags and Highlight Keywords for Memories.json (V2)
# Reads keywords from external file to avoid encoding syntax errors

$usPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\RawData\en-US\memories.json"
$thPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\memories.json"
$kwPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\keywords_thai.txt"

Write-Host "Please wait, processing..." -ForegroundColor Cyan

# 1. Read Files
if (-not (Test-Path $usPath) -or -not (Test-Path $thPath) -or -not (Test-Path $kwPath)) {
    Write-Error "Files not found!"
    exit
}

$usJson = Get-Content -Path $usPath -Raw -Encoding UTF8 | ConvertFrom-Json
$thJson = Get-Content -Path $thPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Read Keywords
$keywords = Get-Content -Path $kwPath -Encoding UTF8
# Sort by length descending to match longest terms first (Important!)
$keywords = $keywords | Where-Object { $_ -ne "" } | Sort-Object -Property Length -Descending

Write-Host "Loaded $($keywords.Count) keywords." -ForegroundColor Gray

$output = [ordered]@{}
$count = 0
$modCount = 0

foreach ($key in $thJson.PSObject.Properties.Name) {
    $thEntry = $thJson.$key
    
    # 2. Create Clean Entry
    $newEntry = [ordered]@{}
    
    foreach ($prop in $thEntry.PSObject.Properties) {
        $newEntry[$prop.Name] = $prop.Value
    }
    
    # 3. Process Description
    if ($usJson.PSObject.Properties.Name -contains $key) {
        $usEntry = $usJson.$key
        $usDesc = $usEntry.description
        $thDesc = $newEntry.description
        $originalThDesc = $thDesc
        
        if ($usDesc -and $thDesc) {
            # --- A. Scaling Tags (from US source) ---
            
            # 1. Quality Scaling <sprite=5>
            if ($usDesc -match '<sprite=5>') {
                $thDesc = $thDesc -replace '(\d+\.?\d*)%(?!<sprite)', '$1%<sprite=5>'
            }
            
            # 2. AP Scaling <sprite=1> (Blue)
            if ($usDesc -match '<sprite=1>') {
                $thDesc = $thDesc -replace '(\d+\.?\d*)%<sprite=5>', '<sprite=1><color=#16D7FF>$1%</color><sprite=5>'
            }
            
            # 3. AD Scaling <sprite=2> (Orange)
            if ($usDesc -match '<sprite=2>') {
                $thDesc = $thDesc -replace '(\d+\.?\d*)%<sprite=5>', '<sprite=2><color=#FF8A2D>$1%</color><sprite=5>'
            }
             
            # --- B. Thai Keyword Highlighting ---
            foreach ($kw in $keywords) {
                $kw = $kw.Trim()
                if ($kw.Length -eq 0) { continue }
                
                $escapedKw = [regex]::Escape($kw)
                # Pattern: Match word if NOT surrounded by color tags
                $pattern = "(?<!<color=yellow>)$escapedKw(?!</color>)"
                
                if ($thDesc -match $escapedKw -and $thDesc -notmatch "<color=yellow>$escapedKw</color>") {
                    $thDesc = $thDesc -replace $pattern, "<color=yellow>$kw</color>"
                }
            }
            
            if ($thDesc -ne $originalThDesc) {
                $newEntry.description = $thDesc
                $modCount++
            }
        }
    }
    
    $output[$key] = $newEntry
    $count++
}

# 4. Safe Save
if ($output.Count -eq 0) {
    Write-Error "Output is empty! Aborting save to prevent data loss."
    exit
}

$jsonString = $output | ConvertTo-Json -Depth 10 # Increase depth to ensure nested objects are serialized
# Fix unicode escapes
$jsonString = $jsonString -replace '\\u003c', '<'
$jsonString = $jsonString -replace '\\u003e', '>'

[System.IO.File]::WriteAllText($thPath, $jsonString, [System.Text.Encoding]::UTF8)

Write-Host "Success! Processed $count entries. Modified $modCount descriptions." -ForegroundColor Green
Write-Host "Saved to: $thPath" -ForegroundColor Gray
