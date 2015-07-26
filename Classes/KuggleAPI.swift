import UIKit
import Security
import Foundation

// Keychain Integration
/**

A collection of helper functions for saving text and data in the keychain.

*/
public class KeychainSwift {
    
    static var lastQueryParameters: [String: NSObject]? // Used by unit tests
    
    /**
    
    Stores the text value in the keychain item under the given key.
    
    - parameter key: Key under which the text value is stored in the keychain.
    - parameter value: Text string to be written to the keychain.
    - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
    
    */
    public class func set(value: String, forKey key: String,
        withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
            
            if let value = value.dataUsingEncoding(NSUTF8StringEncoding) {
                return set(value, forKey: key, withAccess: access)
            }
            
            return false
    }
    
    /**
    
    Stores the data in the keychain item under the given key.
    
    - parameter key: Key under which the data is stored in the keychain.
    - parameter value: Data to be written to the keychain.
    - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
    
    - returns: True if the text was successfully written to the keychain.
    
    */
    public class func set(value: NSData, forKey key: String,
        withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
            
            let accessible = access?.value ?? KeychainSwiftAccessOptions.defaultOption.value
            
            let query = [
                KeychainSwiftConstants.klass       : KeychainSwiftConstants.classGenericPassword,
                KeychainSwiftConstants.attrAccount : key,
                KeychainSwiftConstants.valueData   : value,
                KeychainSwiftConstants.accessible  : accessible
            ]
            
            lastQueryParameters = query
            
            SecItemDelete(query as CFDictionaryRef)
            
            let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
            
            return status == noErr
    }
    
    /**
    
    Retrieves the text value from the keychain that corresponds to the given key.
    
    - parameter key: The key that is used to read the keychain item.
    - returns: The text value from the keychain. Returns nil if unable to read the item.
    
    */
    public class func get(key: String) -> String? {
        if let data = getData(key),
            let currentString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                
                return currentString
        }
        
        return nil
    }
    
    /**
    
    Retrieves the data from the keychain that corresponds to the given key.
    
    - parameter key: The key that is used to read the keychain item.
    - returns: The text value from the keychain. Returns nil if unable to read the item.
    
    */
    public class func getData(key: String) -> NSData? {
        let query = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : key,
            KeychainSwiftConstants.returnData  : kCFBooleanTrue,
            KeychainSwiftConstants.matchLimit  : kSecMatchLimitOne ]
        
        var result: AnyObject?
        
        let status = withUnsafeMutablePointer(&result) {
            SecItemCopyMatching(query, UnsafeMutablePointer($0))
        }
        
        if status == noErr { return result as? NSData }
        
        return nil
    }
    
    /**
    
    Deletes the single keychain item specified by the key.
    
    - parameter key: The key that is used to delete the keychain item.
    - returns: True if the item was successfully deleted.
    
    */
    public class func delete(key: String) -> Bool {
        let query = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
    /**
    
    Deletes all keychain items used by the app.
    
    - returns: True if the keychain items were successfully deleted.
    
    */
    public class func clear() -> Bool {
        let query = [ kSecClass as String : kSecClassGenericPassword ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
}


// ----------------------------
//
// KeychainSwiftAccessOptions.swift
//
// ----------------------------

import Security

/**

These options are used to determine when a keychain item should be readable. The default value is AccessibleWhenUnlocked.

*/
public enum KeychainSwiftAccessOptions {
    
    /**
    
    The data in the keychain item can be accessed only while the device is unlocked by the user.
    
    This is recommended for items that need to be accessible only while the application is in the foreground. Items with this attribute migrate to a new device when using encrypted backups.
    
    This is the default value for keychain items added without explicitly setting an accessibility constant.
    
    */
    case AccessibleWhenUnlocked
    
    /**
    
    The data in the keychain item can be accessed only while the device is unlocked by the user.
    
    This is recommended for items that need to be accessible only while the application is in the foreground. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
    
    */
    case AccessibleWhenUnlockedThisDeviceOnly
    
    /**
    
    The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
    
    After the first unlock, the data remains accessible until the next restart. This is recommended for items that need to be accessed by background applications. Items with this attribute migrate to a new device when using encrypted backups.
    
    */
    case AccessibleAfterFirstUnlock
    
    /**
    
    The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
    
    After the first unlock, the data remains accessible until the next restart. This is recommended for items that need to be accessed by background applications. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
    
    */
    case AccessibleAfterFirstUnlockThisDeviceOnly
    
    /**
    
    The data in the keychain item can always be accessed regardless of whether the device is locked.
    
    This is not recommended for application use. Items with this attribute migrate to a new device when using encrypted backups.
    
    */
    case AccessibleAlways
    
    /**
    
    The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on the device.
    
    This is recommended for items that only need to be accessible while the application is in the foreground. Items with this attribute never migrate to a new device. After a backup is restored to a new device, these items are missing. No items can be stored in this class on devices without a passcode. Disabling the device passcode causes all items in this class to be deleted.
    
    */
    case AccessibleWhenPasscodeSetThisDeviceOnly
    
    /**
    
    The data in the keychain item can always be accessed regardless of whether the device is locked.
    
    This is not recommended for application use. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
    
    */
    case AccessibleAlwaysThisDeviceOnly
    
    static var defaultOption: KeychainSwiftAccessOptions {
        return .AccessibleWhenUnlocked
    }
    
    var value: String {
        switch self {
        case .AccessibleWhenUnlocked:
            return toString(kSecAttrAccessibleWhenUnlocked)
            
        case .AccessibleWhenUnlockedThisDeviceOnly:
            return toString(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
            
        case .AccessibleAfterFirstUnlock:
            return toString(kSecAttrAccessibleAfterFirstUnlock)
            
        case .AccessibleAfterFirstUnlockThisDeviceOnly:
            return toString(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
            
        case .AccessibleAlways:
            return toString(kSecAttrAccessibleAlways)
            
        case .AccessibleWhenPasscodeSetThisDeviceOnly:
            return toString(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
            
        case .AccessibleAlwaysThisDeviceOnly:
            return toString(kSecAttrAccessibleAlwaysThisDeviceOnly)
        }
    }
    
    func toString(value: CFStringRef) -> String {
        return KeychainSwiftConstants.toString(value)
    }
}


// ----------------------------
//
// TegKeychainConstants.swift
//
// ----------------------------

import Foundation
import Security

public struct KeychainSwiftConstants {
    public static var klass: String { return toString(kSecClass) }
    public static var classGenericPassword: String { return toString(kSecClassGenericPassword) }
    public static var attrAccount: String { return toString(kSecAttrAccount) }
    public static var valueData: String { return toString(kSecValueData) }
    public static var returnData: String { return toString(kSecReturnData) }
    public static var matchLimit: String { return toString(kSecMatchLimit) }
    
    /**
    
    A value that indicates when your app needs access to the data in a keychain item. The default value is AccessibleWhenUnlocked. For a list of possible values, see KeychainSwiftAccessOptions.
    
    */
    public static var accessible: String { return toString(kSecAttrAccessible) }
    
    static func toString(value: CFStringRef) -> String {
        return value as String
    }
}

// Kuggle API Integration
class KuggleAPI :NSObject {
    static let sharedInstance = KuggleAPI()
    
    override init() {
        super.init()
    
    }
    
    // Helper methods
    static func langCode() -> String {
        return NSLocale.currentLocale().localeIdentifier
    }
    
    static func baseURL() -> String {
        return "https://api.kuggleland.com/1/"
    }
    
    func getRequest(endpointName: String, token: AnyObject?, params: AnyObject?, getRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("GET", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            
            if (endpointName == "profile") {
                if (error != nil) {
                    if let errorFlag : NSError = error as NSError! {
                        if errorFlag.code == 401 { // Remove the token if there is an error
                            KeychainSwift.delete("token")
                        }
                    }
                }
            }
            getRequestCompletionHandler(json: json, responseError: error)
        })
    }
    
    func postRequest(endpointName: String, token: AnyObject?, params: AnyObject?, postRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("POST", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            if error == nil {
                // If there is a token (most likely from register endpoint) given lets set it up
                if let token = (json as! NSDictionary)["token"] as? String {
                    KeychainSwift.set(token, forKey: "token")
                }
                postRequestCompletionHandler(json: json, responseError: error)
            } else {
                postRequestCompletionHandler(json: json, responseError: error)
            }
        })
    }

    func request(methodName : String, endpointName: String, token: AnyObject?, params: AnyObject?, requestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        if let t : String = token as? String {
            rawRequest(methodName, urlString: KuggleAPI.baseURL() + endpointName, headers: ["Token": t], params: params, rawRequestCompletionHandler: {json, error -> Void in
                if error == nil {
                    let meta = (json as! NSDictionary)["meta"] as! NSDictionary
                    let metaCode = meta.objectForKey("code") as! NSInteger
                    let metaMsg = meta.objectForKey("msg") as! String
                    if (metaCode != 200) {
                        requestCompletionHandler(json: json, responseError: NSError(domain: metaMsg, code: metaCode, userInfo: nil))
                    } else {
                        requestCompletionHandler(json: json, responseError: error)
                    }
                } else {
                    requestCompletionHandler(json: nil, responseError: error)
                }
            })
        } else {
            rawRequest(methodName, urlString: KuggleAPI.baseURL() + endpointName, headers: nil, params: params, rawRequestCompletionHandler: {json, error -> Void in
                let meta = (json as! NSDictionary)["meta"] as! NSDictionary
                let metaCode = meta.objectForKey("code") as! NSInteger
                let metaMsg = meta.objectForKey("msg") as! String
                if (metaCode != 200) {
                    requestCompletionHandler(json: json, responseError: NSError(domain: metaMsg, code: metaCode, userInfo: nil))
                } else {
                    requestCompletionHandler(json: json, responseError: error)
                }
                
            })
        }
    }
    
    // Raw Request
    func rawRequest(methodName : String, urlString: String, headers: AnyObject?, params: AnyObject?, rawRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        var err: NSError?
        let currentLocale = NSLocale.currentLocale()
        let localeidentifier: AnyObject? = currentLocale.objectForKey(NSLocaleIdentifier)
        let localeidentifierstring = localeidentifier?.stringValue
        var request = NSMutableURLRequest()
        if let p : Dictionary<String, String> = params as? Dictionary<String, String> {
            if (methodName == "GET" || methodName == "DELETE") {
                var urlStringWithParams = urlString + "?" + query(p)
                request = NSMutableURLRequest(URL: NSURL(string: urlStringWithParams)!)
            } else {
                // POST or PUT with params (dont put them in URL)
                request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            }
        } else {
            // POST or PUT no params
            request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        }

        var session = NSURLSession.sharedSession()
        request.HTTPMethod = methodName
        if let p : Dictionary<String, String> = params as? Dictionary<String, String> {
            if (methodName == "POST" || methodName == "PUT") {
                // POST or PUT and PARAMS specified
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.HTTPBody = query(p).dataUsingEncoding(NSUTF8StringEncoding)
            }
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(localeidentifierstring, forHTTPHeaderField: "Accept-language")
        // Custom Headers
        if let h : Dictionary<String,String> = headers as? Dictionary<String,String> {
            for (key: String, value: String) in h {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 404 || httpResponse.statusCode == 401 {
                // 200 Response, 404, or 401 = Lets try the JSON
                if (error == nil) {
                    var jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.allZeros, error: &err)
                    rawRequestCompletionHandler(json: jsonObject, responseError: err)
                } else {
                    rawRequestCompletionHandler(json: nil, responseError: error)
                }
            } else {
                rawRequestCompletionHandler(json: nil, responseError: NSError(domain: "GeneralHTTPError", code: httpResponse.statusCode, userInfo: nil))
            }
        })
        task.resume()
    }
    
    // Utils
    func escape(string: String) -> String {
        let generalDelimiters = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimiters = "!$&'()*+,;="
        
        let legalURLCharactersToBeEscaped: CFStringRef = generalDelimiters + subDelimiters
        
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.extend([(escape(key), escape("\(value)"))])
        }
        
        return components
    }
    
    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in sorted(Array(parameters.keys), <) {
            let value: AnyObject! = parameters[key]
            components += self.queryComponents(key, value)
        }
        
        return join("&", components.map{"\($0)=\($1)"} as [String])
    }
}
