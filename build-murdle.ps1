param(
  [string]$Source,
  [string]$Output,
  [string]$SourceDirectory = 'sources',
  [string]$OutputDirectory = 'puzzles'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$templatePath = Join-Path $root 'murdle-template.html'

function Resolve-ProjectPath([string]$Path) {
  if ([IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $root $Path
}

function Get-DefaultOutputName([string]$SourcePath) {
  $baseName = [IO.Path]::GetFileNameWithoutExtension($SourcePath)
  if ($baseName -in @('mini', 'standard')) { return "$baseName-murdle.html" }
  return "$baseName.html"
}

function Build-Puzzle([string]$SourcePath, [string]$OutputPath) {
  $puzzle = Get-Content -LiteralPath $SourcePath -Raw | ConvertFrom-Json -AsHashtable
  $required = 'mode', 'edition', 'title', 'subtitle', 'storyTitle', 'storyHtml', 'clues', 'suspects', 'weapons', 'rooms', 'solution'
  foreach ($field in $required) {
    if (-not $puzzle.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($puzzle[$field])) {
      throw "$SourcePath requires '$field'."
    }
  }

  $count = $puzzle.suspects.Count
  if ($count -lt 3 -or $puzzle.weapons.Count -ne $count -or $puzzle.rooms.Count -ne $count) {
    throw "$SourcePath must contain the same number of suspects, weapons, and rooms, with at least three in each category."
  }
  if ($puzzle.mode -eq 'mini' -and $count -ne 3) { throw "$SourcePath is mini mode and requires exactly three entries in each category." }
  if ($puzzle.mode -eq 'standard' -and $count -ne 5) { throw "$SourcePath is standard mode and requires exactly five entries in each category." }
  if ($puzzle.storyHtml -match '<\s*/?\s*(script|style|iframe)\b') { throw "$SourcePath storyHtml cannot contain script, style, or iframe elements." }
  if ($puzzle.solution.suspect -notin $puzzle.suspects -or $puzzle.solution.weapon -notin $puzzle.weapons -or $puzzle.solution.room -notin $puzzle.rooms) {
    throw "$SourcePath solution must use entries from the suspect, weapon, and room lists."
  }
  foreach ($clue in $puzzle.clues) {
    if ([string]::IsNullOrWhiteSpace($clue.text)) { throw "$SourcePath contains a clue without text." }
  }

  $puzzleJson = ($puzzle | ConvertTo-Json -Depth 10 -Compress).Replace('</', '<\/')
  $html = [IO.File]::ReadAllText($templatePath)
  $html = $html.Replace('__PAGE_TITLE__', [string]$puzzle.title)
  $html = $html.Replace('__EDITION__', [string]$puzzle.edition)
  $html = $html.Replace('__PUZZLE_JSON__', $puzzleJson)

  [IO.Directory]::CreateDirectory((Split-Path -Parent $OutputPath)) | Out-Null
  [IO.File]::WriteAllText($OutputPath, $html, [Text.UTF8Encoding]::new($false))
  Write-Host "Built $OutputPath from $SourcePath"
}

if (-not (Test-Path -LiteralPath $templatePath)) { throw 'Missing murdle-template.html.' }
if ($Output -and -not $Source) { throw '-Output can only be used together with -Source.' }

$outputDirectoryPath = Resolve-ProjectPath $OutputDirectory
if ($Source) {
  $sourcePath = Resolve-ProjectPath $Source
  if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Missing source file: $Source" }
  $outputPath = if ($Output) { Resolve-ProjectPath $Output } else { Join-Path $outputDirectoryPath (Get-DefaultOutputName $sourcePath) }
  Build-Puzzle $sourcePath $outputPath
  exit
}

$sourceDirectoryPath = Resolve-ProjectPath $SourceDirectory
if (-not (Test-Path -LiteralPath $sourceDirectoryPath -PathType Container)) { throw "Missing source directory: $SourceDirectory" }
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceDirectoryPath -Filter '*.json' -File | Sort-Object Name)
if ($sourceFiles.Count -eq 0) { throw "No JSON puzzle sources found in $SourceDirectory." }

foreach ($sourceFile in $sourceFiles) {
  Build-Puzzle $sourceFile.FullName (Join-Path $outputDirectoryPath (Get-DefaultOutputName $sourceFile.FullName))
}