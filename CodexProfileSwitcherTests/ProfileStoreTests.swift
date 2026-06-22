import XCTest
@testable import CodexProfileSwitcher

@MainActor
final class ProfileStoreTests: XCTestCase {
    private var temporaryHomes: [URL] = []

    override func tearDownWithError() throws {
        for homeURL in temporaryHomes {
            try? FileManager.default.removeItem(at: homeURL)
        }
        temporaryHomes.removeAll()
        try super.tearDownWithError()
    }

    func testCreatedProfileUsesPrivatePermissions() throws {
        let store = makeStore()

        store.createBlankProfile()

        let profile = try XCTUnwrap(store.profiles.first)
        let permissions = try posixPermissions(at: store.path(for: profile))
        XCTAssertEqual(permissions, 0o600)
    }

    func testRenameReturnsReloadedProfileWithCurrentIdentifier() throws {
        let homeURL = makeTemporaryHome()
        let store = ProfileStore(homeURL: homeURL, bootstrap: false, restartsCodexOnApply: false)
        store.createBlankProfile()
        let original = try XCTUnwrap(store.profiles.first)

        let renamed = store.update(original, name: "Team/API", contents: "model = \"gpt-5\"\n")
        store.apply(renamed)

        XCTAssertTrue(store.profiles.contains { $0.id == renamed.id })
        XCTAssertEqual(store.activeProfileID, renamed.id)

        let restoredStore = ProfileStore(homeURL: homeURL, bootstrap: false, restartsCodexOnApply: false)
        XCTAssertEqual(restoredStore.activeProfileID, renamed.id)
    }

    func testRepeatedApplyCreatesUniqueBackups() throws {
        let homeURL = makeTemporaryHome()
        let store = ProfileStore(homeURL: homeURL, bootstrap: false, restartsCodexOnApply: false)
        let codexDirectoryURL = homeURL.appending(path: ".codex", directoryHint: .isDirectory)
        let configURL = codexDirectoryURL.appending(path: "config.toml")
        try "model = \"initial\"\n".write(to: configURL, atomically: true, encoding: .utf8)

        store.createBlankProfile()
        let profile = try XCTUnwrap(store.profiles.first)

        store.apply(profile)
        store.apply(profile)

        let backupURLs = try FileManager.default.contentsOfDirectory(
            at: codexDirectoryURL,
            includingPropertiesForKeys: nil
        )
        .filter { $0.lastPathComponent.hasPrefix("config.toml.profile-switcher-backup-") }

        XCTAssertEqual(backupURLs.count, 2)
    }

    private func makeStore() -> ProfileStore {
        ProfileStore(homeURL: makeTemporaryHome(), bootstrap: false, restartsCodexOnApply: false)
    }

    private func makeTemporaryHome() -> URL {
        let homeURL = FileManager.default.temporaryDirectory
            .appending(path: "CodexProfileSwitcherTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: homeURL, withIntermediateDirectories: true)
        temporaryHomes.append(homeURL)
        return homeURL
    }

    private func posixPermissions(at url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return try XCTUnwrap(attributes[.posixPermissions] as? Int) & 0o777
    }
}
