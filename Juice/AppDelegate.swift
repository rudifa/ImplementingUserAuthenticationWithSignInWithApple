/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Main application delegate.
 */

import AuthenticationServices
import RudifaUtilPkg
import UIKit

enum CredentialStateError: Error {
    case revokedOrNotFound

    var description: String {
        "revokedOrNotFound"
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    fileprivate func dispatchOnAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { credentialState, _ in
            switch credentialState {
            case .authorized:
                completion(.success(true)) // The Apple ID credential is valid.
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                completion(.failure(CredentialStateError.revokedOrNotFound))
            default:
                break
            }
        }
    }

    /// - Tag: did_finish_launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Task {
            do {
                let isAuthorised = try await isAppAuthorised()
                if isAuthorised {
                    self.printClassAndFunc("App is authorised")
                } else {
                    self.printClassAndFunc("App is not authorised")
                    DispatchQueue.main.async {
                        self.window?.rootViewController?.showLoginViewController()
                    }
                }
            } catch {
                print("Failed to check authorisation: \(error)")
                // Handle error
            }
        }
        return true
    }

    func isAppAuthorised() async throws -> Bool {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Bool, Error>) in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { credentialState, _ in
                switch credentialState {
                case .authorized:
                    continuation.resume(returning: true) // The Apple ID credential is valid.
                case .revoked, .notFound:
                    // The Apple ID credential is either revoked or was not found.
                    continuation.resume(returning: false)
                default:
                    break
                }
            }
        })
    }
}
