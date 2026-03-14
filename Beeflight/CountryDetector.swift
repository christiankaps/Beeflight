import Foundation

enum CountryDetector {

    struct Country {
        let isoCode: String
        let name: String
    }

    // MARK: - Internal Types

    private struct ParsedCountry {
        let isoCode: String
        let name: String
        let outerRings: [[[Double]]] // one outer ring per polygon; each ring = [[lon, lat], ...]
    }

    // MARK: - Parsed Storage (lazy, loaded once)

    private static let countries: [ParsedCountry] = loadCountries()

    // MARK: - Public API

    /// Returns the country at the given coordinates, or nil if over ocean / unknown.
    static func country(at latitude: Double, longitude: Double) -> Country? {
        for country in countries {
            for ring in country.outerRings {
                if pointInPolygon(longitude: longitude, latitude: latitude, ring: ring) {
                    let iso = (country.isoCode == "-99" || country.isoCode.isEmpty)
                        ? "" : country.isoCode
                    return Country(isoCode: iso, name: country.name)
                }
            }
        }
        return nil
    }

    /// Returns a localized country name using Foundation's Locale.
    /// Falls back to the English name from GeoJSON if the ISO code is unavailable.
    static func localizedCountryName(for country: Country) -> String {
        if !country.isoCode.isEmpty,
           let localized = Locale.current.localizedString(forRegionCode: country.isoCode) {
            return localized
        }
        return country.name
    }

    // MARK: - GeoJSON Loading

    private static func loadCountries() -> [ParsedCountry] {
        guard let url = Bundle.main.url(forResource: "countries_110m", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            return []
        }

        var result: [ParsedCountry] = []
        result.reserveCapacity(features.count)

        for feature in features {
            guard let properties = feature["properties"] as? [String: Any],
                  let geometry = feature["geometry"] as? [String: Any],
                  let geomType = geometry["type"] as? String,
                  let rawCoords = geometry["coordinates"] as? [Any] else {
                continue
            }

            let isoCode = (properties["ISO_A2"] as? String) ?? ""
            let name = (properties["NAME"] as? String) ?? ""

            var outerRings: [[[Double]]] = []

            if geomType == "Polygon" {
                if let ring = parseOuterRing(from: rawCoords) {
                    outerRings.append(ring)
                }
            } else if geomType == "MultiPolygon" {
                for polyCoords in rawCoords {
                    if let rings = polyCoords as? [Any],
                       let ring = parseOuterRing(from: rings) {
                        outerRings.append(ring)
                    }
                }
            }

            if !outerRings.isEmpty {
                result.append(ParsedCountry(isoCode: isoCode, name: name, outerRings: outerRings))
            }
        }

        return result
    }

    /// Extract the outer ring (index 0) from a polygon's coordinate array.
    private static func parseOuterRing(from rawRings: [Any]) -> [[Double]]? {
        guard let firstRing = rawRings.first as? [[NSNumber]] else { return nil }
        return firstRing.map { pair in pair.map { $0.doubleValue } }
    }

    // MARK: - Point-in-Polygon (Ray Casting)

    private static func pointInPolygon(longitude: Double, latitude: Double, ring: [[Double]]) -> Bool {
        let n = ring.count
        guard n >= 4 else { return false }

        var inside = false
        var j = n - 1

        for i in 0..<n {
            let xi = ring[i][0], yi = ring[i][1]
            let xj = ring[j][0], yj = ring[j][1]

            if ((yi > latitude) != (yj > latitude)) &&
                (longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }

        return inside
    }
}
