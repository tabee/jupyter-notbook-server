# Jupyter Notebook Server (Docker)

Professionelles, sicheres Docker-Setup für den klassischen Jupyter Notebook Server. Optimiert für VPS-Deployment mit Traefik-Integration, WireGuard-Support und konsistenter Konfiguration über .env-Datei.

## Weitere Projekte

- **[mkdocs-projects-server](./mkdocs-projects-server/)** - Ein leeres MkDocs-Projekt für die Dokumentationserstellung mit dem Material-Theme

---

## Inhaltsverzeichnis

1. Einordnung und Funktionsumfang
2. Voraussetzungen
3. Vorbereitung auf einem frischen System
4. Pflicht-Konfiguration (.env Datei)
5. Deployment-Szenarien
6. Erststart
7. Regelbetrieb
8. Erweiterungen (Pakete, Ports, Verzeichnisse)
9. Remote-Zugriff mit Traefik
10. Troubleshooting
11. Details zum Container

---

## 1. Einordnung und Funktionsumfang

- Jupyter Notebook Server mit professionellem Setup
- Container läuft als nicht privilegierter Benutzer mit konfigurierbarer UID/GID
- Persistente Notebooks über ein Host-Volume
- Automatischer Neustart mittels Docker Restart-Policy
- Python 3.12 slim-bookworm Basis-Image, tini als Init-Prozess
- Notebook 7.2.2 mit JupyterLab 4.2.5 und jupyter-server 2.14.2
- Traefik-Integration für sicheren Remote-Zugriff
- **Pflicht .env-Datei** - keine Default-Werte mehr
- Standard-Theme hell, schaltbar auf Dunkelmodus direkt in der UI

---

## 2. Voraussetzungen

Auf einem neuen Rechner sollten folgende Punkte erfüllt sein:

- Ubuntu 22.04 LTS oder kompatible Distribution (andere Hosts funktionieren, sind aber nicht getestet)
- Docker Engine ≥ 24 und Docker Compose Plugin (meist Teil der Engine)
- Bash Shell und sudo Zugriff für Systemänderungen
- Optional: WireGuard für sicheren VPN-Zugriff
- Optional: Traefik Reverse Proxy für HTTPS und externe Erreichbarkeit

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

## 4. Pflicht-Konfiguration (.env Datei)

**WICHTIG:** Eine `.env` Datei ist ab sofort **Pflicht**. Es gibt keine Default-Werte mehr.

1. Kopiere die Beispiel-Konfiguration:
   ```bash
   cp .env.example .env
   ```

2. Passe die `.env` Datei an deine Umgebung an:
   ```bash
   nano .env
   ```

3. Setze mindestens diese Variablen:

| Variable | Bedeutung | Beispiel |
|----------|-----------|----------|
| `USER_ID` | UID des Container-Benutzers | `1000` (verwende `id -u`) |
| `GROUP_ID` | GID des Container-Benutzers | `1000` (verwende `id -g`) |
| `PROJECTS_DIR` | **Absoluter** Host-Verzeichnis für Notebooks | `/home/youruser/jupyter-work` |
| `JUPYTER_PORT` | Host-Port (nur localhost gebunden ohne Traefik) | `8888` |
| `CONTAINER_NAME` | Name des Docker-Containers | `jupyter-notebook` |
| `JUPYTER_DOMAIN` | Domain für Traefik (nur bei VPS-Deployment) | `jupyter.example.com` |
| `TRAEFIK_NETWORK` | Traefik Docker-Netzwerk (nur bei VPS-Deployment) | `traefik_proxy` |
| `TRAEFIK_NETWORK_EXTERNAL` | Ob Traefik-Netzwerk extern ist (nur bei VPS) | `true` |

Beispiel `.env` Datei:

```bash
USER_ID=1000
GROUP_ID=1000
PROJECTS_DIR=/home/youruser/jupyter-work
JUPYTER_PORT=8888
CONTAINER_NAME=jupyter-notebook
JUPYTER_DOMAIN=jupyter.example.com
TRAEFIK_NETWORK=traefik_proxy
TRAEFIK_NETWORK_EXTERNAL=true
```

**Hinweise:**
- Verwende **absolute Pfade** für `PROJECTS_DIR`
- Der angegebene Benutzer benötigt Schreibrechte auf `PROJECTS_DIR`
- Die `.env` Datei ist in `.gitignore` und wird nicht committed

---

## 5. Deployment-Szenarien

### Szenario A: Lokaler Zugriff (localhost only)

Für Entwicklung auf einem lokalen Rechner oder Server mit SSH-Tunnel:

```bash
# .env Konfiguration
JUPYTER_PORT=8888
# In docker-compose.yml: Port-Mapping bleibt aktiv
```

Zugriff: `http://127.0.0.1:8888`

### Szenario B: VPS mit Traefik (empfohlen für Produktion)

Für professionelle VPS-Deployments mit HTTPS und Authentifizierung:

1. **Traefik Setup** (falls noch nicht vorhanden):
   ```bash
   # Traefik Docker-Netzwerk erstellen
   docker network create traefik_proxy
   ```

2. **docker-compose.yml anpassen**:
   ```yaml
   # Port-Mapping auskommentieren (Zeile 13)
   # - "127.0.0.1:${JUPYTER_PORT}:8888"
   
   # Traefik Labels einkommentieren (Zeilen 20-28)
   ```

3. **.env konfigurieren**:
   ```bash
   JUPYTER_DOMAIN=jupyter.yourdomain.com
   TRAEFIK_NETWORK=traefik_proxy
   TRAEFIK_NETWORK_EXTERNAL=true  # Weil das Netzwerk extern erstellt wurde
   ```

4. **Basic Auth generieren** (empfohlen):
   ```bash
   # htpasswd installieren
   sudo apt-get install apache2-utils
   
   # Passwort-Hash generieren
   echo $(htpasswd -nb admin yourpassword) | sed 's/\$/\$\$/g'
   ```
   
   Hash in docker-compose.yml eintragen (Label `jupyter-auth.basicauth.users`)

5. **DNS konfigurieren**: A-Record für `jupyter.yourdomain.com` auf VPS-IP

### Szenario C: VPS mit WireGuard + Traefik

Für maximale Sicherheit kombiniere WireGuard VPN mit Traefik:

1. **WireGuard installieren und konfigurieren**:
   ```bash
   sudo apt-get install wireguard
   # Konfiguration nach WireGuard-Dokumentation
   ```

2. **Traefik nur über WireGuard erreichbar machen**:
   - Traefik lauscht nur auf WireGuard-Interface (z.B. `wg0`)
   - Jupyter nur über VPN erreichbar

3. **.env wie Szenario B** konfigurieren

---

## 6. Erststart

1. **Arbeitsverzeichnis für Notebooks vorbereiten**:
   ```bash
   mkdir -p /home/youruser/jupyter-work
   sudo chown -R $(id -u):$(id -g) /home/youruser/jupyter-work
   ```

2. **Container erstmals starten**:
   ```bash
   cd ~/Code/jupyter-notebook-server
   docker compose up -d --build
   ```

- Der erste Build kann mehrere Minuten dauern (Python-Pakete werden installiert).
- Nach erfolgreichem Start ist der Server unter `http://127.0.0.1:${JUPYTER_PORT}` erreichbar (bei lokalem Setup).
- Bei Traefik-Setup ist der Server unter `https://${JUPYTER_DOMAIN}` erreichbar.

Überprüfung des Containerstatus:

```bash
docker compose ps
docker compose logs --tail 50
```

---

## 7. Regelbetrieb

| Aufgabe | Befehl |
|---------|--------|
| Container starten (ohne Rebuild) | `docker compose up -d` |
| Container stoppen | `docker compose stop` |
| Container entfernen | `docker compose down` |
| Neu bauen | `docker compose up -d --build` |
| Logs verfolgen | `docker compose logs -f` |
| Neustarten | `docker compose restart` |

`docker compose down -v` entfernt benannte Docker-Volumes. Da dieses Setup ein Bind-Mount auf `${PROJECTS_DIR}` nutzt, bleiben dort abgelegte Notebooks erhalten. Falls zusätzliche Volumes konfiguriert wurden, sollten diese vor `-v` gesichert werden.

---

## 8. Erweiterungen

**Python-Pakete:**

`requirements.txt` anpassen und anschließend den Container neu bauen.

**Weitere Host-Verzeichnisse mounten:**

Für mehrere Mounts kann die Compose-Datei erweitert werden:

```yaml
volumes:
  - ${PROJECTS_DIR}:/home/jupyter/jupyter-work
  - /path/to/data:/home/jupyter/data:ro  # Read-only data mount
```

**Port ändern:**

In `.env` anpassen: `JUPYTER_PORT=8890`. Danach `docker compose up -d --build` ausführen.

**Theme anpassen (Notebook 7):**

Notebook 7 basiert auf der JupyterLab-Oberfläche. Das Theme wechselst du direkt im Browser unter *Settings → JupyterLab Theme*. Für den Dunkelmodus wähle z. B. **JupyterLab Dark**.

---

## 9. Remote-Zugriff mit Traefik

### Traefik-Integration aktivieren

1. **docker-compose.yml bearbeiten**:
   ```bash
   nano docker-compose.yml
   ```

2. **Port-Mapping auskommentieren** (Zeilen 12-13):
   ```yaml
   # Bind only to localhost for security (comment out when using Traefik)
   # - "127.0.0.1:${JUPYTER_PORT}:8888"
   ```

3. **Traefik-Labels einkommentieren** (Zeilen 21-29):
   ```yaml
   labels:
     traefik.enable: "true"
     traefik.http.routers.jupyter.rule: "Host(`${JUPYTER_DOMAIN}`)"
     traefik.http.routers.jupyter.entrypoints: "websecure"
     traefik.http.routers.jupyter.tls.certresolver: "letsencrypt"
     traefik.http.services.jupyter.loadbalancer.server.port: "8888"
     traefik.http.routers.jupyter.middlewares: "jupyter-auth"
     traefik.http.middlewares.jupyter-auth.basicauth.users: "admin:$$apr1$$..."
   ```

4. **Basic Auth Passwort generieren**:
   ```bash
   echo $(htpasswd -nb admin yourpassword) | sed 's/\$/\$\$/g'
   ```
   
   Ausgabe in Label `jupyter-auth.basicauth.users` einfügen.

5. **Container neu starten**:
   ```bash
   docker compose down
   docker compose up -d --build
   ```

### Sicherheitshinweise

- **Niemals** ohne Authentifizierung ins Internet exponieren
- Verwende **immer** HTTPS (Traefik mit Let's Encrypt)
- Basic Auth ist Minimum, OAuth2/SSO für mehrere Benutzer empfohlen
- WireGuard VPN für zusätzliche Sicherheit

### Alternative: SSH-Tunnel

Ohne Traefik kannst du SSH-Port-Forwarding verwenden:

```bash
ssh -L 8888:127.0.0.1:8888 user@vps-ip
```

Dann lokal auf `http://127.0.0.1:8888` zugreifen.

---

## 10. Troubleshooting

**Permission denied beim Speichern:**

```bash
ls -ld ${PROJECTS_DIR}
sudo chown -R $(id -u):$(id -g) ${PROJECTS_DIR}
docker compose restart
```

**Port bereits belegt:**

```bash
# In .env Datei ändern
JUPYTER_PORT=8889
# Dann neu starten
docker compose up -d --build
```

**Fehlende .env Datei:**

```bash
cp .env.example .env
nano .env  # Werte anpassen
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

## 11. Details zum Container

| Aspekt | Wert |
|--------|------|
| Basis-Image | python:3.12-slim-bookworm |
| Init-Prozess | tini |
| Container-User | `jupyter` (UID/GID via `USER_ID`/`GROUP_ID`) |
| Arbeitsverzeichnis | `/home/jupyter/jupyter-work` |
| Virtualenv | `/home/jupyter/venv` |
| Port | 8888 (nur 127.0.0.1 ohne Traefik) |
| Restart-Policy | `unless-stopped` |
| Jupyter Notebook Version | 7.2.2 (mit JupyterLab 4.2.5, jupyter-server 2.14.2) |
| Abhängigkeiten | Python Pakete aus `requirements.txt` |
| Warnungsfilter | `PYTHONWARNINGS=ignore::jupyter_events.JupyterEventsVersionWarning` |

---

## Lizenz

MIT
