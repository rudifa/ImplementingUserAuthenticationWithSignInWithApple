/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Login view controller.
 */

import AuthenticationServices
import UIKit

class LoginViewController: UIViewController {
    @IBOutlet var loginProviderStackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProviderLoginView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlows()
    }

    /// - Tag: add_appleid_button
    func setupProviderLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        loginProviderStackView.addArrangedSubview(authorizationButton)
    }

    // - Tag: perform_appleid_password_request
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]

        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    /// - Tag: perform_appleid_request
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:

            self.printClassAndFunc("appleIDCredential:\n\(appleIDCredential)")

            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            // For the purpose of this demo app, store the `userIdentifier` in the keychain.
            saveUserInKeychain(userIdentifier)

            // For the purpose of this demo app, show the Apple ID credential information in the `ResultViewController`.
            showResultViewController(userIdentifier: userIdentifier, fullName: fullName, email: email)

        case let passwordCredential as ASPasswordCredential:

            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password

            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                self.showPasswordCredentialAlert(username: username, password: password)
            }

        default:
            break
        }
    }

    private func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.example.apple-samplecode.juice", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            self.printClassAndFunc("Unable to save userIdentifier to keychain.")
        }
    }

    private func showResultViewController(userIdentifier: String, fullName: PersonNameComponents?, email: String?) {
        guard let viewController = presentingViewController as? ResultViewController
        else { return }

        DispatchQueue.main.async {
            viewController.userIdentifierLabel.text = userIdentifier
            if let givenName = fullName?.givenName {
                viewController.givenNameLabel.text = givenName
            }
            if let familyName = fullName?.familyName {
                viewController.familyNameLabel.text = familyName
            }
            if let email = email {
                viewController.emailLabel.text = email
            }
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}

extension UIViewController {
    func showLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? LoginViewController {
            loginViewController.modalPresentationStyle = .formSheet
            loginViewController.isModalInPresentation = true
            present(loginViewController, animated: true, completion: nil)
        }
    }
}

extension ASUserDetectionStatus {
    var description: String {
        switch self {
        case .unsupported: "unsupported"
        case .unknown: "unknown"
        case .likelyReal: "likelyReal"
        @unknown default:
            fatalError()
        }
    }
}

// public enum ASUserDetectionStatus : Int, @unchecked Sendable {
//
//
//    case unsupported = 0
//
//    case unknown = 1
//
//    case likelyReal = 2
// }
//

extension ASAuthorizationAppleIDCredential {
    override open var description: String {
        var sarr: [String] = []
        sarr.append("userID: \(user)") // An opaque user ID associated with the AppleID used for the sign in. This identifier will be stable across the 'developer team', it can later be used as an input to @see ASAuthorizationRequest to request user contact information. The identifier will remain stable as long as the user is connected with the requesting client.  The value may change upon user disconnecting from the identity provider.
        sarr.append("state: \(state ?? "")") // A copy of the state value that was passed to ASAuthorizationRequest.
        sarr.append("authorizedScopes: \(authorizedScopes)") // This value will contain a list of scopes for which the user provided authorization.  These may contain a subset of the requested scopes on @see ASAuthorizationAppleIDRequest.  The application should query this value to identify which scopes were returned as it maybe different from ones requested.
        var authorizationCodeStr = ""
        if let authorizationCode {
            authorizationCodeStr = String(data: authorizationCode, encoding: .utf8)!
        }
        sarr.append("authorizationCode: \(authorizationCodeStr)") // A short-lived, one-time valid token that provides proof of authorization to the server component of the app. The authorization code is bound to the specific transaction using the state attribute passed in the authorization request. The server component of the app can validate the code using Apple’s identity service endpoint provided for this purpose.
        var identityTokenStr = ""
        if let identityToken {
            identityTokenStr = String(data: identityToken, encoding: .utf8)!
        }
        sarr.append("identityToken: \(identityTokenStr)") // A JSON Web Token (JWT) used to communicate information about the identity of the user in a secure way to the app. The ID token will contain the following information: Issuer Identifier, Subject Identifier, Audience, Expiry Time and Issuance Time signed by Apple's identity service.
        sarr.append("email: \(email ?? "")") // An optional email shared by the user.  This field is populated with a value that the user authorized.
        var fullNameStr = ""
        if let fullName {
            fullNameStr = "\(fullName)"
        }
        sarr.append("fullName: \(fullNameStr)") // An optional full name shared by the user.  This field is populated with a value that the user authorized.
        sarr.append("realUserStatus: \(realUserStatus)") // Check this property for a hint as to whether the current user is a "real user".  @see ASUserDetectionStatus for guidelines on handling each status
        return sarr.joined(separator: "\n")
    }
}

// self.printClassAndFuncClassAndFunc("ASAuthorizationAppleIDCredential: \(credentials)")
// self.printClassAndFuncClassAndFunc("credentials.user: \(credentials.user)")
// self.printClassAndFuncClassAndFunc("credentials.email: \(credentials.email ?? "???")")
// self.printClassAndFuncClassAndFunc("credentials.fullName!.givenName: \(credentials.fullName!.givenName ?? "???")")
// self.printClassAndFuncClassAndFunc("credentials.fullName!.familyName: \(credentials.fullName!.familyName ?? "???")")

// @available(iOS 13.0, *)
// open class ASAuthorizationAppleIDCredential : NSObject, ASAuthorizationCredential {
//
//
//    /** @abstract An opaque user ID associated with the AppleID used for the sign in. This identifier will be stable across the 'developer team', it can later be used as an input to @see ASAuthorizationRequest to request user contact information.
//
//     The identifier will remain stable as long as the user is connected with the requesting client.  The value may change upon user disconnecting from the identity provider.
//     */
//    open var user: String { get }
//
//
//    /** @abstract A copy of the state value that was passed to ASAuthorizationRequest.
//     */
//    open var state: String? { get }
//
//
//    /** @abstract This value will contain a list of scopes for which the user provided authorization.  These may contain a subset of the requested scopes on @see ASAuthorizationAppleIDRequest.  The application should query this value to identify which scopes were returned as it maybe different from ones requested.
//     */
//    open var authorizedScopes: [ASAuthorization.Scope] { get }
//
//
//    /** @abstract A short-lived, one-time valid token that provides proof of authorization to the server component of the app. The authorization code is bound to the specific transaction using the state attribute passed in the authorization request. The server component of the app can validate the code using Apple’s identity service endpoint provided for this purpose.
//     */
//    open var authorizationCode: Data? { get }
//
//
//    /** @abstract A JSON Web Token (JWT) used to communicate information about the identity of the user in a secure way to the app. The ID token will contain the following information: Issuer Identifier, Subject Identifier, Audience, Expiry Time and Issuance Time signed by Apple's identity service.
//     */
//    open var identityToken: Data? { get }
//
//
//    /** @abstract An optional email shared by the user.  This field is populated with a value that the user authorized.
//     */
//    open var email: String? { get }
//
//
//    /** @abstract An optional full name shared by the user.  This field is populated with a value that the user authorized.
//     */
//    open var fullName: PersonNameComponents? { get }
//
//
//    /** @abstract Check this property for a hint as to whether the current user is a "real user".  @see ASUserDetectionStatus for guidelines on handling each status
//     */
//    open var realUserStatus: ASUserDetectionStatus { get }
// }

// public enum ASUserDetectionStatus : Int, @unchecked Sendable {
//
//
//    case unsupported = 0
//
//    case unknown = 1
//
//    case likelyReal = 2
// }
//
