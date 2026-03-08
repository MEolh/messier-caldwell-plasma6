# Messier & Caldwell Visible Objects — KDE Plasma 6 Widget

A KDE Plasma 6 widget that shows in real time which **Messier** and **Caldwell** deep-sky objects are currently above the horizon from your location.

![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue)
![License](https://img.shields.io/badge/license-GPL--2.0+-green)

## Features

- **219 objects**: full Messier (110) + Caldwell (109) catalogs
- **Real-time altitude calculation** using accurate astronomical algorithms (Meeus)
- **Configurable location**: type any city name — coordinates resolved via OpenStreetMap/Nominatim
- **Configurable minimum altitude** (default 15°)
- **Catalog filter**: All / Messier only / Caldwell only
- **Color-coded altitude**: green >60°, lime >40°, yellow >25°, orange >15°
- **Object detail popup**: real DSS photo (Aladin/CDS) with adaptive FOV, links to SIMBAD and Aladin
- **Correct object types**: galaxies, globular clusters, open clusters, planetary nebulae, diffuse nebulae
- **Localized UI**: Italian and English included
- **Auto-refresh** every 60 seconds

## Requirements

- KDE Plasma 6.0+
- **Internet connection** required for:
  - Location search (OpenStreetMap/Nominatim)
  - DSS object images (Aladin/CDS)

  The catalog data and altitude calculations work fully offline — only the location search and images need network access.

## Installation

### From KDE Store (.plasmoid)

```bash
tar -xzf messier-widget-plasma6.tar.gz
cd org.kde.plasma.messier_caldwell
bash install.sh
```

### From GitHub

```bash
git clone https://github.com/MEolh/messier-caldwell-plasma6.git
cd messier-caldwell-plasma6
bash install.sh
```

Right-click desktop → Add Widgets → search "Messier"

## Customizing the icon

Replace `contents/ui/telescope.svg` with your own SVG before running `install.sh`.

## Translating

Add `contents/locale/<lang>/LC_MESSAGES/plasma_org.kde.plasma.messier_caldwell.po` based on the English template in `contents/locale/en/`.

## Credits

- Astronomical algorithms: Jean Meeus, *Astronomical Algorithms*
- DSS images: [Aladin / CDS Strasbourg](https://aladin.cds.unistra.fr)
- Location search: [Nominatim / OpenStreetMap](https://nominatim.openstreetmap.org)
- Developed by Michele Machetti — [AMSA Osservatorio Astronomico e Meteorologico di Roselle](https://www.amsagrosseto.com/)

---

# Widget Oggetti Visibili Messier & Caldwell — KDE Plasma 6

Widget per KDE Plasma 6 che mostra in tempo reale quali oggetti del catalogo **Messier** e **Caldwell** sono visibili sopra l'orizzonte dalla tua posizione.

## Caratteristiche

- **219 oggetti**: catalogo completo Messier (110) + Caldwell (109)
- **Calcolo altezza in tempo reale** con algoritmi astronomici accurati (Meeus)
- **Posizione configurabile**: digita il nome di qualsiasi città — coordinate risolte via OpenStreetMap/Nominatim
- **Altezza minima configurabile** (default 15°)
- **Filtro catalogo**: Tutti / solo Messier / solo Caldwell
- **Colori per altitudine**: verde >60°, verde-lime >40°, giallo >25°, arancione >15°
- **Popup dettaglio oggetto**: foto DSS reale (Aladin/CDS) con FOV adattivo, link a SIMBAD e Aladin
- **Tipi oggetti corretti**: galassie, globulari, aperti, nebulose planetarie, nebulose diffuse
- **UI localizzata**: italiano e inglese inclusi
- **Aggiornamento automatico** ogni 60 secondi

## Requisiti

- KDE Plasma 6.0+
- **Connessione internet** necessaria per:
  - Ricerca località (OpenStreetMap/Nominatim)
  - Immagini DSS degli oggetti (Aladin/CDS)

  Il catalogo e il calcolo delle altezze funzionano completamente offline — solo la ricerca località e le immagini richiedono la rete.

## Installazione

### Da KDE Store (.plasmoid)

```bash
tar -xzf messier-widget-plasma6.tar.gz
cd org.kde.plasma.messier_caldwell
bash install.sh
```

### Da GitHub

```bash
git clone https://github.com/MEolh/messier-caldwell-plasma6.git
cd messier-caldwell-plasma6
bash install.sh
```

Tasto destro desktop → Aggiungi widget → cerca "Messier"
