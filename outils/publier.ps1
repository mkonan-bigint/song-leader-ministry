# Publie l'application Song Leader Ministry : liste des audios, puis commit et push vers GitHub.
# Usage : powershell -ExecutionPolicy Bypass -File "C:\Dev Projects\Song Leader Ministry\outils\publier.ps1" ["message du commit"]
param(
  [string]$Message = ""
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "1/3  Liste des audios (dossier audios)" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "audios.ps1")

Write-Host ""
Write-Host "2/3  Fichiers à publier" -ForegroundColor Cyan
# Uniquement l'application, le recueil et les outils (jamais la clé de signature ni les secrets)
git add -- www recueil outils .gitignore
$fichiers = @(git diff --cached --name-only)
if ($fichiers.Count -eq 0) {
  Write-Host "Rien de nouveau à publier : tout est déjà sur GitHub." -ForegroundColor Yellow
  exit 0
}
$fichiers | ForEach-Object { Write-Host "  $_" }

if (-not $Message) {
  $parts = @()
  if ($fichiers -contains "www/cantiques.json") { $parts += "recueil" }
  if ($fichiers -contains "www/audios.json")    { $parts += "audios" }
  if ($fichiers | Where-Object { $_ -notin @("www/cantiques.json", "www/audios.json", "recueil/recueil-valide.md") }) { $parts += "application" }
  if (-not $parts) { $parts = @("recueil") }
  $Message = "Mise à jour : " + ($parts -join ", ") + " (" + (Get-Date -Format "yyyy-MM-dd HH:mm") + ")"
}
git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw "Le commit a échoué." }

Write-Host ""
Write-Host "3/3  Envoi vers GitHub" -ForegroundColor Cyan
git push
if ($LASTEXITCODE -ne 0) { throw "Le push a échoué (connexion ou identifiants GitHub)." }

Write-Host ""
Write-Host "Publié. Le build démarre sur GitHub (5 à 10 minutes) :" -ForegroundColor Green
Write-Host "  https://github.com/mkonan-bigint/song-leader-ministry/actions"
Write-Host "Rappel : les nouveaux fichiers audio doivent aussi être envoyés sur R2, avec exactement le même nom."
