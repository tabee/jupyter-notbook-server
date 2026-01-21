# 🚀 Jupyter Notebook Server - Docker Setup

Ein **minimalistisches, sichere Docker-Setup** für einen Jupyter Notebook Server auf Ubuntu.

---

## ⚡ Schnellstart (3 Schritte)

### 1️⃣ **Berechtigungen korrigieren** (WICHTIG!)

Das Projektverzeichnis muss dir gehören, sonst funktioniert das Speichern von Notebooks nicht:

```bash
sudo chown -R $(id -u):$(id -g) ~/jupyter-work
```

**Grund**: Der Host erstellt das Verzeichnis standardmäßig mit `root:root`. Der Container-User braucht Schreibzugriff.

### 2️⃣ **Container starten**

```bash
cd /home/me/Code/jupyter-notbook-server
docker compose up -d --build
```

**Hinweis**: Beim ersten Start dauert's ~3 Minuten (Dependencies installieren).

### 3️⃣ **Öffne Jupyter**

Gehe zu: **http://127.0.0.1:8888**

✅ Du bist direkt drin - **kein Token nötig** (läuft nur lokal!)

---

## 📋 Features

- ✅ **Jupyter Notebook** (klassisch, nicht JupyterLab)
- ✅ **Non-Root Container**: Läuft als User `me` (UID/GID konfigurierbar)
- ✅ **Secure by Default**: Nur auf localhost gebunden (127.0.0.1:8888)
- ✅ **Persistente Notebooks**: Volume-Mount zu `~/jupyter-work`
- ✅ **Kein Token/Passwort**: Für lokalen Zugriff optimiert
- ✅ **Signal Handling**: Nutzt tini als Init-System
- ✅ **Auto-Restart**: Container startet bei Boot neu

---

## 🔧 Konfiguration

### 🎯 **User anpassen** (falls nicht UID 1000)

Falls dein User eine andere UID hat:

```bash
id  # Zeigt deine aktuelle UID/GID
```

**Dann beim Build mitgeben:**
```bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
docker compose up -d --build
```

Das sorgt dafür, dass der Container-User **exakt die gleiche UID hat** wie dein Host-User → Keine Berechtigungsprobleme!

### 📁 **Notebooks-Verzeichnis ändern**

**Standard**: `~/jupyter-work`

**Anderes Verzeichnis verwenden:**

```bash
export PROJECTS_DIR=/pfad/zu/meinen/notebooks
docker compose up -d --build
```

**Beispiel mit großem Datenspeicher:**
```bash
mkdir -p /data/projects
sudo chown -R $(id -u):$(id -g) /data/projects
export PROJECTS_DIR=/data/projects
docker compose up -d --build
```

**Wichtig**: Stelle sicher, dass dir das Verzeichnis gehört!
```bash
ls -ld /pfad/zum/verzeichnis  # Prüfe den Owner
```

### 📦 **Python-Pakete hinzufügen**

Bearbeite `requirements.txt`:

```txt
numpy
pandas
matplotlib
scikit-learn
requests
```

Dann Container neu bauen:
```bash
docker compose up -d --build
```

---

## 📡 Remote-Zugriff (wichtig!)

⚠️ **Der Server hat KEINE Authentifizierung!** Er läuft nur lokal - das ist sicher.

### ✅ **Sichere Remote-Verbindung: SSH-Tunnel**

```bash
ssh -L 8888:127.0.0.1:8888 user@server.com
```

Jetzt auf deinem Rechner:
```bash
http://localhost:8888
```

Der Traffic ist verschlüsselt über SSH!

### Alternative: Reverse Proxy

Für produktiven Einsatz nutze **Nginx** oder **Traefik** mit:
- ✅ HTTPS
- ✅ Authentifizierung (Basic Auth, OAuth2)
- ✅ SSL/TLS

---

## 🛠️ Befehle im Überblick

| Befehl | Beschreibung |
|--------|-------------|
| `docker compose up -d --build` | Container im Hintergrund starten und neu bauen |
| `docker compose up -d` | Container im Hintergrund starten (ohne Rebuild) |
| `docker compose logs -f` | Live-Logs anzeigen |
| `docker compose logs --tail 50` | Letzte 50 Log-Zeilen |
| `docker compose stop` | Container pausieren |
| `docker compose down` | Container stoppen und entfernen |
| `docker compose ps` | Container-Status prüfen |
| `docker compose restart` | Container neu starten |

---

## 🚨 Troubleshooting

### ❌ "Permission denied" bei Notebook-Erstellung

**Problem**: Verzeichnis gehört `root` oder anderem User.

**Lösung**:
```bash
sudo chown -R $(id -u):$(id -g) ~/jupyter-work
docker compose restart
```

**Prüfe vorher:**
```bash
ls -ld ~/jupyter-work
# Sollte sein: drwxr-xr-x user:user ...
```

### ❌ "Port 8888 already in use"

**Lösung**: Andere Port in `docker-compose.yml` verwenden:

```yaml
ports:
  - "127.0.0.1:8889:8888"  # Nutze 8889 statt 8888
```

Dann: `http://127.0.0.1:8889`

### ❌ Container startet nicht

**Logs prüfen:**
```bash
docker compose logs --tail 200
```

**Häufige Fehler:**
- ❌ `Cannot connect to Docker daemon` → Docker nicht am Laufen
- ❌ `Permission denied` → `sudo chown` Befehl ausführen
- ❌ UID/GID mismatch → Mit korrekten `USER_ID`/`GROUP_ID` neu bauen

### ❌ Sehr langsame Datei-Operationen

Wenn auf **WSL2/Windows** oder **Remote-FS**:
- Notebooks lokal speichern statt in gemountet Pfad
- SSH-Mount statt Docker Volume erwägen

---

## 📚 Container-Details

| Detail | Wert |
|--------|------|
| **Base Image** | Ubuntu 22.04 LTS |
| **Container User** | `me` (default UID: 1000, GID: 1000) |
| **Working Directory** | `/home/me/yupiter-notebooks` |
| **Jupyter Port** | 8888 (nur 127.0.0.1) |
| **Init System** | tini (robuste Signal-Verarbeitung) |
| **Restart Policy** | `unless-stopped` (Auto-Start bei Boot) |
| **Volume Mount** | `${PROJECTS_DIR}` → `/home/me/yupiter-notebooks` |

---

## 🔐 Sicherheit

✅ **Was ist sicher:**
- ✓ Container läuft als **non-root User** (`me`, nicht `root`)
- ✓ Port nur auf **localhost** gebunden (nicht ins Internet)
- ✓ Keine Standard-Authentifizierung nötig für lokalen Zugriff

⚠️ **Warnung für Remote-Zugriff:**
- ⚠ Server hat **KEINE eingebaute Authentifizierung**
- ⚠ Alle, die Zugriff haben, können **beliebigen Code ausführen**
- ✅ **Lösung**: Immer SSH-Tunnel oder Reverse Proxy mit Auth verwenden!

---

## 📂 Projekt-Struktur

```
.
├── Dockerfile              # Container-Image Definition
├── docker-compose.yml      # Docker Compose Konfiguration  
├── requirements.txt        # Python-Pakete (optional)
├── README.md              # Diese Datei
└── .dockerignore          # Dateien ignorieren beim Build
```

---

## 🎓 Häufig gestellte Fragen

**F: Kann ich die UID ändern?**
```bash
export USER_ID=2000
export GROUP_ID=2000
docker compose up -d --build
```

**F: Speichert sich meine Config?**
Ja! Alles in `~/jupyter-work` ist persistent (per Volume-Mount).

**F: Kann ich weitere OS-Pakete installieren?**
Bearbeite `Dockerfile` und füge in der `RUN apt-get install` Zeile Pakete hinzu.

**F: Wie starte ich von Grund auf neu?**
```bash
docker compose down -v  # -v löscht auch Volumes
docker compose up -d --build
```

---

## 📝 Lizenz

MIT - Frei verwendbar.
