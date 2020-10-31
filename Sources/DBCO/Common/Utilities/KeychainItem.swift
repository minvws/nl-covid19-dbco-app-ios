/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class KeychainItem<T: Codable> {
    
    enum KeychainError: Error {
        case notFound
        case unexpectedData
        case unhandledError(status: OSStatus)
    }
    
    var value: T? {
        get {
            return try? read()
        }
        
        set {
            try? save(value: newValue)
        }
    }
    
    var exists: Bool {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanFalse
        query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        switch status {
        case errSecInteractionNotAllowed, noErr:
            return true
            
        default:
            return false
        }
    }
    
    private let name: String
    private let service: String?
    
    init(name: String, service: String?) {
        self.name = name
        self.service = service
    }
    
    // JSONDecoder/Encoder doesn't like fragments
    private struct Wrapped: Codable {
        let value: T
    }
    
    fileprivate func read() throws -> T {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        let decoder = JSONDecoder()
        
        // Parse the value from the query result.
        guard let existingItem = queryResult as? [String: AnyObject], let passwordData = existingItem[kSecValueData as String] as? Data else {
            throw KeychainError.unexpectedData
        }
        
        if let password = try? decoder.decode(Wrapped.self, from: passwordData) {
            return password.value
        } else if T.self is String.Type, let password = String(data: passwordData, encoding: .utf8) {
            return password as! T
        } else {
            throw KeychainError.unexpectedData
        }
    }
    
    fileprivate func save(value: T?) throws {
        guard let value = value else {
            if exists {
                try delete()
            }
            
            return
        }
        
        // Encode the value into an Data object.
        guard let encoded = try? JSONEncoder().encode(Wrapped(value: value)) else {
            throw KeychainError.unexpectedData
        }
        
        if exists {
            // Update the existing item with the new value.
            
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = encoded as AnyObject?
            
            let query = baseQuery()
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        } else {
            /*
             No value was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = baseQuery()
            newItem[kSecValueData as String] = encoded as AnyObject?
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    fileprivate func delete() throws {
        // Delete the existing item from the keychain.
        let query = baseQuery()
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    private func baseQuery() -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        if let service = service {
            query[kSecAttrService as String] = service as AnyObject?
        }
        query[kSecAttrAccount as String] = name as AnyObject?
        
        return query
    }
    
}

// MARK: - Cached Variant
class CachedKeychainItem<T: Codable>: KeychainItem<T> {
    
    override var value: T? {
        get {
            cachedValue = cachedValue ?? (try? read())
            return cachedValue
        }
        
        set {
            cachedValue = newValue
            try? save(value: newValue)
        }
    }
    
    private var cachedValue: T?
    
    override func delete() throws {
        cachedValue = nil
        
        try super.delete()
    }
    
    func clearCache() {
        cachedValue = nil
    }
}

// MARK: - Property Wrapper
@propertyWrapper struct Keychain<T: Codable> {
    let projectedValue: CachedKeychainItem<T>
    private let defaultValue: T
    
    init(wrappedValue: T, name: String, service: String? = nil) {
        projectedValue = .init(name: name, service: service)
        self.defaultValue = wrappedValue
    }
    
    init(name: String, service: String? = nil, defaultValue: T) {
        projectedValue = .init(name: name, service: service)
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            projectedValue.value ?? defaultValue
        }
        set {
            projectedValue.value = newValue
        }
    }
}
