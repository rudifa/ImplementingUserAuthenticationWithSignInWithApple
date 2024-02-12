//
//  ASAAIDCredential.swift
//  Juice
//
//  Created by Rudolf Farkas on 11.02.24.
//  Copyright © 2024 Apple. All rights reserved.
//

import AuthenticationServices

import JWTDecode

extension ASAuthorizationAppleIDCredential {
    func identToken() -> Data? {
        return identityToken
    }

    func unpackIdentityToken() throws -> JWT {
        guard let identityToken = self.identToken(), let jwtString = String(data: identityToken, encoding: .utf8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get identity token"])
        }

        do {
            let jwt = try decode(jwt: jwtString)
            return jwt
        } catch {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode JWT: \(error.localizedDescription)"])
        }
    }
}
