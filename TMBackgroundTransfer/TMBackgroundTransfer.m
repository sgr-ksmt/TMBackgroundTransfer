//
//  TMBackgroundTransfer.m
//  TMBackgroundTransfer
//
//  Created by 1amageek on 2015/11/27.
//  Copyright © 2015年 Timers inc. All rights reserved.
//

#import "TMBackgroundTransfer.h"

@implementation NSURL (Query)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString], [self query] ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

- (NSDictionary *)parseQuery
{
    NSString *query = self.query;
    NSArray *params = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *param in params) {
        NSArray *elements = [param componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByRemovingPercentEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByRemovingPercentEncoding];
        [dict setObject:val forKey:key];
    }
    return dict;
}

@end

@interface TMBackgroundTransfer ()

@end


@implementation TMBackgroundTransfer

static NSString  *_sessionConfigurationIdentifier;

+ (TMBackgroundTransfer *)sharedTransfer
{
    static TMBackgroundTransfer *sharedTransfer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTransfer = [TMBackgroundTransfer new];
    });
    return sharedTransfer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _progress = [NSProgress progressWithTotalUnitCount:100];
        _allowsCellularAccess = NO;
        _sessionConfigurationIdentifier = [self sessionConfigurationIdentifier];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_sessionConfigurationIdentifier];
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self delegateQueue:nil];
    }
    return self;
}

- (NSString *)sessionConfigurationIdentifier
{
    return @"com.timers-inc.background.transfer";
}

- (NSString *)transferIdentifierKey
{
    return @"name";
}

- (NSString *)backgroundTmpDirectoryName
{
    return @"background_tmp";
}

#pragma mark - private method

- (void)removeFileAtTask:(NSURLSessionTask *)task
{
    NSDictionary *dict = [task.originalRequest.URL parseQuery];
    NSString *transferKey = [self transferIdentifierKey];
    NSString *hash = [dict objectForKey:transferKey];
    [self removeFileAtHash:hash];
}

- (void)removeFileAtHash:(NSString *)hash
{
    NSString *tmpDirectoryName = [self backgroundTmpDirectoryName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];
    NSURL *tmpDirectory = [documentsDirectory URLByAppendingPathComponent:tmpDirectoryName isDirectory:YES];
    NSURL *removeURL = [tmpDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", hash]];
    
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:[removeURL path]]) {
        if (![fileManager removeItemAtURL:removeURL error:&error]) {
            if (error) {
                NSLog(@"[remove uploaded file] %@", error);
            }
        }
    }
}

#pragma mark - 

- (NSURLSessionUploadTask *)uploadTaskWithURL:(NSURL *)url data:(NSData *)data hash:(NSString *)hash error:(NSError *__autoreleasing *)error
{
    return [self uploadTaskWithURL:url data:data hash:hash params:nil error:error];
}

- (NSURLSessionUploadTask *)uploadTaskWithURL:(NSURL *)url data:(NSData *)data hash:(NSString *)hash params:(NSDictionary <NSString *, NSString *>*)params error:(NSError *__autoreleasing *)error
{
    NSString *tmpDirectoryName = [self backgroundTmpDirectoryName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];
    
    // create tmp dir
    NSURL *tmpDirectory = [documentsDirectory URLByAppendingPathComponent:tmpDirectoryName isDirectory:YES];
    if (![fileManager fileExistsAtPath:[tmpDirectory path]]) {
        if (![fileManager createDirectoryAtURL:tmpDirectory withIntermediateDirectories:YES attributes:nil error:error]) {
            if (error) {
                NSLog(@"[create tmp dir] %@", *error);
                return nil;
            }
        };
    }
    
    // create upload file
    NSURL *saveURL = [tmpDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", hash]];
    if (![data writeToURL:saveURL options:NSDataWritingAtomic error:error]) {
        if (error) {
            NSLog(@"[create upload file] %@", *error);
            return nil;
        }
    }
    NSString *transferKey = [self transferIdentifierKey];
   
    __block NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@=%@", [url absoluteString], transferKey, hash] relativeToURL:url];
    if (params) {
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *param = [NSString stringWithFormat:@"%@=%@", key, obj];
            requestURL = [requestURL URLByAppendingQueryString:param];
        }];
    }
 
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    request.HTTPMethod = @"POST";
    request.allowsCellularAccess = self.allowsCellularAccess;
    
    if (self.headers) {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    NSURLSessionUploadTask *task = [self.session uploadTaskWithRequest:request fromFile:saveURL];
    [task resume];

    return task;
}

- (BOOL)cancelWithTask:(NSURLSessionUploadTask *)task error:(NSError *__autoreleasing *)error
{
    if (!task) {
        return NO;
    }
    return YES;
}



#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    //float progress = (float)totalBytesSent / totalBytesExpectedToSend;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(backgroundTransfer:session:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
            [self.delegate backgroundTransfer:self session:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesExpectedToSend totalBytesExpectedToSend:totalBytesExpectedToSend];
        }
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ([session.configuration.identifier isEqualToString:[self sessionConfigurationIdentifier]]) {
        if (error) {
            if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                switch ([error code]) {
                    case NSURLErrorCancelled: {
                        
                        NSDictionary *userInfo = error.userInfo;
                        NSURL *url = [userInfo objectForKey:NSURLErrorFailingURLErrorKey];
                        NSDictionary *dict = [url parseQuery];
                        NSString *transferKey = [self transferIdentifierKey];
                        NSString *hash = [dict objectForKey:transferKey];
                        [self removeFileAtHash:hash];
                        
                    }
                        break;
                        
                    default:
                        break;
                }
            }
            
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(backgroundTransfer:session:task:didCompleteWithError:)]) {
                    [self.delegate backgroundTransfer:self session:session task:task didCompleteWithError:error];
                }
            }
            return;
        }
        
        // complete
        [self removeFileAtTask:task];
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(backgroundTransfer:session:task:didCompleteWithError:)]) {
                [self.delegate backgroundTransfer:self session:session task:task didCompleteWithError:error];
            }
        }
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
}


@end
