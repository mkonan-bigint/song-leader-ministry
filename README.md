# Song Leader Ministry

> Mise en place, mise à jour du recueil, publication et dépannage : voir le **[Guide technique](GUIDE-TECHNIQUE.md)**.

Recueil de cantiques bilingue français / anglais pour le conducteur de chants.

- **Android** : APK téléchargeable depuis la dernière *Release* du dépôt (`SongLeaderMinistry.apk`).
- **iPhone** (et tout navigateur) : version web installable publiée sur GitHub Pages. Dans Safari : Partager → « Sur l'écran d'accueil ».
- **Hors connexion** : tout le recueil est enregistré sur le téléphone. Quand il y a Internet, l'application télécharge automatiquement les nouveaux cantiques, sans réinstallation.

## Contenu de l'application

Uniquement les cantiques **validés**, classés par **ordre alphabétique** de titre. Ils viennent du document Claude « Recueil validé – Song Leader Ministry ».

- Liste A → Z avec index des lettres et recherche (titre ou paroles, sans tenir compte des accents)
- Paroles en français, en anglais ou les deux
- Taille du texte, mode nuit, favoris, cantique précédent / suivant (boutons ou balayage)
- L'écran reste allumé pendant la lecture d'un cantique

## Ajouter des cantiques validés

1. Dans le document Claude « Recueil validé – Song Leader Ministry » : menu du document → **Exporter** → **Markdown**.
2. Enregistrer le fichier dans le dossier `recueil\` du projet (le plus récent est utilisé).
3. Lancer l'import :

   ```
   powershell -ExecutionPolicy Bypass -File "C:\Dev Projects\Song Leader Ministry\tools\importer.ps1"
   ```

4. Publier avec Git (add, commit, push). GitHub recompile l'APK et met à jour la version web en quelques minutes.

## Structure

| Dossier | Contenu |
|---|---|
| `www/` | L'application (HTML/JS), le recueil `cantiques.json`, les icônes et les polices |
| `recueil/` | Export Markdown du document « Recueil validé » (source du recueil) |
| `tools/` | Script d'import (`extract.py`) et commande Windows (`importer.ps1`) |
| `assets/` | Sources des icônes et de l'écran de démarrage Android |
| `.github/workflows/` | Compilation de l'APK et publication de la version web |
