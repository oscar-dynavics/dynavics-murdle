param(
  [Parameter(Mandatory)]
  [string]$Source,
  [string]$Output
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$templatePath = Join-Path $root 'murdle-template.html'
$sourcePath = if ([IO.Path]::IsPathRooted($Source)) { $Source } else { Join-Path $root $Source }

if (-not (Test-Path -LiteralPath $templatePath)) { throw 'Missing murdle-template.html.' }
if (-not (Test-Path -LiteralPath $sourcePath)) { throw "Missing source file: $Source" }

$puzzle = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json -AsHashtable
$required = 'mode', 'edition', 'title', 'subtitle', 'storyTitle', 'storyHtml', 'clues', 'suspects', 'weapons', 'rooms', 'solution'
foreach ($field in $required) {
  if (-not $puzzle.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($puzzle[$field])) {
    throw "Puzzle source requires '$field'."
  }
}

$count = $puzzle.suspects.Count
if ($count -lt 3 -or $puzzle.weapons.Count -ne $count -or $puzzle.rooms.Count -ne $count) {
  throw 'Suspects, weapons, and rooms must contain the same number of entries, with at least three in each category.'
}
if ($puzzle.mode -eq 'mini' -and $count -ne 3) { throw 'Mini puzzles require exactly three entries in each category.' }
if ($puzzle.mode -eq 'standard' -and $count -ne 5) { throw 'Standard puzzles require exactly five entries in each category.' }
if ($puzzle.storyHtml -match '<\s*/?\s*(script|style|iframe)\b') { throw 'storyHtml cannot contain script, style, or iframe elements.' }
if ($puzzle.solution.suspect -notin $puzzle.suspects -or $puzzle.solution.weapon -notin $puzzle.weapons -or $puzzle.solution.room -notin $puzzle.rooms) {
  throw 'The solution must use entries from the suspect, weapon, and room lists.'
}
foreach ($clue in $puzzle.clues) {
  if ([string]::IsNullOrWhiteSpace($clue.text)) { throw 'Every clue requires text.' }
}

$defaultOutput = Join-Path $root (Join-Path 'puzzles' "$($puzzle.mode)-murdle.html")
$outputPath = if ([string]::IsNullOrWhiteSpace($Output)) { $defaultOutput } elseif ([IO.Path]::IsPathRooted($Output)) { $Output } else { Join-Path $root $Output }
$puzzleJson = $puzzle | ConvertTo-Json -Depth 10 -Compress
$puzzleJson = $puzzleJson.Replace('</', '<\/')
$html = [IO.File]::ReadAllText($templatePath)
$html = $html.Replace('__PAGE_TITLE__', [string]$puzzle.title)
$html = $html.Replace('__EDITION__', [string]$puzzle.edition)
$html = $html.Replace('__PUZZLE_JSON__', $puzzleJson)

[IO.Directory]::CreateDirectory((Split-Path -Parent $outputPath)) | Out-Null
[IO.File]::WriteAllText($outputPath, $html, [Text.UTF8Encoding]::new($false))
Write-Host "Built $outputPath from $sourcePath"