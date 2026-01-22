# Jupyter Notebook Server (Docker)

Sicheres, reproduzierbares Docker-Setup für den klassischen Jupyter Notebook Server. Der Fokus liegt auf einer nachvollziehbaren Erstinstallation auf neuen Hosts, konsistenten Berechtigungen und klaren Umgebungsvariablen.

---

## Inhaltsverzeichnis

1. Einordnung und Funktionsumfang
2. Voraussetzungen
3. Vorbereitung auf einem frischen System
4. Umgebungsvariablen und Pfad-Konfiguration
5. Erststart
6. Regelbetrieb
7. Erweiterungen (Pakete, Ports, Verzeichnisse)
8. Remote-Zugriff
9. Troubleshooting
10. Details zum Container

---

## 1. Einordnung und Funktionsumfang

- Klassischer Jupyter Notebook Server ohne Token-Login (nur localhost erreichbar)
- Container läuft als nicht privilegierter Benutzer mit frei wählbarer UID/GID
- Persistente Notebooks über ein Host-Volume (Standard: `~/jupyter-work`)
- Automatischer Neustart mittels Docker Restart-Policy
- Minimales Ubuntu 22.04 LTS Basis-Image, tini als Init-Prozess

---

## 2. Voraussetzungen

Auf einem neuen Rechner sollten folgende Punkte erfüllt sein:

- Ubuntu 22.04 LTS oder kompatible Distribution (andere Hosts funktionieren, sind aber nicht getestet)
- Docker Engine ≥ 24 und Docker Compose Plugin (meist Teil der Engine)
- Bash Shell und sudo Zugriff für Systemänderungen
- Optional: dedizierter Linux-Benutzer, der später nur für Jupyter zuständig ist

Docker Installation auf Ubuntu (falls noch nicht vorhanden):

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
# Abmelden/Anmelden oder "newgrp docker" ausführen
```

---

## 3. Vorbereitung auf einem frischen System

1. Repository beziehen:
  ```bash
  mkdir -p ~/Code
  cd ~/Code
  git clone https://github.com/tabee/jupyter-notbook-server.git
  cd jupyter-notbook-server
  ```

2. Optional dedizierten Linux-User anlegen (falls nicht mit dem Hauptaccount gearbeitet werden soll):
  ```bash
  sudo adduser jupyter
  sudo usermod -aG docker jupyter
  ```
  Danach auf diesen Account wechseln (`su - jupyter`) und die folgenden Schritte durchführen.

3. Arbeitsverzeichnis für Notebooks vorbereiten (Standardpfad, anpassbar):
  ```bash
  mkdir -p ~/jupyter-work
  ```

4. Berechtigungen prüfen und angleichen:
  ```bash
  ls -ld ~/jupyter-work
  sudo chown -R $(id -u):$(id -g) ~/jupyter-work
  ```
  Ziel ist, dass Notebook-Dateien vom Host-User geschrieben werden können.

5. Optional zusätzliche Projektpfade anlegen (z. B. getrennte Speicherorte auf größeren Datenträgern) und analog Besitzrechte setzen.

---

## 4. Umgebungsvariablen und Pfad-Konfiguration

Die Compose-Datei nutzt mehrere Variablen. Diese können temporär exportiert oder in einer `.env` Datei neben `docker-compose.yml` persistiert werden.

| Variable | Bedeutung | Standardwert |
|----------|-----------|--------------|
| `USER_ID` | UID des Container-Benutzers | Ausgabe von `id -u` |
| `GROUP_ID` | GID des Container-Benutzers | Ausgabe von `id -g` |
| `PROJECTS_DIR` | Host-Verzeichnis für Notebooks | `${HOME}/jupyter-work` |
| `JUPYTER_PORT` | Host-Port (nur localhost gebunden) | `8888` |
| `CONTAINER_NAME` | Name des Compose-Services | `jupyter-notebook` |

Beispiel: Variablen exportieren und dauerhaft machen:

```bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
export PROJECTS_DIR=${HOME}/jupyter-work
export JUPYTER_PORT=8888

cat <<'EOF' >> ~/.bashrc
# Jupyter Notebook Server (Docker)
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
export PROJECTS_DIR=${HOME}/jupyter-work
export JUPYTER_PORT=8888
EOF
```

Alternativ lässt sich eine `.env` Datei erstellen:

```bash
cat <<'EOF' > .env
USER_ID=$(id -u)
GROUP_ID=$(id -g)
PROJECTS_DIR=${HOME}/jupyter-work
JUPYTER_PORT=8888
CONTAINER_NAME=jupyter-notebook
EOF
```

Die Compose-Datei liest `.env` automatisch ein. Nach Änderungen empfiehlt sich `docker compose down` gefolgt von `docker compose up -d --build`.

---

## 5. Erststart

```bash
cd ~/Code/jupyter-notbook-server
docker compose up -d --build
```

- Der erste Build kann mehrere Minuten dauern (Python-Pakete werden installiert).
- Nach erfolgreichem Start ist der Server unter `http://127.0.0.1:${JUPYTER_PORT}` erreichbar (Standard `8888`).
- Token oder Passwort sind deaktiviert. Der Server ist ausschließlich auf localhost gebunden.

Überprüfung des Containerstatus:

```bash
docker compose ps
docker compose logs --tail 50
```

---

## 6. Regelbetrieb

| Aufgabe | Befehl |
|---------|--------|
| Container starten (ohne Rebuild) | `docker compose up -d` |
| Container stoppen | `docker compose stop` |
| Container entfernen | `docker compose down` |
| Neu bauen | `docker compose up -d --build` |
| Logs verfolgen | `docker compose logs -f` |
| Neustarten | `docker compose restart` |

Es empfiehlt sich, vor `docker compose down -v` ein Backup wichtiger Notebooks anzulegen, da hiermit auch die Daten im Volume gelöscht werden.

---

## 7. Erweiterungen

**Python-Pakete:**

`requirements.txt` anpassen und anschließend den Container neu bauen.

**Weitere Host-Verzeichnisse mounten:**

`PROJECTS_DIR` auf das gewünschte Verzeichnis setzen. Anschließend erneut die Besitzrechte prüfen (`ls -ld <pfad>`). Für mehrere Mounts kann die Compose-Datei erweitert werden.

**Port ändern:**

`export JUPYTER_PORT=8890` oder in `.env` anpassen. Danach `docker compose up -d --build` ausführen und den neuen Port verwenden.

**Dedizierte Nutzerordnung:**

Wer mehrere User auf einem Host hat, sollte für jede Person ein eigenes Notebook-Verzeichnis und entsprechende `.env` Datei pflegen. So bleiben UID/GID klar getrennt.

---

## 8. Remote-Zugriff

Der Server hat keine eigene Authentifizierung. Für externen Zugriff gilt daher mindestens eine der folgenden Varianten:

- SSH-Tunnel:
  ```bash
  ssh -L 8888:127.0.0.1:${JUPYTER_PORT} user@server
  ```
- Reverse Proxy (z. B. Nginx, Traefik) mit HTTPS und Authentifizierung (Basic Auth, OAuth2, SSO)

Exponiere den Port niemals ungeschützt ins Internet.

---

## 9. Troubleshooting

**Permission denied beim Speichern:**

```bash
ls -ld ${PROJECTS_DIR}
sudo chown -R $(id -u):$(id -g) ${PROJECTS_DIR}
docker compose restart
```

**Port bereits belegt:**

```bash
export JUPYTER_PORT=8889
docker compose up -d --build
```

**Docker Daemon nicht erreichbar:**

```bash
sudo systemctl status docker
sudo systemctl start docker
```

**Langsame I/O auf WSL oder Netzwerkshares:**

- Notebooks in ein lokales Linux-Dateisystem legen
- Alternativ rsync/SSHFS nutzen statt Docker-Bind-Mounts

---

## 10. Details zum Container

| Aspekt | Wert |
|--------|------|
| Basis-Image | Ubuntu 22.04 LTS |
| Init-Prozess | tini |
| Container-User | `me` (UID/GID via `USER_ID`/`GROUP_ID`) |
| Arbeitsverzeichnis | `/home/me/jupyter-work` |
| Port | 8888 (nur 127.0.0.1) |
| Restart-Policy | `unless-stopped` |
| Abhängigkeiten | Python Pakete aus `requirements.txt` |

---

## Lizenz

MIT
