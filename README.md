# TMBackgroundTransfer

## Usage
``` objective-c

NSString *hash = [imageData MD5HexDigest];
NSURL *url = [NSURL URLWithString:@"http://localhost:3000/media/upload"];
NSError *error = nil;
[[TMBackgroundTransfer sharedTransfer] uploadTaskWithURL:url data:imageData hash:hash error:&error];

```
