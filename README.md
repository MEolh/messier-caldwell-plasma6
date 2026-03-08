# Messier & Caldwell Visible Objects — KDE Plasma 6 Widget

A KDE Plasma 6 widget that shows in real time which **Messier** and **Caldwell** deep-sky objects are currently above the horizon from your location.

![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue)
![License](https://img.shields.io/badge/license-GPL--2.0+-green)

## Features

- **219 objects**: full Messier (110) + Caldwell (109) catalogs
- **Real-time altitude calculation** using accurate astronomical algorithms (Meeus)
- **Configurable location**: type any city name — coordinates resolved via OpenStreetMap/Nominatim, no API key required
- **Configurable minimum altitude** (default 15°)
- **Catalog filter**: All / Messier only / Caldwell only
- **Color-coded altitude**: green >60°, lime >40°, yellow >25°, orange >15°
- **Object detail popup**: DSS real photo (Aladin/CDS) with adaptive FOV, links to SIMBAD and Aladin
- **Correct object types**: galaxies, globular clusters, open clusters, planetary nebulae, diffuse nebulae
- **i18n**: Italian and English included, easily extensible
- **Auto-refresh** every 60 seconds

## Installation

```bash
tar -xzf messier-widget-plasma6.tar.gz
cd messier-widget-p6/
bash install.sh
```

Right-click desktop → Add Widgets → search "Messier"

**Requirements**: KDE Plasma 6.0+, internet connection (location search + DSS images)

## Customizing the icon

Replace `contents/ui/telescope.svg` before running `install.sh`.

## Translating

Add `contents/locale/<lang>/LC_MESSAGES/org.amsa.messier.visible.po` based on the English template.

## Credits

- Astronomical algorithms: Jean Meeus, *Astronomical Algorithms*
- DSS images: [Aladin / CDS Strasbourg](https://aladin.cds.unistra.fr)
- Location search: [Nominatim / OpenStreetMap](https://nominatim.openstreetmap.org)
- Developed at [AMSA Osservatorio Astronomico e Meteorologico di Roselle](https://www.amsa-astronomia.it)

---

# Widget Oggetti Visibili Messier & Caldwell — KDE Plasma 6

Widget per KDE Plasma 6 che mostra in tempo reale quali oggetti del catalogo **Messier** e **Caldwell** sono visibili dalla tua posizione.

## Installazione

```bash
tar -xzf messier-widget-plasma6.tar.gz
cd messier-widget-p6/
bash install.sh
```

Tasto destro desktop → Aggiungi widget → cerca "Messier"
