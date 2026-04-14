import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Read-only accessor for an MBTiles (SQLite) tile archive.
///
/// MBTiles stores tile images in a `tiles` table keyed by
/// `(zoom_level, tile_column, tile_row)` where `tile_row` follows the **TMS**
/// convention (origin at bottom-left). Slippy-map / MapKit consumers use the
/// XYZ convention (origin at top-left), so we flip the row on lookup:
/// `tms_y = (1 << z) - 1 - xyz_y`.
///
/// The store is thread-safe for concurrent reads: sqlite3 connections are
/// opened in serialized threading mode (the default when `SQLITE_THREADSAFE=1`,
/// which Apple's system libsqlite is built with) and we serialize statement
/// use through an internal lock since prepared statements themselves are not
/// safe to share across threads.
final class MBTilesStore {
    private let db: OpaquePointer
    private let lock = NSLock()
    private var stmt: OpaquePointer?

    let url: URL
    let minZoom: Int
    let maxZoom: Int

    /// Opens the archive read-only. Returns nil if the file is missing or
    /// isn't a readable SQLite database with an MBTiles `tiles` table.
    init?(url: URL) {
        self.url = url
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &handle, flags, nil) == SQLITE_OK,
              let handle else {
            if let handle { sqlite3_close(handle) }
            return nil
        }
        self.db = handle

        // Prepare the hot-path SELECT once.
        let sql = "SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1;"
        var prepared: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &prepared, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return nil
        }
        self.stmt = prepared

        // Derive zoom range from metadata (MBTiles spec) or fall back to
        // scanning the tiles table.
        self.minZoom = Self.readIntMetadata(db: db, key: "minzoom") ?? Self.scanZoom(db: db, descending: false) ?? 0
        self.maxZoom = Self.readIntMetadata(db: db, key: "maxzoom") ?? Self.scanZoom(db: db, descending: true) ?? 0
    }

    deinit {
        // Tile lookups are issued by MKTileOverlayRenderer on background
        // threads. If the store's last strong reference is dropped (e.g.
        // when the manager swaps a downloaded pack out) while a lookup is
        // mid-flight, `deinit` must not tear down sqlite state under the
        // reader. Acquire the same lock that `tileData` uses so any
        // in-flight call completes first.
        lock.lock()
        if let stmt { sqlite3_finalize(stmt) }
        sqlite3_close(db)
        lock.unlock()
    }

    /// Returns the raw tile bytes (typically PNG or JPEG) at the given
    /// slippy-map (XYZ) coordinate, or nil if not found.
    func tileData(z: Int, x: Int, y: Int) -> Data? {
        guard z >= 0, x >= 0, y >= 0 else { return nil }
        // Flip y: XYZ → TMS
        let tmsY = (1 << z) - 1 - y

        lock.lock()
        defer { lock.unlock() }

        guard let stmt else { return nil }
        sqlite3_reset(stmt)
        sqlite3_clear_bindings(stmt)
        sqlite3_bind_int(stmt, 1, Int32(z))
        sqlite3_bind_int(stmt, 2, Int32(x))
        sqlite3_bind_int(stmt, 3, Int32(tmsY))

        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        guard let blob = sqlite3_column_blob(stmt, 0) else { return nil }
        let length = Int(sqlite3_column_bytes(stmt, 0))
        guard length > 0 else { return nil }
        return Data(bytes: blob, count: length)
    }

    // MARK: - Metadata helpers

    private static func readIntMetadata(db: OpaquePointer, key: String) -> Int? {
        var stmt: OpaquePointer?
        defer { if let stmt { sqlite3_finalize(stmt) } }
        let sql = "SELECT value FROM metadata WHERE name = ? LIMIT 1;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_ROW, let cStr = sqlite3_column_text(stmt, 0) else { return nil }
        return Int(String(cString: cStr))
    }

    private static func scanZoom(db: OpaquePointer, descending: Bool) -> Int? {
        var stmt: OpaquePointer?
        defer { if let stmt { sqlite3_finalize(stmt) } }
        let order = descending ? "DESC" : "ASC"
        let sql = "SELECT zoom_level FROM tiles ORDER BY zoom_level \(order) LIMIT 1;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return Int(sqlite3_column_int(stmt, 0))
    }
}
