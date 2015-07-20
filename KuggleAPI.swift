// This is not refactored.

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
    
    func getRequest(endpointName: String, token: String, params: Dictionary<String, String>?, getRequestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        self.request("GET", endpointName: endpointName, token: token, params: params, requestCompletionHandler: {json, error -> Void in
            getRequestCompletionHandler(json: json, responseError: error)
        })
    }
    
    func request(methodName : String, endpointName: String, token: String, params: Dictionary<String, String>?, requestCompletionHandler: (json: AnyObject?, responseError: NSError?) -> Void) {
        var err: NSError?
        let currentLocale = NSLocale.currentLocale()
        let localeidentifier: AnyObject? = currentLocale.objectForKey(NSLocaleIdentifier)
        let localeidentifierstring = localeidentifier?.stringValue
        
        var request = NSMutableURLRequest(URL: NSURL(string: KuggleAPI.baseURL() + endpointName)!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = methodName
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(localeidentifierstring, forHTTPHeaderField: "Accept-language")
        if (token != "") {
            request.addValue(token, forHTTPHeaderField: "Token")
        }
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
            if (error == nil) {
                var jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.allZeros, error: &err)
                
                requestCompletionHandler(json: jsonObject, responseError: err)
            } else {
                requestCompletionHandler(json: nil, responseError: error)
            }
        })
        task.resume()
    }
