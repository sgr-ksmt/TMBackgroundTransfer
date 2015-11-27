//
//  NSData+MD5.m
//  Famm
//
//  Created by 1amageek on 2015/11/25.
//  Copyright © 2015年 Timers. All rights reserved.
//

#import "NSData+MD5.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (MD5)

- (NSString *)MD5HexDigest
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([self bytes], (unsigned int)[self length], result);
    NSString *hash = [NSString stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    return hash;
}

@end
