# Met à jour le recueil de l'application Song Leader Ministry.
# Source : l'export Markdown du document Claude « Recueil validé – Song Leader Ministry »,
# enregistré dans le dossier recueil\ du projet (le fichier .md le plus récent est utilisé).
param(
  [string]$Source = ""
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Source) { $Source = Join-Path $repo "recueil" }

# --- Trouver un vrai Python (et pas le raccourci du Microsoft Store) ---
function Find-Python {
  $candidates = @()
  foreach ($name in @("python", "python3", "py")) {
    Get-Command $name -All -ErrorAction SilentlyContinue | ForEach-Object {
      if ($_.Source -and $_.Source -notmatch "WindowsApps") { $candidates += $_.Source }
    }
  }
  $roots = @("$env:USERPROFILE\MiniConda3", "$env:USERPROFILE\miniconda3", "$env:USERPROFILE\anaconda3",
             "$env:USERPROFILE\Anaconda3", "$env:LOCALAPPDATA\miniconda3", "$env:LOCALAPPDATA\anaconda3",
             "$env:ProgramData\miniconda3", "$env:ProgramData\anaconda3", "C:\miniconda3", "C:\anaconda3")
  foreach ($r in $roots) { if (Test-Path "$r\python.exe") { $candidates += "$r\python.exe" } }
  Get-ChildItem "$env:LOCALAPPDATA\Programs\Python\Python3*\python.exe" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | ForEach-Object { $candidates += $_.FullName }
  foreach ($c in $candidates) {
    try { & $c -c "import sys; assert sys.version_info >= (3, 8)" 2>$null; if ($LASTEXITCODE -eq 0) { return $c } } catch {}
  }
  return $null
}

$python = Find-Python
if (-not $python) {
  Write-Host "Aucune installation de Python trouvée." -ForegroundColor Red
  Write-Host "Installez Python depuis https://www.python.org/downloads/ (cocher « Add python.exe to PATH »), puis relancez."
  exit 1
}

Write-Host "Import depuis : $Source"
& $python "$PSScriptRoot\extract.py" "$Source" "$repo\www\cantiques.json"
if ($LASTEXITCODE -ne 0) { Write-Host "L'import a échoué (voir le message ci-dessus)." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Recueil mis à jour : $repo\www\cantiques.json" -ForegroundColor Green
Write-Host "Publiez ensuite avec Git (add, commit, push) : l'APK et la version iPhone se mettent à jour automatiquement."
