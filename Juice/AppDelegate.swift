/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Main application delegate.
 */

import AuthenticationServices
import RudifaUtilPkg
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    fileprivate func dispatchOnAuthorization() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { credentialState, _ in
            switch credentialState {
            case .authorized:
                break // The Apple ID credential is valid.
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                DispatchQueue.main.async {
                    self.window?.rootViewController?.showLoginViewController()
                }
            default:
                break
            }
        }
    }

    enum CredentialStateError: Error {
        case revokedOrNotFound

        var description: String {
            "revokedOrNotFound"
        }
    }

    fileprivate func dispatchOnAuthorization2(completion: @escaping (Result<Bool, Error>) -> Void) {
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
//        dispatchOnAuthorization()

        dispatchOnAuthorization2 { result in
            switch result {
            case let .success(isAuthorized):
                self.printClassAndFunc("Authorization status: \(isAuthorized)")
            case let .failure(error):
                self.printClassAndFunc("Authorization error: \(error)")
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                DispatchQueue.main.async {
                    self.window?.rootViewController?.showLoginViewController()
                }
            }
        }
        return true
    }
}
