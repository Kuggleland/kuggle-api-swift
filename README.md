# Kuggle API Swift class
Class to interface with the Kuggle backend in a Swift blocks style API.

This is a work in progress. Pull requests welcome

## Useful inbuilt functionality
* Token keychain saving if there is a token attribute in the JSON dictionary returned
* Token keychain automatic revocation if there is a 401 error.
* Detects general HTTP errors like a good internet citizen should. So you should check if the json returned is nil.
* Sends language header.
* API is similar to the feel of the AlamoFire framework except it actually supports custom headers a bit better.

## Attributions

* Thanks to [exchangegroup/keychain-swift](https://github.com/exchangegroup/keychain-swift) for the keychain code.

## Installation

1. Add the following to your Podfile
```
platform :ios
pod 'KuggleAPI', :git => 'https://github.com/Kuggleland/kuggle-api-swift'
```

2. Then do a pod install.

There is no step 3.

## Sample code to query

### Add to Bridging Header
```objc
#import <CommonCrypto/CommonHMAC.h>
```

### Instantiating this class
```swift
  var kuggle = KuggleAPI.sharedInstance
```

### Registration using facebook
#### Parameters
* 'fbtoken' - This is the token returned from the *OAUTH Dance* from the application. This endpoint will validate the users profile and decide whether or not to create it.

#### Expected Response
* 'fromfb' - This is what the app has pulled from facebook. Which contains a 'birthday' (Javascript Date format), 'birthdaystring' (format which you can actually serialize back into a javascript date object), 'firstname', 'gender' (0 = female, 1 = male, 2 = other or undisclosed), 'id' (the users facebook ID)
* 'token' - This is the login token that you need to use on protected endpoints. For convenience purposes, this class will also save it automatically to the keychain under the value 'token' (eventually may even automatically include it). Only returned if registration was successful. Check NSError and display error.domain to user (this response is localized if you're using this API)

#### Other things to note
* Profile is automatically created. No need to call the create profile endpoint.
* Handle errors. Sometimes bad things happen, server room catches fire, etc etc. Also successful facebook authorization doesn't guarantee that the account gets created (just like being on the guestlist of a popular nightclub doesn't actually guarantee you entry). There's a few behind the scene checks on your account details (whether or not you actually authorized the right things, etc)

```swift
        k.postRequest("register", token: nil, params: ["fbtoken": "tokengoeshere"], postRequestCompletionHandler: {json,err -> Void in
            if (err == nil) {
                let meta = (json as! NSDictionary)["meta"] as! NSDictionary
                let metaCode = meta.objectForKey("code") as! NSInteger
                let metaMsg = meta.objectForKey("msg") as! String
                println(metaCode)
                println(metaMsg)
                println(json)
                dispatch_async(dispatch_get_main_queue(),{
                  self.performSegueWithIdentifier("loggedin", sender: self)
                })                
            } else {
                if let error : NSError = err as NSError!
                {
                    println(error.code)
                    println(error.domain)
                  dispatch_async(dispatch_get_main_queue(),{
                    // Do some error thing
                  })
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

This functionality, returns the 'meta' key, as well as 'token' if successfully validated. For convenience purposes, this class will also save the token automatically to the keychain under the value 'token' (eventually may even automatically include it).

```swift
  kuggle.postRequest("register", token: nil, params: ["phonenumber": "+11234567", "pin": "12345"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      let meta = (json as! NSDictionary)["meta"] as! NSDictionary
      let metaCode = meta.objectForKey("code") as! NSInteger
      let metaMsg = meta.objectForKey("msg") as! String
      println(metaCode)
      println(metaMsg)
      println(json)
      dispatch_async(dispatch_get_main_queue(),{
        self.performSegueWithIdentifier("pinview", sender: self)
      })      
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
      let profilecreated = (json as! NSDictionary)["profilecreated"] as! Bool
      if (profilecreated == true) {
        let profile: NSDictionary = (json as! NSDictionary)["profile"] as! NSDictionary
        dispatch_async(dispatch_get_main_queue(),{
          self.performSegueWithIdentifier("loggedin", sender: self)
        })      
      } else {
        dispatch_async(dispatch_get_main_queue(),{
          self.performSegueWithIdentifier("setupprofile", sender: self)
        })  
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
          dispatch_async(dispatch_get_main_queue(),{
            self.performSegueWithIdentifier("profilecreated", sender: self)
          })          
      }
    } else {
      if let error : NSError = err as NSError!
        {
          println(error.code)
          println(error.domain)
          // Not created
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

### Purpose

This is the API to create a purpose

Either returns success or fail (in status codes)

#### Create Purpose 

**Input Parameters**
* 'purpose': This is a 120 character or less string
* 'lat' or 'lng': This is for tagging the purpose to a location if a place is not used.
* 'placeid': This is for tagging the purpose to a place. A list of places can be found from the nearby/places endpoint.
* 'type': This is for specifying the purpose type. Either 'goal', 'help', or 'give'


```swift
  k.postRequest("purpose", token: "Token", params: ["purpose": "Need Help with studies!", "lat": "22.283580", "lng": "114.135281", "type": "help"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
        // Purpose created successfully!
      }
    } else {
      if let error : NSError = err as NSError!
        {
          println(error.code)
          println(error.domain)
          // An error has occured, show error message on the screen (error.domain)
        }
    }

  })
```

#### Like Purpose

* This is the endpoint to like a purpose. It is a POST request with no body against purpose/PURPOSEID/like
* PURPOSEID can be shown from nearby/people
* Once you like a purpose, you can't dislike the purpose

```swift
  k.postRequest("purpose/purposeid/like", token: "Token", params: nil, postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
        // Purpose liked successfully
      }
    } else {
      if let error : NSError = err as NSError!
        {
          println(error.code)
          println(error.domain)
          // An error has occured, show error message on the screen (error.domain)
        }
    }

  })
```

#### DisLike Purpose

* This is the endpoint to dislike a purpose. It is a POST request with no body against purpose/PURPOSEID/dislike
* PURPOSEID can be shown from nearby/people
* Once you dislike a purpose, you can't like the purpose

```swift
  k.postRequest("purpose/purposeid/dislike", token: "Token", params: nil, postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
        // Purpose disliked successfully!
      }
    } else {
      if let error : NSError = err as NSError!
        {
          println(error.code)
          println(error.domain)
          // An error has occured, show error message on the screen (error.domain)
        }
    }

  })
```
#### Get last purposes

Shows the last purposes that was set by the user

```swift
  k.getRequest("purpose", token: "USERTOKEN", params: nil, getRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
        // Show the last purposes as a 'purposes' key
      }
    } else {
      if let error : NSError = err as NSError! {
        println(error.code)
        println(error.domain) // Message returned. This is localized automatically

      }
    }
  })
```

### Nearby People / Places

**Parameters**
* 'lat' or 'lng': This is where the person searching is
* 'distance': Optional. This is the distance radius for the search in meters. Defaults at 5000 if not specified.

#### Nearby People
```swift
  k.getRequest("nearby/people", token: "USERTOKEN", params: ["lat": "22.283580", "lng": "114.135281"], getRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
      // Success
      // There should be a key called 'people' which is the list
      }
    } else {
      if let error : NSError = err as NSError! {
        println(error.code)
        println(error.domain)
        // Error
      }
    }
  })
```

#### Nearby Places
```swift
  k.getRequest("nearby/places", token: "USERTOKEN", params: ["lat": "22.283580", "lng": "114.135281"], getRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      if let jsonResp : NSDictionary = json as? NSDictionary {
      // Success
      // There should be a key called 'places' which is the list
      }
    } else {
      if let error : NSError = err as NSError! {
        println(error.code)
        println(error.domain)
        // Error
      }
    }
  })
```
