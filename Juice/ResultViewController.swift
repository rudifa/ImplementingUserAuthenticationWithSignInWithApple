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
    @IBOutlet var familyNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var signOutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        userIdentifierLabel.text = KeychainItem.currentUserIdentifier
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
                    let alertController = UIAlertController(title: "Delete Account", message: "Please delete the Juice account in Settings and then come back to this app.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }

            case let .failure(error):
                self.printClassAndFunc("Authorization error: \(error)")
                // The Apple ID credential is either revoked or was not found, so we can delete the keychain item
                DispatchQueue.main.async {
                    // Delete the user identifier that was previously stored in the keychain.
                    KeychainItem.deleteUserIdentifierFromKeychain()

                    // Clear the user interface.
                    self.userIdentifierLabel.text = ""
                    self.givenNameLabel.text = ""
                    self.familyNameLabel.text = ""
                    self.emailLabel.text = ""

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
}
