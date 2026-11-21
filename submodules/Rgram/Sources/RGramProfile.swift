import Foundation

/// What the R Gram registry knows about one Telegram user.
public struct RGramProfile: Equatable, Codable {
    public let userId: Int64
    public let bannerURL: URL?
    public let isPremium: Bool

    public init(userId: Int64, bannerURL: URL?, isPremium: Bool) {
        self.userId = userId
        self.bannerURL = bannerURL
        self.isPremium = isPremium
    }
}

extension RGramProfile {
    /// Decodes `{"profiles": {"<id>": {"banner": "https://…", "premium": true}}}`.
    static func decodeProfiles(_ data: Data) -> [Int64: RGramProfile] {
        struct Entry: Decodable {
            let banner: String?
            let premium: Bool?
        }
        struct Envelope: Decodable {
            let profiles: [String: Entry]
        }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            return [:]
        }
        var result: [Int64: RGramProfile] = [:]
        for (key, entry) in envelope.profiles {
            guard let id = Int64(key) else {
                continue
            }
            let url = entry.banner.flatMap { URL(string: $0) }
            // Only https banners are accepted.
            let safeURL = (url?.scheme == "https") ? url : nil
            result[id] = RGramProfile(userId: id, bannerURL: safeURL, isPremium: entry.premium ?? false)
        }
        return result
    }
}
