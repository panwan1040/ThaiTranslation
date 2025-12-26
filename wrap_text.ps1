# Script to add newlines to Thai text in memories.json
# Breaking lines at approximately 50-55 characters

$inputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\memories.json"
$outputPath = "d:\SteamLibrary\steamapps\common\Shape of Dreams\Mods\ThaiTranslation\RawData\th-TH\memories_wrapped.json"

$MAX_LINE_LENGTH = 50

# Characters that are good break points
$breakChars = @(' ', ',', '/', ')', '(', '!', '?', ':', ';', '–', '-', '—')

function Wrap-ThaiText {
    param([string]$text)
    
    if ([string]::IsNullOrEmpty($text)) { return $text }
    
    # Split by existing newlines
    $paragraphs = $text -split '\n'
    $result = @()
    
    foreach ($paragraph in $paragraphs) {
        $paragraph = $paragraph.TrimEnd("`r")
        
        # If paragraph is short enough, keep as is
        if ($paragraph.Length -le $MAX_LINE_LENGTH) {
            $result += $paragraph
            continue
        }
        
        # Wrap long paragraph
        $startIndex = 0
        $wrappedLines = @()
        
        while ($startIndex -lt $paragraph.Length) {
            $remainingLength = $paragraph.Length - $startIndex
            
            if ($remainingLength -le $MAX_LINE_LENGTH) {
                # Last chunk
                $wrappedLines += $paragraph.Substring($startIndex)
                break
            }
            
            # Find best break point
            $breakPoint = -1
            $searchEnd = [Math]::Min($startIndex + $MAX_LINE_LENGTH, $paragraph.Length)
            
            # Search backwards for a good break point
            for ($i = $searchEnd - 1; $i -gt $startIndex; $i--) {
                $char = $paragraph[$i]
                if ($breakChars -contains $char) {
                    $breakPoint = $i + 1
                    break
                }
            }
            
            # If no good break point, force break
            if ($breakPoint -le $startIndex) {
                $breakPoint = $startIndex + $MAX_LINE_LENGTH
            }
            
            # Append this chunk
            $chunk = $paragraph.Substring($startIndex, $breakPoint - $startIndex).TrimEnd()
            $wrappedLines += $chunk
            
            $startIndex = $breakPoint
            
            # Skip leading spaces
            while ($startIndex -lt $paragraph.Length -and $paragraph[$startIndex] -eq ' ') {
                $startIndex++
            }
        }
        
        $result += ($wrappedLines -join "`n")
    }
    
    return ($result -join "`n")
}

# Read JSON
Write-Host "Reading memories.json..."
$json = Get-Content $inputPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Process each entry
$count = 0
$properties = $json.PSObject.Properties

foreach ($prop in $properties) {
    $key = $prop.Name
    $entry = $prop.Value
    
    # Wrap description
    if ($entry.PSObject.Properties['description']) {
        $original = $entry.description
        $wrapped = Wrap-ThaiText $original
        if ($original -ne $wrapped) {
            $entry.description = $wrapped
            $count++
        }
    }
    
    # Wrap lore
    if ($entry.PSObject.Properties['lore']) {
        $original = $entry.lore
        $wrapped = Wrap-ThaiText $original
        if ($original -ne $wrapped) {
            $entry.lore = $wrapped
            $count++
        }
    }
}

# Save JSON
Write-Host "Saving to memories_wrapped.json..."
$json | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8

Write-Host "Done! Modified $count fields."
Write-Host "Output saved to: $outputPath"
Write-Host ""
Write-Host "Please review the output file, then rename it to memories.json if satisfied."
