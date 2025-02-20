import ApphudSDK
import Siren
import UIKit
import StoreKit
import AppTrackingTransparency
import AdSupport

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var userId: String?
    var cachedTemplates: [Template] = []
    var experimentV = String()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Apphud.start(apiKey: "app_bNQx4yniLzkzQe6oXfF2CUfhcEitht")
        
        let userId = Apphud.userID()
        UserDefaults.standard.set(userId, forKey: "userId")
        preloadTemplates()
        Siren.shared.wail()
        
        if #available(iOS 14.5, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .notDetermined:
                        print("notDetermined")
                    case .restricted:
                        print("restricted")
                    case .denied:
                        print("denied")
                    case .authorized:
                        print("authorized")
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    @unknown default:
                        print("@unknown")
                    }
                }
            }
        }

        return true
    }
    
    private func preloadTemplates() {
        let savedTemplates = CacheManager.shared.loadAllTemplatesFromCache()
        cachedTemplates = savedTemplates

        NetworkService.shared.fetchEffects(forApp: Bundle.main.bundleIdentifier ?? "com.test.test") { [weak self] result in
            switch result {
            case let .success(templates):
                guard let self = self else { return }
                var updatedTemplates: [Template] = []

                Task {
                    for serverTemplate in templates {
                        if let cachedTemplate = self.cachedTemplates.first(where: { $0.id == serverTemplate.id }) {
                            if cachedTemplate.preview != serverTemplate.preview {
                                do {
                                    let videoURL = try await self.downloadAndSaveVideo(for: serverTemplate)
                                    var updatedTemplate = serverTemplate
                                    updatedTemplate.localVideoName = videoURL?.lastPathComponent
                                    updatedTemplates.append(updatedTemplate)
                                } catch {
                                    print("Error updating video for template \(serverTemplate.id): \(error.localizedDescription)")
                                    updatedTemplates.append(cachedTemplate)
                                }
                            } else {
                                updatedTemplates.append(cachedTemplate)
                            }
                        } else {
                            if !serverTemplate.preview.isEmpty {
                                do {
                                    let videoURL = try await self.downloadAndSaveVideo(for: serverTemplate)
                                    var newTemplate = serverTemplate
                                    newTemplate.localVideoName = videoURL?.lastPathComponent
                                    updatedTemplates.append(newTemplate)
                                } catch {
                                    print("Error downloading video for new template \(serverTemplate.id): \(error.localizedDescription)")
                                }
                            }
                        }

                        self.cachedTemplates = updatedTemplates
                        CacheManager.shared.saveTemplateToCache(updatedTemplates)
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .templatesUpdated, object: updatedTemplates)
                        }
                    }
                }

            case let .failure(error):
                print("Error fetching templates from server: \(error.localizedDescription)")
            }
        }
    }

    private func downloadAndSaveVideo(for template: Template) async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            CacheManager.shared.saveVideo(for: template) { result in
                switch result {
                case let .success(videoURL):
                    print("Video successfully saved for template \(template.id).")
                    continuation.resume(returning: videoURL)
                case let .failure(error):
                    print("Error saving video for template \(template.id): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
