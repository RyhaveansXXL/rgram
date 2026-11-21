import Foundation

/// R Gram build-time configuration, read from the app's Info.plist.
///
/// - `RGramAPIBase`: HTTPS base URL of the R Gram registry (see `rgram-server/`). Empty disables
///   every cross-user R Gram feature (banners and R Premium badges of other users); the app then
///   behaves like the base client.
/// - `RGramUpdateRepo`: `owner/repo` of the GitHub repository whose Releases carry new IPA builds.
public enum RGramConfig {
    public static let appName = "R Gram"

    public static var apiBase: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "RGramAPIBase") as? String, !value.isEmpty, !value.hasPrefix("__") else {
            return nil
        }
        return URL(string: value)
    }

    public static var updateRepository: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "RGramUpdateRepo") as? String, !value.isEmpty, !value.hasPrefix("__") else {
            return nil
        }
        return value
    }

    public static var isRegistryEnabled: Bool {
        return self.apiBase != nil
    }

    public static var buildNumber: Int {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return Int(raw) ?? 0
    }
}
