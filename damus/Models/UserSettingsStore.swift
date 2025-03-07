//
//  UserSettingsStore.swift
//  damus
//
//  Created by Suhail Saqan on 12/29/22.
//

import Foundation
import Vault
import UIKit

func should_show_wallet_selector(_ pubkey: String) -> Bool {
    return UserDefaults.standard.object(forKey: "show_wallet_selector") as? Bool ?? true
}

func pk_setting_key(_ pubkey: String, key: String) -> String {
    return "\(pubkey)_\(key)"
}

func default_zap_setting_key(pubkey: String) -> String {
    return pk_setting_key(pubkey, key: "default_zap_amount")
}

func set_default_zap_amount(pubkey: String, amount: Int) {
    let key = default_zap_setting_key(pubkey: pubkey)
    UserDefaults.standard.setValue(amount, forKey: key)
}

func get_default_zap_amount(pubkey: String) -> Int? {
    let key = default_zap_setting_key(pubkey: pubkey)
    let amt = UserDefaults.standard.integer(forKey: key)
    if amt == 0 {
        return nil
    }
    return amt
}

func should_disable_image_animation() -> Bool {
    return (UserDefaults.standard.object(forKey: "disable_animation") as? Bool)
            ?? UIAccessibility.isReduceMotionEnabled
 }

func get_default_wallet(_ pubkey: String) -> Wallet {
    if let defaultWalletName = UserDefaults.standard.string(forKey: "default_wallet"),
       let default_wallet = Wallet(rawValue: defaultWalletName)
    {
        return default_wallet
    } else {
        return .system_default_wallet
    }
}

private func get_translation_service(_ pubkey: String) -> TranslationService? {
    guard let translation_service = UserDefaults.standard.string(forKey: "translation_service") else {
        return nil
    }

    return TranslationService(rawValue: translation_service)
}

private func get_deepl_plan(_ pubkey: String) -> DeepLPlan? {
    guard let server_name = UserDefaults.standard.string(forKey: "deepl_plan") else {
        return nil
    }

    return DeepLPlan(rawValue: server_name)
}

private func get_libretranslate_server(_ pubkey: String) -> LibreTranslateServer? {
    guard let server_name = UserDefaults.standard.string(forKey: "libretranslate_server") else {
        return nil
    }
    
    return LibreTranslateServer(rawValue: server_name)
}

private func get_libretranslate_url(_ pubkey: String, server: LibreTranslateServer) -> String? {
    if let url = server.model.url {
        return url
    }
    
    return UserDefaults.standard.object(forKey: "libretranslate_url") as? String
}

class UserSettingsStore: ObservableObject {
    @Published var default_wallet: Wallet {
        didSet {
            UserDefaults.standard.set(default_wallet.rawValue, forKey: "default_wallet")
        }
    }
    
    @Published var show_wallet_selector: Bool {
        didSet {
            UserDefaults.standard.set(show_wallet_selector, forKey: "show_wallet_selector")
        }
    }

    @Published var left_handed: Bool {
        didSet {
            UserDefaults.standard.set(left_handed, forKey: "left_handed")
        }
    }

    @Published var translation_service: TranslationService {
        didSet {
            UserDefaults.standard.set(translation_service.rawValue, forKey: "translation_service")
        }
    }

    @Published var deepl_plan: DeepLPlan {
        didSet {
            UserDefaults.standard.set(deepl_plan.rawValue, forKey: "deepl_plan")
        }
    }

    @Published var deepl_api_key: String {
        didSet {
            do {
                if deepl_api_key == "" {
                    try clearDeepLApiKey()
                } else {
                    try saveDeepLApiKey(deepl_api_key)
                }
            } catch {
                // No-op.
            }
        }
    }

    @Published var libretranslate_server: LibreTranslateServer {
        didSet {
            if oldValue == libretranslate_server {
                return
            }

            UserDefaults.standard.set(libretranslate_server.rawValue, forKey: "libretranslate_server")

            libretranslate_api_key = ""

            if libretranslate_server == .custom {
                libretranslate_url = ""
            } else {
                libretranslate_url = libretranslate_server.model.url!
            }
        }
    }

    @Published var libretranslate_url: String {
        didSet {
            UserDefaults.standard.set(libretranslate_url, forKey: "libretranslate_url")
        }
    }

    @Published var libretranslate_api_key: String {
        didSet {
            do {
                if libretranslate_api_key == "" {
                    try clearLibreTranslateApiKey()
                } else {
                    try saveLibreTranslateApiKey(libretranslate_api_key)
                }
            } catch {
                // No-op.
            }
        }
    }
    
    @Published var disable_animation: Bool {
        didSet {
            UserDefaults.standard.set(disable_animation, forKey: "disable_animation")
        }
     }

    init() {
        // TODO: pubkey-scoped settings
        let pubkey = ""
        self.default_wallet = get_default_wallet(pubkey)
        show_wallet_selector = should_show_wallet_selector(pubkey)

        left_handed = UserDefaults.standard.object(forKey: "left_handed") as? Bool ?? false
        disable_animation = should_disable_image_animation()

        // Note from @tyiu:
        // Default translation service is disabled by default for now until we gain some confidence that it is working well in production.
        // Instead of throwing all Damus users onto feature immediately, allow for discovery of feature organically.
        // Also, we are connecting to servers listed as mirrors on the official LibreTranslate GitHub README that do not require API keys.
        // However, we have not asked them for permission to use, so we're trying to be good neighbors for now.
        // Opportunity: spin up dedicated trusted LibreTranslate server that requires an API key for any access (or higher rate limit access).
        if let translation_service = get_translation_service(pubkey) {
            self.translation_service = translation_service
        } else {
            self.translation_service = .none
        }

        if let libretranslate_server = get_libretranslate_server(pubkey) {
            self.libretranslate_server = libretranslate_server
            self.libretranslate_url = get_libretranslate_url(pubkey, server: libretranslate_server) ?? ""
        } else {
            // Choose a random server to distribute load.
            libretranslate_server = .allCases.filter { $0 != .custom }.randomElement()!
            libretranslate_url = ""
        }
            
        do {
            libretranslate_api_key = try Vault.getPrivateKey(keychainConfiguration: DamusLibreTranslateKeychainConfiguration())
        } catch {
            libretranslate_api_key = ""
        }

        if let deepl_plan = get_deepl_plan(pubkey) {
            self.deepl_plan = deepl_plan
        } else {
            self.deepl_plan = .free
        }

        do {
            deepl_api_key = try Vault.getPrivateKey(keychainConfiguration: DamusDeepLKeychainConfiguration())
        } catch {
            deepl_api_key = ""
        }
    }

    private func saveLibreTranslateApiKey(_ apiKey: String) throws {
        try Vault.savePrivateKey(apiKey, keychainConfiguration: DamusLibreTranslateKeychainConfiguration())
    }

    private func clearLibreTranslateApiKey() throws {
        try Vault.deletePrivateKey(keychainConfiguration: DamusLibreTranslateKeychainConfiguration())
    }

    private func saveDeepLApiKey(_ apiKey: String) throws {
        try Vault.savePrivateKey(apiKey, keychainConfiguration: DamusDeepLKeychainConfiguration())
    }

    private func clearDeepLApiKey() throws {
        try Vault.deletePrivateKey(keychainConfiguration: DamusDeepLKeychainConfiguration())
    }

    func can_translate(_ pubkey: String) -> Bool {
        switch translation_service {
        case .none:
            return false
        case .libretranslate:
            return URLComponents(string: libretranslate_url) != nil
        case .deepl:
            return deepl_api_key != ""
        }
    }
}

struct DamusLibreTranslateKeychainConfiguration: KeychainConfiguration {
    var serviceName = "damus"
    var accessGroup: String? = nil
    var accountName = "libretranslate_apikey"
}

struct DamusDeepLKeychainConfiguration: KeychainConfiguration {
    var serviceName = "damus"
    var accessGroup: String? = nil
    var accountName = "deepl_apikey"
}
