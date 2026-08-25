import Foundation

struct AppInfo: Equatable, Sendable {
    let shortVersion: String?
    let build: String?

    init(shortVersion: String?, build: String?) {
        self.shortVersion = shortVersion
        self.build = build
    }

    init(bundle: Bundle) {
        self.init(
            shortVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        )
    }

    var displayVersion: String {
        guard let shortVersion, !shortVersion.isEmpty else {
            return "—"
        }

        guard let build, !build.isEmpty else {
            return shortVersion
        }

        return "\(shortVersion) (\(build))"
    }
}
