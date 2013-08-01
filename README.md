NSObject+ObjectIO
=============

This is a drop-in category of NSObject that allows saving and loading of your objects. This uses the [NSObject+ObjectMap](https://github.com/uacaps/NSObject-ObjectMap) base category and extends it further. AES256 encryption/decryption is included in this class as well for optionally securing your NSObjects when you save and load them.

![screenshot](https://raw.github.com/uacaps/NSObject-ObjectIO/master/Screenshots/screen-01.png)

--------------------

## Set Up ##

Drag the included <code>NSObject+ObjectIO.{h,m}</code> classes into your project, and #import them into the classes you want to use them in.

Link to Frameworks:

* Security
* CommonCrypto

--------------------

## Saving your NSObjects ##

Saving your NSObjects to disk can be very useful depending on the context of your application. This function works on both iOS and OSX to maintain your NSObjects and their properties at the time of save. To save an NSObject to disk, use the <code>-(void)saveToUrl:completion:</code> method.

**Considerations:**
* Reduced File Size: this maps the properties (value) of your NSObject to a single character key. Graphs on the reduction of file size can be seen below.
* Encryption: to encrypt your data with state-of-the-art AES256 encryption, pass in a password for the encryptionString parameter, and a generated salt for saltString.

*Note on salts:* Salting a password is considered good practice for contemporary cryptography. This adds another layer of security to the password entered, where if an attacker knows your password, they still need additional information to get to the actual meat of the data. PBKDF2 is used for the key derivation funtion, which supports key stretching for added security. We use a method called by <code>[NSMutableData generateSalt]</code> that generates a random ASCII string salt to be used for the encryption/decryption. As this returns an NSString, you should store this salt somewhere where it can be retrieved and used, rather than in plaintext in your projects. Common methods today include private configuration files or through database queries. **Make sure to save this salt as it will be critical to have to decrypt your files and parse them back in to NSObjects!**

Here's some sample code for generating a salt, and saving your files to the Desktop.

```objc
NSString *salt = [NSMutableData generateSalt];
    
NSString *fileName = @"Filename.extension";
    
//Save document
[MyObject saveToDocumentsDirectoryWithName:fileName reducedFileSize:YES password:@"Password" salt:salt completion:^(NSError *error) {
	if(!error){
        	//Success
        }
        else {
        	//Fail
        }
}];
```

--------------------

## Loading your NSObjects ##

Loading your NSObjects back from disk is just as easy as saving. Just use the <code>-(id)objectFromURL:password:salt:</code> method. The only consideration to using this is to make sure that you alloc and init your NSObject before calling this. *If you encrypted the file, then hopefully you saved that salt somewhere safe.* An example of using this is like so:

```objc
__block MyNSObject *newObject = [[MyNSObject alloc] init];
					        	
[newObject loadFromDocumentsDirectoryWithName:fileName password:@"Password" salt:salt completion:^(id object, NSError *error) {
	if(!error){
		//Assign object
		newObject = (MyObject *)object;
        }
        else {
		//Fail
        }
}];
```

--------------------

## For the Future ##

We added some security heavy features with regards to encryption/decryption - but as standards and best practices change, it would be fortuitious to stay on top of those areas. So, don't feel unsure if you want to add a pull-request or open an Issue to discuss the encryption methods to make sure they are cryptographically top-notch.
