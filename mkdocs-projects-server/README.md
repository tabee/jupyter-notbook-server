# MkDocs Projects Server

Ein leeres MkDocs-Projekt für die Dokumentationserstellung.

## Beschreibung

Dies ist ein minimales MkDocs-Projekt-Setup mit dem Material-Theme, das als Ausgangspunkt für die Erstellung von Projektdokumentationen dient.

## Voraussetzungen

- Python 3.8 oder höher
- pip (Python Paketmanager)

## Installation

1. Installieren Sie die erforderlichen Python-Pakete:

```bash
pip install -r requirements.txt
```

## Verwendung

### Lokale Entwicklung

Starten Sie den MkDocs-Entwicklungsserver:

```bash
cd mkdocs-projects-server
mkdocs serve
```

Die Dokumentation ist dann unter `http://127.0.0.1:8000` verfügbar.

### Dokumentation erstellen

Erstellen Sie die statische Website:

```bash
cd mkdocs-projects-server
mkdocs build
```

Die generierte Website befindet sich im `site/` Verzeichnis.

## Projektstruktur

```
mkdocs-projects-server/
├── docs/
│   └── index.md          # Startseite der Dokumentation
├── mkdocs.yml            # MkDocs-Konfiguration
├── requirements.txt      # Python-Abhängigkeiten
└── README.md            # Diese Datei
```

## Konfiguration

Die Hauptkonfiguration befindet sich in `mkdocs.yml`. Hier können Sie:

- Site-Informationen anpassen
- Theme-Einstellungen ändern
- Navigation konfigurieren
- Plugins hinzufügen
- Markdown-Erweiterungen aktivieren

## Dokumentation hinzufügen

1. Erstellen Sie neue Markdown-Dateien im `docs/` Verzeichnis
2. Aktualisieren Sie die `nav`-Sektion in `mkdocs.yml`, um die neuen Seiten einzubinden
3. Der Entwicklungsserver aktualisiert sich automatisch bei Dateiänderungen

## Lizenz

MIT
