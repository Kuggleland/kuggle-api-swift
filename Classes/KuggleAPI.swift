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
    
    func getRequest(endpointName: String, token: AnyObject?, params: AnyObject?, getRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("GET", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            getRequestCompletionHandler(json: json, responseError: error)
        })
    }
    
    func postRequest(endpointName: String, token: AnyObject?, params: AnyObject?, postRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("POST", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            postRequestCompletionHandler(json: json, responseError: error)
        })
    }

    func request(methodName : String, endpointName: String, token: AnyObject?, params: AnyObject?, requestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        if let t : String = token as? String {
            rawRequest(methodName, urlString: KuggleAPI.baseURL() + endpointName, headers: ["Token": t], params: params, rawRequestCompletionHandler: {json, error -> Void in
                let meta = (json as! NSDictionary)["meta"] as! NSDictionary
                let metaCode = meta.objectForKey("code") as! NSInteger
                let metaMsg = meta.objectForKey("msg") as! String
                if (metaCode != 200) {
                    requestCompletionHandler(json: json, responseError: NSError(domain: metaMsg, code: metaCode, userInfo: nil))
                } else {
                    requestCompletionHandler(json: json, responseError: error)
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
