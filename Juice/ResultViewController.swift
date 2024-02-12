/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Main application view controller.
 */

import AuthenticationServices
import UIKit

class ResultViewController: UIViewController {
    @IBOutlet var userIdentifierLabel: UILabel!
    @IBOutlet var givenNameLabel: UILabel!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var signOutButton: UIButton!

    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var authorizedScopesLabel: UILabel!
    @IBOutlet var authorizationCodeLabel: UILabel!
    @IBOutlet var identityTokenLabel: UILabel!
    @IBOutlet var emailLabel2: UILabel!
    @IBOutlet var fullNameLabel2: UILabel!
    @IBOutlet var realUserStatusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
//        userIdentifierLabel.text = "userID: " + KeychainItem.currentUserCredential.id

        updateKeychainLabels()

        // show for testing
        // [Presentation] Attempt to present <Juice.LoginViewController: 0x12dd0df30> on <Juice.ResultViewController: 0x12dd09660> (from <Juice.ResultViewController: 0x12dd09660>) whose view is not in the window hierarchy.
        // self.showLoginViewController()
    }

    @IBAction func signInButtonPressed() {
        DispatchQueue.main.async {
            self.showLoginViewController()
        }
    }

    @IBAction func signOutButtonPressed() {
        dispatchOnAuthorization { result in
            switch result {
            case let .success(isAuthorized):
                self.printClassAndFunc("Authorization status: \(isAuthorized)")
                // The Apple ID credential was found,
                // pop up an alert asking user to delete the account in Settings

                // Ask user to delete the Juice account in Settings
                // and then come back to this app

                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Delete Account", message: "Please delete the Juice account in " + "Settings : <your name> : Password and Security : Connect with Apple " +
                        "and come back to this app.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }

            case let .failure(error):
                self.printClassAndFunc("Authorization error: \(error)")
                // The Apple ID credential is either revoked or was not found, so we can delete the keychain item
                DispatchQueue.main.async {
                    // Delete the user identifier that was previously stored in the keychain.
                    KeychainItem.deleteCurrenUserCredential()

                    // Clear the user interface.
                    self.userIdentifierLabel.text = ""
                    self.givenNameLabel.text = ""
                    self.fullNameLabel.text = ""
                    self.emailLabel.text = ""

                    // enable for testing
                    // self.showLoginViewController()

                    // present pop up an alert-OK saying that the user account was deleted

                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Account Deleted", message: "Your account has been successfully deleted.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    fileprivate func dispatchOnAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserCredential.id) { credentialState, _ in
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

    public func updateKeychainLabels() {

//            viewController.userIdentifierLabel.text = credential.user
//            if let fullName = credential.fullName {
//                viewController.givenNameLabel.text = fullName.givenName
//                viewController.fullNameLabel.text = fullName.familyName
//            }
//            if let email = credential.email {
//                 viewController.emailLabel.text = email
//            }
        userIdentifierLabel.text = "userID: " + KeychainItem.currentUserCredential.id
        fullNameLabel.text = "fullName: " + KeychainItem.currentUserCredential.fullName
        emailLabel.text = "email: " + KeychainItem.currentUserCredential.email
    }

    public func updateCredentialLabels(from credential: ASAuthorizationAppleIDCredential) {
        userIDLabel.text = "userID: " + credential.user
        stateLabel.text = "state: " + (credential.state ?? "")
        authorizedScopesLabel.text = "authorizedScopes: " + convertAuthorizedScopesToString(from: credential)
        authorizationCodeLabel.text = "authorizationCode: " + convertAuthorizationCodeToString(from: credential)
        identityTokenLabel.text = "identityToken: " + convertIdentityTokenToString(from: credential)
        emailLabel2.text = "email: " + (credential.email ?? "")
        fullNameLabel2.text = convertFullNameToString(from: credential)
        realUserStatusLabel.text = "realUserStatus: " + convertRealUserStatusToString(from: credential)
    }

    private func convertRealUserStatusToString(from credential: ASAuthorizationAppleIDCredential) -> String {
        switch credential.realUserStatus {
        case .likelyReal:
            return "Likely Real"
        case .unknown:
            return "Unknown"
        case .unsupported:
            return "Unsupported"
        @unknown default:
            return "Unknown"
        }
    }

    private func convertIdentityTokenToString(from credential: ASAuthorizationAppleIDCredential) -> String {
        guard let identityTokenData = credential.identityToken else {
            return ""
        }
        return String(data: identityTokenData, encoding: .utf8) ?? ""
    }

    private func convertAuthorizationCodeToString(from credential: ASAuthorizationAppleIDCredential) -> String {
        guard let authorizationCodeData = credential.authorizationCode else {
            return ""
        }
        return String(data: authorizationCodeData, encoding: .utf8) ?? ""
    }

    private func convertAuthorizedScopesToString(from credential: ASAuthorizationAppleIDCredential) -> String {
        return credential.authorizedScopes.map { $0.rawValue }.joined(separator: ", ")
    }

    private func convertFullNameToString(from credential: ASAuthorizationAppleIDCredential) -> String {
        guard let fullName = credential.fullName else {
            return ""
        }
        let familyName = fullName.familyName ?? ""
        let givenName = fullName.givenName ?? ""
        return "fullName: \(familyName) \(givenName)"
    }
}
