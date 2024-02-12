//
//  KeychainItem.swift
//  shAre
//
//  Created by Rudolf Farkas on 29.05.20
//  Copyright © 2020 Eric PAJOT. All rights reserved.
//

import Foundation

struct KeychainItem {
    // MARK: Types

    enum KeychainError: Error {
        case noDataFound
        case unexpectedData
        case unhandledError
    }

    // MARK: Properties

    private let service = Bundle.main.bundleIdentifier ?? ""
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""

    private(set) var account: String

    let accessGroup: String?

    // MARK: Intialization

    init(account: String, accessGroup: String? = nil) {
        self.account = account
        self.accessGroup = accessGroup
    }

    // MARK: Keychain access

    func readItem<T: Codable>() throws -> T {
        let data = try read()
        let value = try JSONDecoder().decode(T.self, from: data)
        return value
    }

    func saveItem<T: Codable>(_ item: T) throws {
        let data = try JSONEncoder().encode(item)
        try save(encodedData: data)
    }

    // MARK: Keychain access helpers

    func read() throws -> Data {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        var query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noDataFound }
        guard status == noErr else { throw KeychainError.unhandledError }

        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String: AnyObject],
            let data = existingItem[kSecValueData as String] as? Data
        else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    private func save(encodedData: Data) throws {
        do {
            // Check for an existing item in the keychain.
            try _ = read()

            // Update the existing item with the new data.
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedData as AnyObject?

            let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError }
        } catch KeychainError.noDataFound {
            /*
             No data was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedData as AnyObject?

            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError }
        }
    }

    func deleteItem() throws {
        // Delete the existing item from the keychain.
        let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)

        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError }
    }

    // MARK: Convenience

    private static func keychainQuery(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?

        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }

        return query
    }
}

extension KeychainItem {
    static var currentUserCredential: UserCredential {
        do {
            let storedCredentials: UserCredential = try KeychainItem(account: UserCredential.keychainAccount).readItem()
            return storedCredentials
        } catch {
            return UserCredential()
        }
    }

    static func saveCurrentUserCredential(_ credential: UserCredential) {
        do {
            try KeychainItem(account: UserCredential.keychainAccount).saveItem(credential)
        } catch {
            print("saveItem failed")
        }
    }

    static func deleteCurrenUserCredential() {
        do {
            try KeychainItem(account: UserCredential.keychainAccount).deleteItem()
        } catch {
            print("Unable to delete user credential from keychain")
        }
    }
}
