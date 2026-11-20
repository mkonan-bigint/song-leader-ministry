# Liste les audios du dossier « audios » et met à jour www/audios.json pour l'application.
# Nommage : <ID>.mp3 ou <ID>_<Libellé>.mp3  (ex. C0273.mp3, C0273_Anglais.mp3, C0273_Chorale.mp3)
# Le libellé (après le tiret bas) est affiché tel quel dans l'application.
param(
  [string]$Base = "https://audios.songleaderministry.org"
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dir  = Join-Path $root "audios"
if (-not (Test-Path $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
  Write-Host "Dossier créé : $dir (déposez-y les audios, nommés comme dans le bucket R2)"
}

# Les fichiers audio ne vont jamais dans Git : ils sont sur R2.
$gi = Join-Path $root ".gitignore"
if (-not (Test-Path $gi) -or -not (Select-String -Path $gi -Pattern '^audios/\s*$' -Quiet)) {
  Add-Content -Path $gi -Value "audios/"
  Write-Host ".gitignore : ligne 'audios/' ajoutée"
}

$items = [ordered]@{}
$ignores = @()
$nb = 0
Get-ChildItem -Path $dir -File |
  Where-Object { @('.mp3', '.m4a') -contains $_.Extension.ToLower() } |
  Sort-Object @{ Expression = { $_.BaseName -match '[_-]' } }, Name |
  ForEach-Object {
    if ($_.BaseName -match '^([Cc]\d{4})(?:[_-](.+))?$') {
      $id  = $Matches[1].ToUpper()
      $lbl = if ($Matches[2]) { ($Matches[2] -replace '[_-]+', ' ').Trim() } else { "Audio" }
      if (-not $items.Contains($id)) { $items[$id] = New-Object System.Collections.ArrayList }
      [void]$items[$id].Add([ordered]@{ f = $_.Name; l = $lbl })
      $nb++
    } else {
      $ignores += $_.Name
    }
  }

$obj = [ordered]@{
  version = (Get-Date -Format "yyyyMMddHHmmss")
  base    = $Base.TrimEnd('/')
  items   = $items
}
$json = ConvertTo-Json -InputObject $obj -Depth 6
$out  = Join-Path $root "www\audios.json"
[IO.File]::WriteAllText($out, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "audios.json mis à jour : $nb fichier(s) pour $($items.Count) cantique(s)."
Write-Host "Adresse des audios : $($obj.base)"
if ($ignores.Count) {
  Write-Host ""
  Write-Host "Ignorés (le nom doit commencer par l'ID, ex. C0273_Anglais.mp3) :" -ForegroundColor Yellow
  $ignores | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}
Write-Host ""
Write-Host "Rappel : envoyez sur R2 les fichiers avec exactement le même nom (majuscules comprises)."
