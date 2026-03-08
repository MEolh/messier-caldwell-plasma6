/**
 * astro.js - Motore di calcolo astronomico
 * Calcolo altezza/azimuth per oggetti del cielo profondo
 * Basato su algoritmi di Jean Meeus "Astronomical Algorithms"
 */

// Converti gradi in radianti
function toRad(deg) { return deg * Math.PI / 180.0; }
// Converti radianti in gradi
function toDeg(rad) { return rad * 180.0 / Math.PI; }

/**
 * Calcola il Julian Day Number da una data
 */
function julianDay(date) {
    let Y = date.getUTCFullYear();
    let M = date.getUTCMonth() + 1;
    let D = date.getUTCDate() +
            date.getUTCHours() / 24.0 +
            date.getUTCMinutes() / 1440.0 +
            date.getUTCSeconds() / 86400.0;

    if (M <= 2) { Y -= 1; M += 12; }
    let A = Math.floor(Y / 100);
    let B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (Y + 4716)) + Math.floor(30.6001 * (M + 1)) + D + B - 1524.5;
}

/**
 * Calcola il Greenwich Mean Sidereal Time (GMST) in gradi
 */
function gmst(jd) {
    let T = (jd - 2451545.0) / 36525.0;
    let theta = 280.46061837 +
                360.98564736629 * (jd - 2451545.0) +
                0.000387933 * T * T -
                T * T * T / 38710000.0;
    return ((theta % 360) + 360) % 360;
}

/**
 * Calcola altezza e azimuth di un oggetto
 * @param {number} ra   - Ascensione Retta in gradi (0-360)
 * @param {number} dec  - Declinazione in gradi (-90/+90)
 * @param {number} lat  - Latitudine osservatore in gradi
 * @param {number} lon  - Longitudine osservatore in gradi (E positivo)
 * @param {Date}   date - Data/ora corrente
 * @returns {{alt: number, az: number}}
 */
function altAz(ra, dec, lat, lon, date) {
    let jd = julianDay(date);
    let gst = gmst(jd);
    // Local Sidereal Time
    let lst = ((gst + lon) % 360 + 360) % 360;
    // Hour Angle
    let ha = toRad(((lst - ra) % 360 + 360) % 360);

    let decR = toRad(dec);
    let latR = toRad(lat);

    // Altezza
    let sinAlt = Math.sin(decR) * Math.sin(latR) +
                 Math.cos(decR) * Math.cos(latR) * Math.cos(ha);
    let alt = toDeg(Math.asin(sinAlt));

    // Azimuth (da Nord, verso Est)
    let cosAz = (Math.sin(decR) - Math.sin(toRad(alt)) * Math.sin(latR)) /
                (Math.cos(toRad(alt)) * Math.cos(latR));
    cosAz = Math.max(-1, Math.min(1, cosAz)); // clamp per sicurezza
    let az = toDeg(Math.acos(cosAz));
    if (Math.sin(ha) > 0) az = 360 - az;

    return { alt: alt, az: az };
}

/**
 * Filtra il catalogo per oggetti visibili sopra la soglia
 */
function getVisibleObjects(catalog, lat, lon, minAlt, date) {
    let now = date || new Date();
    let visible = [];

    for (let i = 0; i < catalog.length; i++) {
        let obj = catalog[i];
        let pos = altAz(obj.ra, obj.dec, lat, lon, now);
        if (pos.alt >= minAlt) {
            visible.push({
                name:        obj.name,
                catalog:     obj.catalog,
                type:        obj.type,
                typeIcon:    obj.typeIcon,
                constellation: obj.constellation,
                magnitude:   obj.magnitude,
                size:        obj.size,
                alt:         Math.round(pos.alt * 10) / 10,
                az:          Math.round(pos.az * 10) / 10,
                ra:          obj.ra,
                dec:         obj.dec
            });
        }
    }

    // Ordina per altezza decrescente
    visible.sort(function(a, b) { return b.alt - a.alt; });
    return visible;
}
