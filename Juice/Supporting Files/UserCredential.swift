//
//  UserCredential.swift v.0.2.0
//  shAre
//
//  Created by Rudolf Farkas on 27.05.20.
//  Copyright © 2020 Eric PAJOT. All rights reserved.
//

import AuthenticationServices
import Foundation

struct UserCredential: Codable, Equatable {
    let id: String
    let fullName: String
    let email: String

    init(id: String = "", fullName: String = "", email: String = "") {
        self.id = id
        self.fullName = fullName
        self.email = email
    }

    init(credential: ASAuthorizationAppleIDCredential) {
        id = credential.user
        if let givenName = credential.fullName?.givenName,
            let familyName = credential.fullName?.familyName {
            fullName = Self.fullName(givenName: givenName, familyName: familyName)
        } else {
            fullName = ""
        }
        email = credential.email ?? ""
    }

    var isComplete: Bool {
        return id != "" && fullName != "" && email != ""
    }

    var brief: String {
        var strs: [String] = []
        strs.append("id= \(id)")
        strs.append("fullName= \(fullName)")
        strs.append("email= \(email)")
        return strs.joined(separator: ", ")
    }

    static let keychainAccount = "userCredentials"

    static func fullName(givenName: String, familyName: String) -> String {
        return "\(givenName) \(familyName)"
    }
}

