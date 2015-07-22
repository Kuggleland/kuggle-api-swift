# Kuggle API Swift class
Class to interface with the Kuggle backend

This is a work in progress.

## Sample code to query

### Instantiating this class
```swift
  var kuggle = KuggleAPI.sharedInstance
```

### Registration using facebook
#### Parameters
* 'fbtoken' - This is the token returned from the *OAUTH Dance* from the application. This endpoint will validate the users profile and decide whether or not to create it.

#### Expected Response
* 'fromfb' - This is what the app has pulled from facebook. Which contains a 'birthday' (Javascript Date format), 'birthdaystring' (format which you can actually serialize back into a javascript date object), 'firstname', 'gender' (0 = female, 1 = male, 2 = other or undisclosed), 'id' (the users facebook ID)
* 'token' - This is the login token that you need to use on protected endpoints. Only returned if registration was successful. Check NSError and display error.domain to user (this response is localized if you're using this API)

#### Other things to note
* Profile is automatically created. No need to call the create profile endpoint.

```swift
        k.postRequest("register", token: nil, params: ["fbtoken": "tokengoeshere"], postRequestCompletionHandler: {json,err -> Void in
            if (err == nil) {
                let meta = (json as! NSDictionary)["meta"] as! NSDictionary
                let metaCode = meta.objectForKey("code") as! NSInteger
                let metaMsg = meta.objectForKey("msg") as! String
                println(metaCode)
                println(metaMsg)
                println(json)
            } else {
                if let error : NSError = err as NSError!
                {
                    println(error.code)
                    println(error.domain)
                }
            }

        })
```

### Registration by Phone Number

* replace '+11234567' with a phone number thats valid.

This only returns a 'meta' key. 200 is always good. Its automatically read and returns in NSError format. error.code is the HTTP code, and error.domain is the error message (this is also localized depending on the users phone settings)

```swift
  kuggle.postRequest("register", token: nil, params: ["phonenumber": "+11234567"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      let meta = (json as! NSDictionary)["meta"] as! NSDictionary
      let metaCode = meta.objectForKey("code") as! NSInteger
      let metaMsg = meta.objectForKey("msg") as! String
      println(metaCode)
      println(metaMsg)
      println(json)
    } else {
      if let error : NSError = err as NSError!
      {
        println(error.code)
        println(error.domain)
      }
    }
  })
```

### Verify PIN

* replace '+11234567' with a phone number thats valid.
* replace '12345' with a PIN thats valid

This functionality, returns the 'meta' key, as well as 'token' if successfully validated.

```swift
  kuggle.postRequest("register", token: nil, params: ["phonenumber": "+11234567", "pin": "12345"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      let meta = (json as! NSDictionary)["meta"] as! NSDictionary
      let metaCode = meta.objectForKey("code") as! NSInteger
      let metaMsg = meta.objectForKey("msg") as! String
      println(metaCode)
      println(metaMsg)
      println(json)
    } else {
      if let error : NSError = err as NSError!
      {
        println(error.code)
        println(error.domain)
      }
    }
  })
```
### Get User Profile

This is an example how to fetch a user profile.
It will return the following keys:
* profilecreated - Is the user already known. This is usually set to false if registered with a phone number, as the number is verified but there is no profile.
* profile - Shows the user's profile. Their 'facebookid' or 'phonenumber' (depends how they registered). Their 'firstname'. Their 'dob' in a friendly format. Their 'gender' (which is 'female', 'male', or 'other'). The persons 'invitecode'
* meta - This is included in all responses. Will show information pertaining to the response itself.

```swift
  k.getRequest("profile", token: "Your Token Here", params: nil,  getRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      let meta = (json as! NSDictionary)["meta"] as! NSDictionary
      let metaCode = meta.objectForKey("code") as! NSInteger
      let metaMsg = meta.objectForKey("msg") as! String
      println(metaCode)
      println(metaMsg)
      println(json)
    } else {
      if let error : NSError = err as NSError!
        {
          println(error.code)
          println(error.domain)
        }
    }
  })
```
### Create Profile

This functionality is used when a user attempts to use phone number registration.

Either returns success or fail (in status codes)

```swift
  k.postRequest("profile", token: "EXAMPLE", params: ["firstname": "Joe", "dob": "1990-03-05", "gender": "1"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
        let meta = jsonResp["meta"] as! NSDictionary
          let metaCode = meta.objectForKey("code") as! NSInteger
          let metaMsg = meta.objectForKey("msg") as! String
          println(metaMsg)
          println(jsonResp)
      }
    } else {
      if let error : NSError = err as NSError!
        {
          println(error.code)
          println(error.domain)
        }
    }

  })
```

### Get Balance

Returns your kredits balance as a 'balance' key.

```swift
  k.getRequest("kredits", token: "USERTOKEN", params: nil, getRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
        let balance = jsonResp["balance"] as! NSInteger
        println(balance)
      }
    } else {
      if let error : NSError = err as NSError! {
        println(error.code)
        println(error.domain)
      }
    }
  })
```
