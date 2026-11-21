import Foundation
import UIKit

/// Settings ▸ "R Gram update": asks GitHub Releases whether a newer IPA exists and offers to open it.
public enum RGramUpdatePrompt {
    public static func checkAndPresent() {
        RGramUpdateChecker.check { update in
            guard let top = topViewController() else {
                return
            }
            if let update {
                let alert = UIAlertController(title: RGramStrings.string(.updateAvailable), message: update.title, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: RGramStrings.string(.updateInstall), style: .default, handler: { _ in
                    UIApplication.shared.open(update.ipaURL ?? update.pageURL)
                }))
                alert.addAction(UIAlertAction(title: RGramStrings.string(.updateLater), style: .cancel))
                top.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: nil, message: RGramConfig.appName + " ✓", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                top.present(alert, animated: true)
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first(where: { $0.activationState == .foregroundActive })
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
