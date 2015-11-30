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

@property (nonatomic) NSDictionary <NSString *, NSString *>*headers;

@property (nonatomic) BOOL allowsCellularAccess; // default NO;
@property (nonatomic, readonly) NSString *sessionConfigurationIdentifier;
@property (nonatomic, readonly) NSURLSession *session;
@property (nonatomic, readonly) NSProgress *progress;
@property (nonatomic, weak) id <TMBackgroundTransferDelegate> delegate;

+ (TMBackgroundTransfer *)sharedTransfer;

/**
 SessionのID
 Override method
 */
- (NSString *)sessionConfigurationIdentifier;

/**
 Requestのクエリキー
 Override method
 */
- (NSString *)transferIdentifierKey;

/**
 Documents directoryに作られるtmp directoryの名前
 Override method
 */
- (NSString *)backgroundTmpDirectoryName;

/**
 データをバックグランドで転送
 @return アップロードタスク
 @param URL 転送先のURL
 @param data 転送するデータ
 @param error エラー
 */
- (NSURLSessionUploadTask *)uploadTaskWithURL:(NSURL *)url data:(NSData *)data hash:(NSString *)hash error:(NSError *__autoreleasing *)error;

/**
 データをバックグランドで転送
 @return アップロードタスク
 @param URL 転送先のURL
 @param data 転送するデータ
 @param params 転送先URLに付随するQuery
 @param error エラー
 */
- (NSURLSessionUploadTask *)uploadTaskWithURL:(NSURL *)url data:(NSData *)data hash:(NSString *)hash params:(NSDictionary <NSString *, NSString *>*)params error:(NSError *__autoreleasing *)error;


- (BOOL)cancelWithTask:(NSURLSessionUploadTask *)task error:(NSError *__autoreleasing *)error;

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