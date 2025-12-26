# Sync Tags and Highlight Keywords for Memories.json
# Securely adds formatting from English source to Thai translation

$usPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\RawData\en-US\memories.json"
$thPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\memories.json"

Write-Host "Please wait, processing..." -ForegroundColor Cyan

# 1. Read Files
if (-not (Test-Path $usPath) -or -not (Test-Path $thPath)) {
    Write-Error "Files not found!"
    exit
}

$usJson = Get-Content -Path $usPath -Raw -Encoding UTF8 | ConvertFrom-Json
$thJson = Get-Content -Path $thPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Keyword Mapping (Thai Key Terms to Highlight)
# Using generic matching to avoid encoding headache in script body if possible
# But here we define common Thai game terms directly
$keywords = @(
    "ความเสียหายกายภาพ", "ความเสียหายเวท", "ความเสียหายจริง", 
    "ความเสียหายไฟ", "ความเสียหายน้ำแข็ง", "ความเสียหายสายฟ้า", "ความเสียหายพิษ",
    "ความเสียหายแสง", "ความเสียหายมืด", "ความเสียหาย",
    "พลังโจมตี", "พลังเวท", "ความเร็วโจมตี", "ความเร็วเคลื่อนที่", 
    "ลดคูลดาวน์", "คูลดาวน์", "พลังชีวิต", "มานา", "เกราะป้องกัน", "เกราะ", "โล่",
    "โอกาสคริติคอล", "ความแรงคริติคอล",
    "สตัน", "สโลว์", "ตรึง", "ใบ้", "ตาบอด", "หวาดกลัว", "ยั่วยุ", "ผลัก", "ดึง", "ลอย", "อมตะ",
    "ฟื้นฟู", "รักษา", "ดูดเลือด", "กดค้าง", "พาสซีฟ", "สถานะผิดปกติ"
)
# Sort by length descending to match longest terms first
$keywords = $keywords | Sort-Object -Property Length -Descending

$output = [ordered]@{}
$count = 0

foreach ($key in $thJson.PSObject.Properties.Name) {
    $thEntry = $thJson.$key
    
    # 2. Create Clean Entry
    $newEntry = [ordered]@{}
    
    # Copy all properties
    foreach ($prop in $thEntry.PSObject.Properties) {
        $newEntry[$prop.Name] = $prop.Value
    }
    
    # 3. Process Description
    if ($usJson.PSObject.Properties.Name -contains $key) {
        $usEntry = $usJson.$key
        $usDesc = $usEntry.description
        $thDesc = $newEntry.description
        
        if ($usDesc -and $thDesc) {
            # --- A. Scaling Tags (from US source) ---
            
            # 1. Quality Scaling <sprite=5>
            # Matches any number% followed by <sprite=5> in English, finds corresponding % in Thai
            # This is tricky because numbers might change order, but usually they don't.
            # Simpler approach: If US has <sprite=5>, assume all percentages in Thai need it (unless they already have it)
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
                # Wrap keyword in yellow color if not already colored
                # Regex explained:
                # (?<!<color=yellow>) : Lookbehind to ensure not already prefixed by color tag
                # (KEYWORD)           : The word to match
                # (?!</color>)        : Lookahead to ensure not followed by closing color tag
                
                $escapedKw = [regex]::Escape($kw)
                $pattern = "(?<!<color=yellow>)$escapedKw(?!</color>)"
                
                if ($thDesc -match $escapedKw -and $thDesc -notmatch "<color=yellow>$escapedKw</color>") {
                    $thDesc = $thDesc -replace $pattern, "<color=yellow>$kw</color>"
                }
            }
            
            $newEntry.description = $thDesc
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

$jsonString = $output | ConvertTo-Json -Depth 10
# Fix unicode escapes
$jsonString = $jsonString -replace '\\u003c', '<'
$jsonString = $jsonString -replace '\\u003e', '>'

[System.IO.File]::WriteAllText($thPath, $jsonString, [System.Text.Encoding]::UTF8)

Write-Host "Success! Processed $count entries." -ForegroundColor Green
Write-Host "Saved to: $thPath" -ForegroundColor Gray
