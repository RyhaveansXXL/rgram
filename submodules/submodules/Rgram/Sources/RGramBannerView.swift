import Foundation
import UIKit

/// Image view that shows an R Gram user's banner. Hidden (alpha 0) unless the registry has one.
public final class RGramBannerView: UIImageView {
    private static let imageCache = NSCache<NSURL, UIImage>()

    private var userId: Int64?
    private var loadingURL: URL?
    private var observer: NSObjectProtocol?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
        self.alpha = 0.0
        self.observer = NotificationCenter.default.addObserver(forName: RGramRegistry.didUpdateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
    }

    required public init?(coder: NSCoder) {
        preconditionFailure()
    }

    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Call from the header's update pass. Cheap when nothing changed.
    public func setUserId(_ userId: Int64?) {
        if self.userId != userId {
            self.userId = userId
            self.loadingURL = nil
            self.image = nil
            self.alpha = 0.0
        }
        if let userId, RGramConfig.isRegistryEnabled {
            RGramRegistry.shared.prefetch(userIds: [userId])
        }
        self.refresh()
    }

    private func refresh() {
        guard let userId = self.userId, let url = RGramRegistry.shared.cachedProfile(userId: userId)?.bannerURL else {
            if self.image != nil {
                self.image = nil
            }
            self.alpha = 0.0
            return
        }
        if let image = RGramBannerView.imageCache.object(forKey: url as NSURL) {
            self.image = image
            self.alpha = 1.0
            return
        }
        if self.loadingURL == url {
            return
        }
        self.loadingURL = url
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                return
            }
            RGramBannerView.imageCache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async {
                guard let self, self.loadingURL == url else {
                    return
                }
                self.image = image
                self.alpha = 1.0
            }
        }.resume()
    }
}
