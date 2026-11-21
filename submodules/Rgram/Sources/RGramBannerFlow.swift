import Foundation
import UIKit
import PhotosUI

/// "Banner" button flow of the profile editor: choose a photo, upload it, or remove the banner.
public final class RGramBannerFlow: NSObject, PHPickerViewControllerDelegate {
    private let userId: Int64
    private weak var presenter: UIViewController?
    private var retained: RGramBannerFlow?

    private init(userId: Int64, presenter: UIViewController) {
        self.userId = userId
        self.presenter = presenter
        super.init()
    }

    public static func present(userId: Int64, from presenter: UIViewController) {
        let flow = RGramBannerFlow(userId: userId, presenter: presenter)
        flow.retained = flow
        flow.showMenu()
    }

    private func showMenu() {
        guard let presenter = self.presenter else {
            self.retained = nil
            return
        }
        let sheet = UIAlertController(title: RGramStrings.string(.bannerTitle), message: RGramStrings.string(.bannerHelp), preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: RGramStrings.string(.bannerChoose), style: .default, handler: { [weak self] _ in
            self?.showPicker()
        }))
        sheet.addAction(UIAlertAction(title: RGramStrings.string(.bannerRemove), style: .destructive, handler: { [weak self] _ in
            self?.upload(image: nil)
        }))
        sheet.addAction(UIAlertAction(title: RGramStrings.string(.cancel), style: .cancel, handler: { [weak self] _ in
            self?.retained = nil
        }))
        sheet.popoverPresentationController?.sourceView = presenter.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        presenter.present(sheet, animated: true)
    }

    private func showPicker() {
        guard let presenter = self.presenter else {
            self.retained = nil
            return
        }
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presenter.present(picker, animated: true)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            self.retained = nil
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                self?.upload(image: object as? UIImage)
            }
        }
    }

    private func upload(image: UIImage?) {
        guard RGramConfig.isRegistryEnabled else {
            self.showAlert(RGramStrings.string(.bannerNeedsRegistry))
            return
        }
        RGramRegistry.shared.updateOwnBanner(userId: self.userId, image: image) { [weak self] result in
            if case .failure = result {
                self?.showAlert(RGramStrings.string(.bannerUploadFailed))
            } else {
                self?.retained = nil
            }
        }
    }

    private func showAlert(_ text: String) {
        if let presenter = self.presenter {
            let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            presenter.present(alert, animated: true)
        }
        self.retained = nil
    }
}
