//
//  ContactHelper.swift
//  
//
//  Created by Sam Johnson on 12/22/22.
//

import Foundation
import Contacts
import Vapor

public class ContactHelper {
    
    var app: Application
    var addressCache: [String:String] = [:]
    let lock = NSLock()
    
    init(_ app: Application) {
        self.app = app
    }
    
    func parseAddress(_ rawAddress: String) -> String {
        let addresses = rawAddress.split(separator: ",")
        var parsedAddresses: [String] = []
        
        for address in addresses {
            let addressStr = String(address)
            
            if let cached = addressCache[addressStr] {
                parsedAddresses.append(cached)
                continue
            }
            
            let parsedAddress = getContactName(from: addressStr)
            parsedAddresses.append(parsedAddress)
            
            lock.lock()
            addressCache[addressStr] = parsedAddress
            lock.unlock()
        }
        
        return parsedAddresses.joined(separator: ", ")
    }
    
    func getContactName(from address: String) -> String {
        let store = CNContactStore()
        do {
            var predicate: NSPredicate
            var keysToFetch: [CNKeyDescriptor]
            
            if let _ = address.firstIndex(of: "@") {
                predicate = CNContact.predicateForContacts(matchingEmailAddress: address)
                keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName) as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor]
            } else {
                predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: address))
                keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName) as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
            }
            
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            
            guard contacts.count > 0 else {
                return address
            }
            
            let parsedAddress = CNContactFormatter.string(from: contacts[0], style: .fullName) ?? address
            return parsedAddress
        } catch {
            app.logger.error("Failed to fetch contact, error: \(error)")
            return address
        }
    }
    
}
