# Guide technique — Song Leader Ministry

Application de recueil de cantiques bilingue, disponible sur **Android** (APK) et **iPhone** (application web installable), avec fonctionnement **hors connexion**. Même architecture que Man Child Ministry.

---

## 1. Vue d'ensemble

```
Document Claude « Recueil validé – Song Leader Ministry »
        │  Exporter → Markdown  →  recueil\*.md
        │  tools\importer.ps1  (script Python extract.py)
        ▼
www\cantiques.json  ── git push ──►  GitHub
                                       │  GitHub Actions (.github\workflows\build.yml)
                                       ├──► APK Android  → Releases (lien de téléchargement permanent)
                                       └──► Version web  → GitHub Pages (iPhone + recueil en ligne)
```

- **Une seule application web** (`www\index.html`) sert pour les deux plateformes.
- **Android** : emballée dans un APK avec Capacitor, compilé par GitHub Actions.
- **iPhone** : publiée sur GitHub Pages, installée depuis Safari, sans App Store.
- **Mises à jour** : l'application embarque le recueil. Avec Internet, elle télécharge la version publiée si elle est plus récente. Les nouveaux cantiques arrivent **sans réinstaller l'APK**.
- **Ordre** : les cantiques sont triés par ordre alphabétique du titre, accents et majuscules ignorés — le même ordre que le document « Recueil validé ».

### Contenu du dossier

| Élément | Rôle |
|---|---|
| `www\index.html` | L'application : liste A → Z, recherche, lecture FR / EN, favoris, réglages |
| `www\cantiques.json` | Le recueil généré par l'import (ne pas modifier à la main) |
| `www\config.js` | Adresse du recueil en ligne, remplie automatiquement à la compilation |
| `www\sw.js`, `www\manifest.webmanifest` | Fonctionnement hors connexion et installation sur l'iPhone |
| `www\icons\`, `www\fonts\` | Logo, icônes et polices, embarqués pour fonctionner sans Internet |
| `recueil\` | Export Markdown du document « Recueil validé » |
| `tools\extract.py`, `tools\importer.ps1` | Conversion du Markdown en `cantiques.json` |
| `assets\` | Sources de l'icône et de l'écran de démarrage Android |
| `.github\workflows\build.yml` | Compilation de l'APK et publication de la version web |
| `package.json`, `capacitor.config.json` | Configuration du projet Android (Capacitor) |
| `signature-android.keystore` et fichiers `SECRETS-*` | Clé de signature de l'APK. **Confidentiel, exclu de Git** |

---

## 2. Mise en place initiale (une seule fois)

1. Sur github.com, créer le dépôt **`song-leader-ministry`**, en **public** et **sans** README (le mode public est nécessaire pour GitHub Pages avec un compte gratuit).
2. **Settings → Pages** : *Source* = **GitHub Actions**.
3. **Settings → Secrets and variables → Actions → New repository secret** : créer les trois secrets dont les valeurs sont dans `SECRETS-A-NE-PAS-PUBLIER.txt` :

| Nom du secret | Valeur |
|---|---|
| `ANDROID_KEYSTORE_PASSWORD` | le mot de passe indiqué dans le fichier |
| `ANDROID_KEY_ALIAS` | `songleader` |
| `ANDROID_KEYSTORE_BASE64` | **tout** le contenu de `signature-android.keystore.base64.txt` |

4. Premier envoi. Le fichier de compilation a été livré dans `tools\build.yml` ; la deuxième et la troisième commande le placent dans `.github\workflows\`, où GitHub l'attend :

```
cd "C:\Dev Projects\Song Leader Ministry"
New-Item -ItemType Directory -Force .github\workflows | Out-Null
Move-Item tools\build.yml .github\workflows\build.yml
git init -b main
git add .
git commit -m "Song Leader Ministry : application du recueil de cantiques (web + Android)"
git remote add origin https://github.com/mkonan-bigint/song-leader-ministry.git
git push -u origin main
```

5. Onglet **Actions** : le workflow « Publier l'application » lance deux tâches (**pages** et **android**, environ 5 minutes). Les deux doivent finir en vert.

---

## 3. Distribuer l'application

- **Android** — lien permanent vers la dernière version :
  `https://github.com/mkonan-bigint/song-leader-ministry/releases/latest/download/SongLeaderMinistry.apk`
  À partager par WhatsApp, SMS ou e-mail. Sur le téléphone, autoriser « Installer des applications inconnues » quand Android le demande.
- **iPhone** — `https://mkonan-bigint.github.io/song-leader-ministry/` dans **Safari**, puis **Partager → « Sur l'écran d'accueil »**.

---

## 4. Ajouter des cantiques validés

1. Valider les cantiques dans le recueil de travail, puis demander à Claude d'actualiser le document « Recueil validé ».
2. Dans ce document : menu du document → **Exporter** → **Markdown**. Enregistrer le fichier dans `C:\Dev Projects\Song Leader Ministry\recueil\`.
3. Lancer l'import :

```
powershell -ExecutionPolicy Bypass -File "C:\Dev Projects\Song Leader Ministry\tools\importer.ps1"
```

Le script affiche la liste dans l'ordre alphabétique, avec un « ⚠ » pour un cantique sans ID ou un ID en double, et le nombre de nouveaux cantiques.

4. Publier :

```
cd "C:\Dev Projects\Song Leader Ministry"
git add recueil www/cantiques.json
git commit -m "Recueil : ajout de nouveaux cantiques validés"
git push
```

Quelques minutes plus tard, la version web et l'APK sont à jour, et les téléphones déjà installés affichent « X nouveaux cantiques ajoutés » à leur prochaine connexion.

### Format attendu du document

```
## Titre du cantique
ID : C0001
**Français**
ligne 1
ligne 2
(ligne vide = nouvelle strophe)
**English**
line 1
```

Une strophe qui commence par « Refrain » est mise en valeur par un trait doré dans l'application.

---

## 5. Sécurité et sauvegardes

- **`signature-android.keystore` et son mot de passe** : à sauvegarder **hors du PC**. S'ils sont perdus, aucune mise à jour de l'APK ne pourra s'installer par-dessus l'ancienne version.
- Ne **jamais** publier ces fichiers sur GitHub : ils sont exclus par `.gitignore`.
- Le dépôt étant public, les paroles sont consultables par tous, comme la version web.

## 6. Dépannage

| Problème | Solution |
|---|---|
| « Aucun fichier .md dans recueil » | Exporter le document en Markdown dans le dossier `recueil\` |
| Un cantique manque dans l'application | Vérifier qu'il est dans le document « Recueil validé » avec un titre `##` et une ligne `ID :`, puis relancer l'import |
| La tâche **pages** échoue | Settings → Pages → Source : **GitHub Actions** |
| La tâche **android** échoue à l'étape « Signature » | Recopier **tout** le contenu de `signature-android.keystore.base64.txt` dans le secret |
| « Application non installée » sur Android | Désinstaller l'ancienne version (signée avec une autre clé), puis réinstaller |
| Les nouveaux cantiques n'apparaissent pas | Vérifier l'onglet Actions, puis rouvrir l'application avec Internet |
