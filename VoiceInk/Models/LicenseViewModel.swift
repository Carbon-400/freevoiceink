import Foundation
import AppKit

@MainActor
class LicenseViewModel: ObservableObject {
    enum LicenseState: Equatable {
        case licensed
    }

    @Published private(set) var licenseState: LicenseState = .licensed
    @Published var licenseKey: String = ""
    @Published var isValidating = false
    @Published var validationMessage: String?
    @Published var validationSuccess: Bool = true
    @Published private(set) var activationsLimit: Int = 0

    private let licenseManager = LicenseManager.shared

    init() {
        licenseState = .licensed
    }

    var canUseApp: Bool {
        true
    }
    
    func openPurchaseLink() {
        if let url = URL(string: "https://github.com/Beingpax/VoiceInk") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func validateLicense() async {
        validationSuccess = true
        validationMessage = "RawSpeech is free and does not require a license key."
        isValidating = false
    }
    
    func removeLicense() {
        licenseManager.removeAll()
        licenseState = .licensed
        licenseKey = ""
        validationMessage = "RawSpeech is free and does not require a license key."
        activationsLimit = 0
        NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
    }
}


// UserDefaults extension for non-sensitive license settings
extension UserDefaults {
    var activationsLimit: Int {
        get { integer(forKey: "VoiceInkActivationsLimit") }
        set { set(newValue, forKey: "VoiceInkActivationsLimit") }
    }
}
