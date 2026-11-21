import Foundation
import UIKit

/// Client of the R Gram registry: the only way the app learns which users run R Gram.
///
/// A user is an "R Gram user" only if the registry has a record for them, so banners and R Premium
/// badges are visible among R Gram users only. Other Telegram clients never see any of it, and
/// nothing here touches Telegram's own account, premium or MTProto state.
public final class RGramRegistry {
    public static let shared = RGramRegistry()

    public static let didUpdateNotification = Notification.Name("RGramRegistryDidUpdate")

    private let queue = DispatchQueue(label: "rgram.registry")
    private var cache: [Int64: RGramProfile] = [:]
    private var knownAbsent: [Int64: Date] = [:]
    private var inFlight: Set<Int64> = []
    private let absentTTL: TimeInterval = 15 * 60

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// The device token that binds an R Gram record to this installation.
    private var deviceToken: String {
        let key = "rgram.deviceToken"
        if let value = UserDefaults.standard.string(forKey: key) {
            return value
        }
        let value = UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }

    // MARK: Reading

    public func cachedProfile(userId: Int64) -> RGramProfile? {
        return self.queue.sync { self.cache[userId] }
    }

    public func isRGramUser(userId: Int64) -> Bool {
        return self.cachedProfile(userId: userId) != nil
    }

    public func isPremium(userId: Int64) -> Bool {
        return self.cachedProfile(userId: userId)?.isPremium ?? false
    }

    /// Fetches records for users not cached yet; posts `didUpdateNotification` when something changed.
    public func prefetch(userIds: [Int64]) {
        guard let base = RGramConfig.apiBase else {
            return
        }
        let now = Date()
        let wanted: [Int64] = self.queue.sync {
            let ids = userIds.filter { id in
                if self.cache[id] != nil || self.inFlight.contains(id) {
                    return false
                }
                if let until = self.knownAbsent[id], until > now {
                    return false
                }
                return true
            }
            for id in ids {
                self.inFlight.insert(id)
            }
            return ids
        }
        if wanted.isEmpty {
            return
        }
        var components = URLComponents(url: base.appendingPathComponent("v1/profiles"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "ids", value: wanted.map(String.init).joined(separator: ","))]
        guard let url = components?.url else {
            self.queue.sync { wanted.forEach { self.inFlight.remove($0) } }
            return
        }
        self.session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else {
                return
            }
            let decoded = data.map(RGramProfile.decodeProfiles) ?? [:]
            self.queue.sync {
                for id in wanted {
                    self.inFlight.remove(id)
                    if let profile = decoded[id] {
                        self.cache[id] = profile
                    } else if data != nil {
                        self.knownAbsent[id] = Date().addingTimeInterval(self.absentTTL)
                    }
                }
            }
            if !decoded.isEmpty {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: RGramRegistry.didUpdateNotification, object: nil)
                }
            }
        }.resume()
    }

    // MARK: Writing (own profile only)

    public enum UpdateError: Error {
        case registryNotConfigured
        case encodingFailed
        case failed
    }

    /// Registers the current user as an R Gram user and sets (or, with `nil`, removes) their banner.
    public func updateOwnBanner(userId: Int64, image: UIImage?, completion: @escaping (Result<Void, UpdateError>) -> Void) {
        guard let base = RGramConfig.apiBase else {
            completion(.failure(.registryNotConfigured))
            return
        }
        var payload: [String: Any] = ["userId": userId]
        if let image {
            guard let data = RGramBannerImage.encode(image) else {
                completion(.failure(.encodingFailed))
                return
            }
            payload["banner"] = data.base64EncodedString()
        } else {
            payload["banner"] = NSNull()
        }
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(.encodingFailed))
            return
        }
        var request = URLRequest(url: base.appendingPathComponent("v1/me"))
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.deviceToken, forHTTPHeaderField: "X-RGram-Token")
        self.session.dataTask(with: request) { [weak self] data, response, _ in
            let ok = (response as? HTTPURLResponse).map { (200 ..< 300).contains($0.statusCode) } ?? false
            guard ok, let self else {
                DispatchQueue.main.async { completion(.failure(.failed)) }
                return
            }
            let decoded = data.map(RGramProfile.decodeProfiles) ?? [:]
            self.queue.sync {
                self.knownAbsent[userId] = nil
                if let profile = decoded[userId] {
                    self.cache[userId] = profile
                } else {
                    self.cache[userId] = RGramProfile(userId: userId, bannerURL: nil, isPremium: self.cache[userId]?.isPremium ?? false)
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: RGramRegistry.didUpdateNotification, object: nil)
                completion(.success(()))
            }
        }.resume()
    }
}

enum RGramBannerImage {
    /// Banner is stored as a 1200 px wide JPEG, capped at ~400 KB.
    static func encode(_ image: UIImage) -> Data? {
        let targetWidth: CGFloat = 1200
        let scale = min(1.0, targetWidth / max(image.size.width, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        var quality: CGFloat = 0.85
        while quality > 0.3 {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= 400_000 {
                return data
            }
            quality -= 0.1
        }
        return resized.jpegData(compressionQuality: 0.3)
    }
}
