# Kuggle API Swift class
Class to interface with the Kuggle backend

This is a work in progress.

## Sample code to query

### Instantiating
```swift
  var kuggle = KuggleAPI.sharedInstance
```

### Registration by Phone Number

* replace '+11234567' with a phone number thats valid.

```swift
  kuggle.postRequest("test", token: "none", params: ["phonenumber": "+11234567"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      let meta = (json as! NSDictionary)["meta"] as! NSDictionary
      let metaCode = meta.objectForKey("code") as! NSInteger
      let metaMsg = meta.objectForKey("msg") as! String
      println(metaCode)
      println(metaMsg)
      println(json)
    } else {
      println(err)
    }
  })
```

### Verify PIN

* replace '+11234567' with a phone number thats valid.
* replace '12345' with a PIN thats valid

```swift
  kuggle.postRequest("test", token: "none", params: ["phonenumber": "+11234567", "pin": "12345"], postRequestCompletionHandler: {json,err -> Void in
    if (err == nil) {
      let meta = (json as! NSDictionary)["meta"] as! NSDictionary
      let metaCode = meta.objectForKey("code") as! NSInteger
      let metaMsg = meta.objectForKey("msg") as! String
      println(metaCode)
      println(metaMsg)
      println(json)
    } else {
      println(err)
    }
  })
```

### Coming soon

Here is a sneak preview of what to expect.

* Getting and user profiles
