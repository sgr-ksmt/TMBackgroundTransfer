//
//  TMBackgroundTransfer.h
//  TMBackgroundTransfer
//
//  Created by 1amageek on 2015/11/27.
//  Copyright © 2015年 Timers inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TMBackgroundTransferDelegate;
@interface TMBackgroundTransfer : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic) NSDictionary *headers;

@property (nonatomic) BOOL allowsCellularAccess; // default NO;
@property (nonatomic) NSString *sessionConfigurationIdentifier;
@property (nonatomic, readonly) NSURLSession *session;
@property (nonatomic, readonly) NSProgress *progress;
@property (nonatomic, weak) id <TMBackgroundTransferDelegate> delegate;

+ (TMBackgroundTransfer *)sharedTransfer;

- (NSString *)sessionConfigurationIdentifier;
- (NSString *)transferIdentifierKey;
- (NSString *)backgroundTmpDirectoryName;

/**
 データをバックグランドで転送
 @return アップロードタスク
 @param URL 転送先のURL
 @param data 転送するデータ
 @param error エラー
 */
- (NSURLSessionUploadTask *)uploadTaskWithURL:(NSURL *)url data:(NSData *)data hash:(NSString *)hash error:(NSError *__autoreleasing *)error;

@end


@protocol TMBackgroundTransferDelegate <NSObject>

- (void)backgroundTransfer:(TMBackgroundTransfer *)backgroundTransfer
                   session:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
           didSendBodyData:(int64_t)bytesSent
            totalBytesSent:(int64_t)totalBytesSent
  totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

- (void)backgroundTransfer:(TMBackgroundTransfer *)backgroundTransfer
                   session:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
      didCompleteWithError:(NSError *)error;

@end