import Foundation

/// Provides app version and build number from the main bundle.
///
/// Used in settings views and TestFlight descriptions.
/// Values come from `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`
/// in the Xcode project settings.
enum AppVersion {

    /// The marketing version string (e.g. "1.0.0").
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// The build number string (e.g. "1").
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// Combined display string (e.g. "1.0.0 (1)").
    static var displayString: String {
        "\(version) (\(build))"
    }
}
