# Run StoreFuse against your production Bridge (URL in gitignored dart_defines.local.json).
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$definesFile = Join-Path $repoRoot "dart_defines.local.json"
if (-not (Test-Path $definesFile)) {
  Write-Error @"
Missing dart_defines.local.json

Copy the template and set your WordPress site root (not /wp-json/...):

  Copy-Item dart_defines.example.json dart_defines.local.json

See docs/env.example.md
"@
}

flutter run `
  --dart-define-from-file=dart_defines.local.json `
  @args
