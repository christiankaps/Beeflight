import Testing
import Foundation
import SQLite3
@testable import Beeflight

private let SQLITE_TRANSIENT_TEST = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct MapTileTierTests {

    @Test func zoomRangeMatchesTier() {
        #expect(MapTileTier.builtIn.minZoom == 0)
        #expect(MapTileTier.builtIn.maxZoom == 3)
        #expect(MapTileTier.standard.maxZoom == 6)
        #expect(MapTileTier.detailed.maxZoom == 8)
    }

    @Test func isDownloadableIsFalseOnlyForBuiltIn() {
        #expect(MapTileTier.builtIn.isDownloadable == false)
        #expect(MapTileTier.standard.isDownloadable == true)
        #expect(MapTileTier.detailed.isDownloadable == true)
    }

    @Test func downloadFilenameIsStableAndUnique() {
        let names = Set(MapTileTier.allCases.map(\.downloadFilename))
        #expect(names.count == MapTileTier.allCases.count)
        #expect(MapTileTier.standard.downloadFilename.hasSuffix(".mbtiles"))
    }

    @Test func approximateBytesIsPositiveAndIncreasing() {
        let sizes = MapTileTier.allCases.map(\.approximateBytes)
        #expect(sizes.allSatisfy { $0 > 0 })
        #expect(MapTileTier.standard.approximateBytes < MapTileTier.detailed.approximateBytes)
    }
}

struct MBTilesStoreTests {

    /// Build a minimal MBTiles SQLite file in a temp dir with a single
    /// red-pixel PNG at (z=1, x=0, y=0 XYZ) and return its URL.
    static func makeFixture() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("beeflight-test-\(UUID().uuidString).mbtiles")
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            throw NSError(domain: "test", code: 1)
        }
        defer { sqlite3_close(db) }

        let schema = """
            CREATE TABLE metadata (name TEXT, value TEXT);
            CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
            INSERT INTO metadata VALUES ('minzoom', '0');
            INSERT INTO metadata VALUES ('maxzoom', '1');
            """
        #expect(sqlite3_exec(db, schema, nil, nil, nil) == SQLITE_OK)

        // Insert at TMS (z=1, x=0, y=0), which is XYZ y = (1<<1) - 1 - 0 = 1.
        // So the tile is at XYZ (z=1, x=0, y=1).
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = "INSERT INTO tiles VALUES (?, ?, ?, ?);"
        #expect(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK)
        sqlite3_bind_int(stmt, 1, 1)
        sqlite3_bind_int(stmt, 2, 0)
        sqlite3_bind_int(stmt, 3, 0) // TMS y = 0
        let bytes: [UInt8] = [0xFF, 0x00, 0x00, 0xFF] // marker bytes
        bytes.withUnsafeBufferPointer { buf in
            _ = sqlite3_bind_blob(stmt, 4, buf.baseAddress, Int32(buf.count), SQLITE_TRANSIENT_TEST)
        }
        #expect(sqlite3_step(stmt) == SQLITE_DONE)

        return url
    }

    @Test func opensAndReportsZoomRange() throws {
        let url = try Self.makeFixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try #require(MBTilesStore(url: url))
        #expect(store.minZoom == 0)
        #expect(store.maxZoom == 1)
    }

    @Test func returnsTileForFlippedY() throws {
        let url = try Self.makeFixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try #require(MBTilesStore(url: url))
        // We stored TMS y=0 at z=1; XYZ y = 1.
        let hit = store.tileData(z: 1, x: 0, y: 1)
        #expect(hit != nil)
        #expect(hit?.count == 4)
        // The OTHER XYZ y should miss.
        let miss = store.tileData(z: 1, x: 0, y: 0)
        #expect(miss == nil)
    }

    @Test func missingFileReturnsNilStore() {
        let url = URL(fileURLWithPath: "/var/empty/does-not-exist.mbtiles")
        #expect(MBTilesStore(url: url) == nil)
    }

    @Test func negativeCoordsReturnNil() throws {
        let url = try Self.makeFixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try #require(MBTilesStore(url: url))
        #expect(store.tileData(z: -1, x: 0, y: 0) == nil)
        #expect(store.tileData(z: 0, x: -1, y: 0) == nil)
    }
}

struct OfflineMapManagerTests {

    @Test func initialStateIsIdleWithNoDownload() {
        let mgr = OfflineMapManager()
        if case .idle = mgr.downloadState { } else {
            Issue.record("expected .idle")
        }
        #expect(mgr.downloadedTier == nil)
        #expect(mgr.downloadedBytes == 0)
        // installedTier falls back to builtIn even when bundledStore is nil.
        #expect(mgr.installedTier == .builtIn)
    }

    @Test func startDownloadOnBuiltInIsNoOp() {
        let mgr = OfflineMapManager()
        mgr.startDownload(tier: .builtIn)
        if case .idle = mgr.downloadState { } else {
            Issue.record("built-in should not start a download")
        }
    }

    @Test func deleteWithoutDownloadIsSafe() {
        let mgr = OfflineMapManager()
        mgr.deleteDownloadedPack()
        #expect(mgr.downloadedTier == nil)
    }
}
