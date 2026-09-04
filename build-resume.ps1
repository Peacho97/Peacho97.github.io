<#
.SYNOPSIS
  Prints _resume-src.html to Keaton-Van-Patten-Resume.pdf via headless Chrome (or Edge).

.NOTES
  Letter size and margins come from the @page rule in _resume-src.html.
  Backgrounds are printed; no browser header/footer is added.
#>
[CmdletBinding()]
param(
    [string]$Source = (Join-Path $PSScriptRoot '_resume-src.html'),
    [string]$Output = (Join-Path $PSScriptRoot 'Keaton-Van-Patten-Resume.pdf')
)

$ErrorActionPreference = 'Stop'

$candidates = @(
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
)

$browser = $null
foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { $browser = $c; break }
}
if (-not $browser) {
    throw "No Chrome or Edge binary found. Looked in:`n  $($candidates -join "`n  ")"
}

if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }

$sourceUri = ([Uri](Resolve-Path -LiteralPath $Source).Path).AbsoluteUri

# A throwaway profile keeps the print out of the user's live browser session.
$profileDir = Join-Path ([IO.Path]::GetTempPath()) ("resume-print-" + [Guid]::NewGuid().ToString('N'))

$browserArgs = @(
    '--headless=new'
    '--disable-gpu'
    '--no-first-run'
    '--no-default-browser-check'
    "--user-data-dir=$profileDir"
    '--run-all-compositor-stages-before-draw'
    '--virtual-time-budget=10000'          # let webfonts land before printing
    '--no-pdf-header-footer'                # no URL/date chrome on the page
    '--print-to-pdf-no-header'              # older flag name, harmless if ignored
    "--print-to-pdf=$Output"
    $sourceUri
)

Write-Host "Browser : $browser"
Write-Host "Source  : $Source"
Write-Host "Output  : $Output"

try {
    & $browser @browserArgs | Out-Null
} finally {
    if (Test-Path -LiteralPath $profileDir) {
        try { Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction Stop } catch {}
    }
}

if (-not (Test-Path -LiteralPath $Output)) { throw "PDF was not produced: $Output" }

$bytes = (Get-Item -LiteralPath $Output).Length
Write-Host "Wrote $Output ($bytes bytes)"
