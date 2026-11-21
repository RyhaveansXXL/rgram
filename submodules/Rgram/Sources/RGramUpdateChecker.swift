import Foundation

/// Checks the GitHub Releases of the R Gram repository for a newer IPA build.
/// Releases are tagged `build-<number>` by `.github/workflows/rgram-ipa.yml`.
public struct RGramUpdate: Equatable {
    public let buildNumber: Int
    public let title: String
    public let pageURL: URL
    public let ipaURL: URL?
}

public enum RGramUpdateChecker {
    public static func parse(_ data: Data) -> RGramUpdate? {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: String
        }
        struct Release: Decodable {
            let tag_name: String
            let name: String?
            let html_url: String
            let assets: [Asset]
        }
        guard let release = try? JSONDecoder().decode(Release.self, from: data) else {
            return nil
        }
        guard release.tag_name.hasPrefix("build-"), let number = Int(release.tag_name.dropFirst("build-".count)) else {
            return nil
        }
        guard let page = URL(string: release.html_url) else {
            return nil
        }
        let ipa = release.assets.first(where: { $0.name.hasSuffix(".ipa") }).flatMap { URL(string: $0.browser_download_url) }
        return RGramUpdate(buildNumber: number, title: release.name ?? release.tag_name, pageURL: page, ipaURL: ipa)
    }

    /// Calls `completion` on the main queue with an update only if it is newer than `currentBuild`.
    public static func check(currentBuild: Int = RGramConfig.buildNumber, completion: @escaping (RGramUpdate?) -> Void) {
        guard let repo = RGramConfig.updateRepository,
              let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let update = data.flatMap(parse).flatMap { $0.buildNumber > currentBuild ? $0 : nil }
            DispatchQueue.main.async { completion(update) }
        }.resume()
    }
}
