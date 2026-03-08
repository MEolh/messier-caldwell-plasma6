import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

import "../../contents/code/astro.js" as Astro
import "../../contents/code/catalogo.js" as Cat

PlasmoidItem {
    id: root

    // ---------------------------------------------------------------
    // Traduzione inline — rileva lingua di sistema senza dipendenze
    // ---------------------------------------------------------------
    property string _lang: Qt.locale().name.substring(0, 2)  // "it", "en", "de"...

    readonly property var _tr: ({
        "it": {
            "Visible Objects":             "Oggetti Visibili",
            "Catalog:":                    "Catalogo:",
            "All":                         "Tutti",
            "Min alt:":                    "Min alt:",
            "Object":                      "Oggetto",
            "Type":                        "Tipo",
            "Const.":                      "Cost.",
            "No visible objects above":    "Nessun oggetto visibile\nsopra",
            "Type:":                       "Tipo:",
            "Constellation:":              "Costellazione:",
            "Altitude:":                   "Altezza:",
            "Magnitude:":                  "Magnitudine:",
            "Azimuth:":                    "Azimuth:",
            "App. size:":                  "Dim. app.:",
            "Constellation:":              "Costellazione:",
            "Size:":                       "Estensione:",
            "Magnitude:":                  "Magnitudine:",
            "DSS image · Adaptive FOV":    "Immagine DSS · FOV adattivo"
        }
    })

    function tr(key) {
        var lang = root._lang;
        if (_tr[lang] && _tr[lang][key] !== undefined)
            return _tr[lang][key];
        return key;  // fallback: mostra la chiave (inglese)
    }

    // Stato ricerca località
    property string locationStatus:  "ok"  // "", "searching", "ok", "error"

    property var    visibleObjects: []
    property string lastUpdate:     ""
    property string filterCatalog:  "ALL"

    property bool   popupVisible:   false
    property var    popupObj:       null
    property string simbadImageUrl:  ""

    preferredRepresentation: fullRepresentation
    implicitWidth:  600
    implicitHeight: 520

    // ---------------------------------------------------------------
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: refreshObjects()
    }

    // Proprietà di lavoro — aggiornate prima del refresh per evitare
    // problemi di timing con Plasmoid.configuration
    property double _lat: 42.75
    property double _lon: 11.15
    property double _alt: 15.0

    function refreshObjects() {
        var now = new Date();
        lastUpdate = Qt.formatTime(now, "HH:mm:ss");
        var catalog = filterCatalog === "M" ? Cat.MESSIER
                    : filterCatalog === "C" ? Cat.CALDWELL
                    : Cat.FULL_CATALOG;
        visibleObjects = [];
        visibleObjects = Astro.getVisibleObjects(catalog, root._lat, root._lon, root._alt, now);
    }

    // ---------------------------------------------------------------
    // Suffissi disambiguation astronomici da provare in ordine
    // ---------------------------------------------------------------
    // ---------------------------------------------------------------
    // SIMBAD + DSS thumbnail per tutti gli oggetti (M e C)
    // ---------------------------------------------------------------
    function simbadIdent(objName) {
        // Per i Messier: SIMBAD accetta "M 31", "M 1" ecc.
        var ch = objName.charAt(0);
        if (ch === "M") return "M " + objName.substring(1);
        // Per i Caldwell: usa il vero NGC/IC dalla mappa
        var ngc = Cat.WIKI_TITLES[objName];
        if (ngc) return ngc;
        return objName;
    }

    function loadSimbadData(objName) {
        simbadImageUrl = "";
        if (!root.popupObj) return;

        // FOV adattivo dalla dimensione angolare dell'oggetto (arcmin → gradi, padding 2.5x)
        var sizeDeg = (root.popupObj.size / 60.0) * 2.5;
        if (sizeDeg < 0.05) sizeDeg = 0.05;  // minimo per planetarie piccole
        if (sizeDeg > 4.0)  sizeDeg = 4.0;   // massimo ragionevole

        var fov = sizeDeg.toFixed(4);

        // Ident SIMBAD: "M 42", "NGC 6543" ecc. — hips2fits lo risolve lato server
        // Questo evita qualsiasi problema di coordinate imprecise nel catalogo locale
        var ident = simbadIdent(objName);

        simbadImageUrl = "https://alaskybis.cds.unistra.fr/hips-image-services/hips2fits"
                       + "?hips=CDS%2FP%2FDSS2%2Fcolor"
                       + "&width=300&height=300"
                       + "&fov=" + fov
                       + "&object=" + encodeURIComponent(ident)
                       + "&projection=TAN"
                       + "&format=png";
    }

    // Cerca coordinate via Nominatim (OpenStreetMap) — nessuna API key richiesta
    function searchLocation(query) {
        if (query.trim() === "") return;
        root.locationStatus = "searching";

        var req = new XMLHttpRequest();
        var url = "https://nominatim.openstreetmap.org/search"
                + "?q=" + encodeURIComponent(query.trim())
                + "&format=json&limit=1"
                + "&accept-language=it";

        req.onreadystatechange = function() {
            if (req.readyState !== 4) return;
            if (req.status === 200) {
                try {
                    var results = JSON.parse(req.responseText);
                    if (results.length > 0) {
                        var r = results[0];
                        var lat = parseFloat(r.lat);
                        var lon = parseFloat(r.lon);
                        // Aggiorna le property di lavoro PRIMA del refresh
                        root._lat = lat;
                        root._lon = lon;
                        // Salva anche in configurazione per la persistenza
                        Plasmoid.configuration.obsLat       = lat;
                        Plasmoid.configuration.obsLon       = lon;
                        Plasmoid.configuration.locationName = r.display_name.split(",")[0]
                                                              + ", " + r.display_name.split(",").slice(-2,-1)[0].trim();
                        root.locationStatus = "ok";
                        root.refreshObjects();
                    } else {
                        root.locationStatus = "error";
                    }
                } catch(e) {
                    root.locationStatus = "error";
                }
            } else {
                root.locationStatus = "error";
            }
        };
        req.open("GET", url);
        req.setRequestHeader("User-Agent", "MessierCaldwellWidget/1.0 KDE Plasma (github.com/MEolh)");
        req.send();
    }

    Component.onCompleted: {
        // Carica valori salvati, con fallback ai default
        root._lat = Plasmoid.configuration.obsLat  || 42.75;
        root._lon = Plasmoid.configuration.obsLon  || 11.15;
        root._alt = Plasmoid.configuration.minAlt  || 15.0;
        // Scrivi i default se erano 0
        if (Plasmoid.configuration.minAlt === 0) {
            Plasmoid.configuration.minAlt = 15;
            root._alt = 15;
        }
        minAltInput.text = root._alt.toFixed(0);
        refreshObjects();
    }

    // ================================================================
    // FULL REPRESENTATION
    // ================================================================
    fullRepresentation: Item {
        Layout.minimumWidth:    440
        Layout.minimumHeight:   380
        Layout.preferredWidth:  600
        Layout.preferredHeight: 560

        Rectangle {
            anchors.fill: parent
            color: "#0a0a12"
            radius: 8
        }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 10
            spacing: 6

            // HEADER
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    source: "../../contents/ui/telescope.svg"
                    width: 28; height: 28
                    smooth: true
                }
                Text {
                    text: tr("Visible Objects")
                    color: "#e8c87a"
                    font.pixelSize: 15; font.bold: true; font.family: "monospace"
                    verticalAlignment: Text.AlignVCenter
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 44; height: 22; radius: 11
                    color:  visibleObjects.length > 0 ? "#1a3a1a" : "#3a1a1a"
                    border.color: visibleObjects.length > 0 ? "#4aaa4a" : "#aa4a4a"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: visibleObjects.length
                        color: visibleObjects.length > 0 ? "#88ee88" : "#ee8888"
                        font.pixelSize: 12; font.bold: true
                    }
                }
                Text {
                    text: lastUpdate
                    color: "#6688aa"; font.pixelSize: 10; font.family: "monospace"
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: rMouse.containsMouse ? "#1e3a5a" : "#0f1f33"
                    border.color: "#2255aa"; border.width: 1
                    Text { anchors.centerIn: parent; text: "⟳"; color: "#4488dd"; font.pixelSize: 14 }
                    MouseArea {
                        id: rMouse; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshObjects()
                    }
                }
            }

            // LOCALITÀ
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "📍"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    Layout.fillWidth: true; height: 22; radius: 3
                    color: "#0a1525"; border.width: 1
                    border.color: locInput.activeFocus ? "#4488dd"
                                : root.locationStatus === "ok"    ? "#336633"
                                : root.locationStatus === "error" ? "#663333"
                                : "#223344"

                    TextInput {
                        id: locInput
                        anchors.fill: parent; anchors.margins: 3
                        text: Plasmoid.configuration.locationName
                        color: "#ccddee"; font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true
                        Keys.onReturnPressed: root.searchLocation(text)
                        Keys.onEnterPressed:  root.searchLocation(text)
                    }
                }

                // Pulsante cerca
                Rectangle {
                    width: 22; height: 22; radius: 3
                    color: locSearchMouse.containsMouse ? "#1e3a5a" : "#0f1f33"
                    border.color: "#2255aa"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: root.locationStatus === "searching" ? "…" : "🔍"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: locSearchMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.searchLocation(locInput.text)
                    }
                }

                // Coordinate attuali
                Text {
                    text: Plasmoid.configuration.obsLat.toFixed(2) + "° "
                        + Plasmoid.configuration.obsLon.toFixed(2) + "°"
                    color: root.locationStatus === "ok"    ? "#44aa44"
                         : root.locationStatus === "error" ? "#aa6644"
                         : "#445566"
                    font.pixelSize: 9; font.family: "monospace"
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // CONTROLLI
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text { text: tr("Catalog:"); color: "#6688aa"; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                Repeater {
                    model: [{label:tr("All"),val:"ALL"},{label:"Messier",val:"M"},{label:"Caldwell",val:"C"}]
                    delegate: Rectangle {
                        width: 60; height: 20; radius: 3
                        color:  root.filterCatalog === modelData.val ? "#1e3a5a" : "#0f1520"
                        border.color: root.filterCatalog === modelData.val ? "#4488dd" : "#223344"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent; text: modelData.label
                            color: root.filterCatalog === modelData.val ? "#88ccff" : "#4477aa"
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.filterCatalog = modelData.val; root.refreshObjects() }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Text { text: tr("Min alt:"); color: "#6688aa"; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                Rectangle {
                    width: 36; height: 20; radius: 3
                    color: "#0f1520"; border.color: "#223344"; border.width: 1
                    TextInput {
                        id: minAltInput
                        anchors.fill: parent; anchors.margins: 2
                        text: "15"
                        color: "#e8c87a"; font.pixelSize: 11; font.family: "monospace"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        validator: IntValidator { bottom: 0; top: 89 }
                        onEditingFinished: {
                            var v = parseInt(text);
                            if (!isNaN(v) && v >= 0 && v < 90) {
                                root._alt = v;
                                Plasmoid.configuration.minAlt = v;
                                root.refreshObjects();
                            }
                        }
                    }
                }
                Text { text: "°"; color: "#6688aa"; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
            }

            // INTESTAZIONE TABELLA
            Rectangle {
                Layout.fillWidth: true; height: 22
                color: "#0f1f33"; radius: 3
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 14
                    spacing: 0
                    Text { text: tr("Object");   color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 52 }
                    Text { text: "T";         color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 22 }
                    Text { text: tr("Type");      color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true }
                    Text { text: tr("Const.");     color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 34 }
                    Text { text: "Alt°";      color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                    Text { text: "Mag";       color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                    Text { text: "Dim'";      color: "#4488dd"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                }
            }

            // LISTA
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: objectList
                    anchors.fill: parent
                    clip: true
                    model: root.visibleObjects
                    spacing: 1

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 8
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.visibleObjects.length === 0
                        text: tr("No visible objects above") + " " + Plasmoid.configuration.minAlt.toFixed(0) + "°"
                        color: "#446688"; font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter; lineHeight: 1.4
                    }

                    delegate: Rectangle {
                        width: objectList.width - 10
                        height: 22
                        color: rowArea.containsMouse ? "#1a2e48"
                             : (index % 2 === 0 ? "#0c1520" : "#0a1018")
                        radius: 2

                        Rectangle {
                            width: 3; height: parent.height; anchors.left: parent.left; radius: 1
                            color: {
                                var a = modelData.alt;
                                if (a >= 60) return "#44ee44";
                                if (a >= 40) return "#aaee44";
                                if (a >= 25) return "#eebb44";
                                return "#ee7744";
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 6
                            spacing: 0

                            Text {
                                text: modelData.name
                                color: modelData.catalog === "M" ? "#88ccff" : "#ffcc88"
                                font.pixelSize: 11; font.bold: true; font.family: "monospace"
                                Layout.preferredWidth: 52
                            }
                            Text { text: modelData.typeIcon; font.pixelSize: 12; Layout.preferredWidth: 22 }
                            Text {
                                text: modelData.type; color: "#aabbcc"; font.pixelSize: 10
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.constellation; color: "#667788"
                                font.pixelSize: 10; font.family: "monospace"; Layout.preferredWidth: 34
                            }
                            Text {
                                text: modelData.alt.toFixed(1) + "°"
                                color: {
                                    var a = modelData.alt;
                                    if (a >= 60) return "#44ee44";
                                    if (a >= 40) return "#aaee44";
                                    if (a >= 25) return "#eebb44";
                                    return "#ee7744";
                                }
                                font.pixelSize: 11; font.bold: true; font.family: "monospace"
                                horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 40
                            }
                            Text {
                                text: modelData.magnitude.toFixed(1); color: "#99aabb"
                                font.pixelSize: 10; font.family: "monospace"
                                horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 32
                            }
                            Text {
                                text: modelData.size + "'"
                                color: "#778899"; font.pixelSize: 10; font.family: "monospace"
                                horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 34
                            }
                        }

                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            visible: rowArea.containsMouse
                            text: "ℹ"; color: "#4488dd"; font.pixelSize: 10
                        }

                        MouseArea {
                            id: rowArea; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.popupObj     = modelData;
                                root.popupVisible = true;
                                root.loadSimbadData(modelData.name);
                            }
                        }
                    }
                }
            }

            // FOOTER
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Text {
                    text: "📍 " + Plasmoid.configuration.obsLat.toFixed(3) + "°N  " + Plasmoid.configuration.obsLon.toFixed(3) + "°E"
                    color: "#445566"; font.pixelSize: 10; font.family: "monospace"
                }
                Item { Layout.fillWidth: true }
                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            {col:"#44ee44",lab:">60°"},{col:"#aaee44",lab:">40°"},
                            {col:"#eebb44",lab:">25°"},{col:"#ee7744",lab:">15°"}
                        ]
                        delegate: Row {
                            spacing: 3
                            Rectangle {
                                width: 6; height: 6; radius: 3; color: modelData.col
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text { text: modelData.lab; color: "#445566"; font.pixelSize: 9 }
                        }
                    }
                }
            }
        }

        // ============================================================
        // POPUP SCHEDA OGGETTO
        // ============================================================
        Rectangle {
            visible: root.popupVisible && root.popupObj !== null
            anchors.fill: parent
            color: "#0d1220"; radius: 8
            border.color: "#2244aa"; border.width: 1
            z: 10

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 10

                // Titolo
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.popupObj ? (root.popupObj.typeIcon + "  " + root.popupObj.name) : ""
                        color: root.popupObj && root.popupObj.catalog === "M" ? "#88ccff" : "#ffcc88"
                        font.pixelSize: 18; font.bold: true; font.family: "monospace"
                        verticalAlignment: Text.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: closeMouse.containsMouse ? "#3a1a1a" : "#1a0a0a"
                        border.color: "#aa4444"; border.width: 1
                        Text { anchors.centerIn: parent; text: "✕"; color: "#ee6666"; font.pixelSize: 14 }
                        MouseArea {
                            id: closeMouse; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.popupVisible = false
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#223355" }

                // Dati tecnici
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4; rowSpacing: 4; columnSpacing: 16

                    Text { text: tr("Type:");          color: "#6688aa"; font.pixelSize: 10 }
                    Text { text: root.popupObj ? root.popupObj.type : ""; color: "#ccddee"; font.pixelSize: 10; Layout.fillWidth: true }
                    Text { text: tr("Constellation:"); color: "#6688aa"; font.pixelSize: 10 }
                    Text { text: root.popupObj ? root.popupObj.constellation : ""; color: "#ccddee"; font.pixelSize: 10 }

                    Text { text: tr("Altitude:");    color: "#6688aa"; font.pixelSize: 10 }
                    Text {
                        text: root.popupObj ? root.popupObj.alt.toFixed(1) + "°" : ""
                        color: {
                            if (!root.popupObj) return "#ccddee";
                            var a = root.popupObj.alt;
                            if (a >= 60) return "#44ee44";
                            if (a >= 40) return "#aaee44";
                            if (a >= 25) return "#eebb44";
                            return "#ee7744";
                        }
                        font.pixelSize: 10; font.bold: true
                    }
                    Text { text: tr("Magnitude:"); color: "#6688aa"; font.pixelSize: 10 }
                    Text { text: root.popupObj ? root.popupObj.magnitude.toFixed(1) : ""; color: "#ccddee"; font.pixelSize: 10 }

                    Text { text: tr("Azimuth:");   color: "#6688aa"; font.pixelSize: 10 }
                    Text { text: root.popupObj ? root.popupObj.az.toFixed(1) + "°" : ""; color: "#ccddee"; font.pixelSize: 10 }
                    Text { text: tr("App. size:"); color: "#6688aa"; font.pixelSize: 10 }
                    Text { text: root.popupObj ? root.popupObj.size + "'" : ""; color: "#ccddee"; font.pixelSize: 10 }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#223355" }

                // Immagine + info
                RowLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12

                    // Immagine DSS da Aladin/CDS con FOV adattivo
                    Rectangle {
                        width: 180; height: 180
                        color: "#060d1a"; radius: 6
                        border.color: "#1a3366"; border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent; anchors.margins: 2
                            source: root.simbadImageUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true; asynchronous: true
                        }

                        // Overlay "caricamento" mentre l'immagine arriva
                        Text {
                            anchors.centerIn: parent
                            visible: root.simbadImageUrl !== "" &&
                                     parent.children[0].status === Image.Loading
                            text: "⟳"; color: "#334466"; font.pixelSize: 24
                        }
                    }

                    // Pannello info testuale dal catalogo
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        spacing: 6

                        // NGC/IC corrispondente
                        Text {
                            visible: root.popupObj !== null
                            text: {
                                if (!root.popupObj) return "";
                                var ngc = Cat.WIKI_TITLES[root.popupObj.name];
                                return ngc ? ngc : root.popupObj.name;
                            }
                            color: "#7799bb"; font.pixelSize: 11; font.bold: true
                        }

                        // Tipo esteso
                        Text {
                            visible: root.popupObj !== null
                            text: root.popupObj ? root.popupObj.type : ""
                            color: "#99bbcc"; font.pixelSize: 11
                        }

                        // Costellazione per esteso
                        Text {
                            visible: root.popupObj !== null
                            text: root.popupObj ? tr("Constellation:") + " " + root.popupObj.constellation : ""
                            color: "#8899aa"; font.pixelSize: 10
                        }

                        // Dimensione angolare
                        Text {
                            visible: root.popupObj !== null
                            text: root.popupObj ? tr("Size:") + " " + root.popupObj.size + "'" : ""
                            color: "#8899aa"; font.pixelSize: 10
                        }

                        // Magnitudine con barra visuale
                        Text {
                            visible: root.popupObj !== null
                            text: root.popupObj ? tr("Magnitude:") + " " + root.popupObj.magnitude.toFixed(1) : ""
                            color: "#8899aa"; font.pixelSize: 10
                        }

                        // Separatore
                        Rectangle { height: 1; Layout.fillWidth: true; color: "#1a2a3a" }

                        // Nota sull'immagine
                        Text {
                            Layout.fillWidth: true
                            text: tr("DSS image · Adaptive FOV")
                            color: "#445566"; font.pixelSize: 9
                            wrapMode: Text.WordWrap
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // Link SIMBAD + Aladin
                RowLayout {
                    spacing: 16
                    Text {
                        visible: root.popupObj !== null
                        text: "🔗 SIMBAD"
                        color: "#4488dd"; font.pixelSize: 10; font.underline: true
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var ident = root.simbadIdent(root.popupObj.name);
                                Qt.openUrlExternally("https://simbad.cds.unistra.fr/simbad/sim-id?Ident="
                                                     + encodeURIComponent(ident));
                            }
                        }
                    }
                    Text {
                        visible: root.popupObj !== null
                        text: "🌌 Aladin"
                        color: "#44aadd"; font.pixelSize: 10; font.underline: true
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var ident = root.simbadIdent(root.popupObj.name);
                                Qt.openUrlExternally("https://aladin.cds.unistra.fr/AladinLite/?target="
                                                     + encodeURIComponent(ident) + "&fov=1&survey=P/DSS2/color");
                            }
                        }
                    }
                }
            }
        }
    }

    // ================================================================
    // COMPACT REPRESENTATION
    // ================================================================
    compactRepresentation: Item {
        Image {
            anchors.fill: parent
            source: "../../contents/ui/telescope.svg"
            smooth: true
        }
        Rectangle {
            anchors.top: parent.top; anchors.right: parent.right
            width: 16; height: 16; radius: 8
            color: "#1e3a1e"; border.color: "#4aaa4a"; border.width: 1
            visible: visibleObjects.length > 0
            Text {
                anchors.centerIn: parent
                text: visibleObjects.length > 99 ? "99+" : visibleObjects.length
                color: "#88ee88"; font.pixelSize: 8; font.bold: true
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
}
