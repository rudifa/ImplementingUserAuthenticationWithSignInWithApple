# wip AppleSignIn / SignOut

[Enhance your Sign in with Apple experience](https://developer.apple.com/videos/play/wwdc2022/10122/) video wwdc 2022

> authorizationCode, how to use: ~10' - 12'

> account deletion: ~13' - ...

## How to get complete user credential (with email and fullName)

This is returned by `func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)` only on the first login with Apple (first for the user + app combination).

In shAre and in Juice we store the complete UserCredential in the Keychain.

If we need to go back to this 'first login with Apple' for testing purposes, [here is how](https://forums.developer.apple.com/forums/thread/121496):

>Hello ZhuHaoyu, This is possible to go back to the first registration behavior.
To do this, login with the [apple account](https://appleid.apple.com/account/manage).
Then go to "sign in and security" > "sign in with apple".
A popup appears showing apps and website where apple sign-in is used.
Clic on the app of your choice and then on "stop using sign in with apple".
ma.coutanceau —  ma.coutanceau 1 year ago

## JWTDecode

[JWTDecode package](https://swiftpackageindex.com/auth0/JWTDecode.swift)
