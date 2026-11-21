import Foundation

/// Small self-contained string table, so R Gram needs no change to the generated PresentationStrings.
public enum RGramStrings {
    public enum Key: String {
        case banner
        case bannerTitle
        case bannerChoose
        case bannerRemove
        case bannerHelp
        case bannerUploadFailed
        case bannerNeedsRegistry
        case premium
        case premiumActive
        case premiumInactive
        case premiumHelp
        case updateRow
        case updateAvailable
        case updateInstall
        case updateLater
        case cancel
    }

    private static let table: [String: [Key: String]] = [
        "az": [
            .banner: "Banner",
            .bannerTitle: "Profil bannerı",
            .bannerChoose: "Banner seç",
            .bannerRemove: "Bannerı sil",
            .bannerHelp: "Banner yalnız R Gram istifadə edənlərdə görünəcək.",
            .bannerUploadFailed: "Banner yüklənmədi. Bir az sonra yenidən cəhd edin.",
            .bannerNeedsRegistry: "R Gram serveri quraşdırılmayıb.",
            .premium: "R Premium",
            .premiumActive: "Aktivdir",
            .premiumInactive: "Aktiv deyil",
            .premiumHelp: "R Premium yalnız R Gram istifadəçiləri arasında keçərlidir və Telegram Premium-u əvəz etmir.",
            .updateRow: "R Gram yeniləməsi",
            .updateAvailable: "Yeni R Gram versiyası var",
            .updateInstall: "Yüklə",
            .updateLater: "Sonra",
            .cancel: "Ləğv et"
        ],
        "ru": [
            .banner: "Баннер",
            .bannerTitle: "Баннер профиля",
            .bannerChoose: "Выбрать баннер",
            .bannerRemove: "Удалить баннер",
            .bannerHelp: "Баннер увидят только пользователи R Gram.",
            .bannerUploadFailed: "Не удалось загрузить баннер. Повторите позже.",
            .bannerNeedsRegistry: "Сервер R Gram не настроен.",
            .premium: "R Premium",
            .premiumActive: "Активен",
            .premiumInactive: "Не активен",
            .premiumHelp: "R Premium действует только среди пользователей R Gram и не заменяет Telegram Premium.",
            .updateRow: "Обновление R Gram",
            .updateAvailable: "Доступна новая версия R Gram",
            .updateInstall: "Скачать",
            .updateLater: "Позже",
            .cancel: "Отмена"
        ],
        "en": [
            .banner: "Banner",
            .bannerTitle: "Profile banner",
            .bannerChoose: "Choose banner",
            .bannerRemove: "Remove banner",
            .bannerHelp: "The banner is visible only to R Gram users.",
            .bannerUploadFailed: "Couldn't upload the banner. Please try again later.",
            .bannerNeedsRegistry: "The R Gram server is not configured.",
            .premium: "R Premium",
            .premiumActive: "Active",
            .premiumInactive: "Not active",
            .premiumHelp: "R Premium is valid only among R Gram users and does not replace Telegram Premium.",
            .updateRow: "R Gram update",
            .updateAvailable: "A new R Gram version is available",
            .updateInstall: "Download",
            .updateLater: "Later",
            .cancel: "Cancel"
        ]
    ]

    public static func string(_ key: Key) -> String {
        let code = Locale.preferredLanguages.first.flatMap { String($0.prefix(2)) } ?? "en"
        return (self.table[code] ?? self.table["en"]!)[key] ?? self.table["en"]![key] ?? ""
    }
}
