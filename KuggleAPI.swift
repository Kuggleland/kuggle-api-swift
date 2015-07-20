import Foundation

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
    
    func getRequest(endpointName: String, token: String, params: Dictionary<String,String>, getRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("GET", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            getRequestCompletionHandler(json: json, responseError: error)
        })
    }
    
    func postRequest(endpointName: String, token: String, params: Dictionary<String,String>, getRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("POST", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            getRequestCompletionHandler(json: json, responseError: error)
        })
    }

    func request(methodName : String, endpointName: String, token: String, params: Dictionary<String,String>, requestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        rawRequest(methodName, urlString: KuggleAPI.baseURL() + endpointName, headers: ["Token": token], params: params, rawRequestCompletionHandler: {json, error -> Void in
            requestCompletionHandler(json: json, responseError: error)
        })
    }
    
    // Raw Request
    func rawRequest(methodName : String, urlString: String, headers: Dictionary<String,String>, params: Dictionary<String,String>, rawRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        var err: NSError?
        let currentLocale = NSLocale.currentLocale()
        let localeidentifier: AnyObject? = currentLocale.objectForKey(NSLocaleIdentifier)
        let localeidentifierstring = localeidentifier?.stringValue
        var request = NSMutableURLRequest()
        if (methodName == "GET" || methodName == "DELETE") {
            var urlStringWithParams = urlString + "?" + query(params)
            request = NSMutableURLRequest(URL: NSURL(string: urlStringWithParams)!)
        } else {
            request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        }

        var session = NSURLSession.sharedSession()
        request.HTTPMethod = methodName
        if (methodName == "POST" || methodName == "PUT") {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = query(params).dataUsingEncoding(NSUTF8StringEncoding)
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(localeidentifierstring, forHTTPHeaderField: "Accept-language")
        // Custom Headers
        for (key: String, value: String) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if (error == nil) {
                var jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.allZeros, error: &err)
                
                rawRequestCompletionHandler(json: jsonObject, responseError: err)
            } else {
                rawRequestCompletionHandler(json: nil, responseError: error)
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
