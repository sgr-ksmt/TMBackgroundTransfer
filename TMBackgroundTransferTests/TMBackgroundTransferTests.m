//
//  TMBackgroundTransferTests.m
//  TMBackgroundTransferTests
//
//  Created by 1amageek on 2015/11/27.
//  Copyright © 2015年 Timers inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Photos;
@import PhotosUI;

#import "NSData+MD5.h"
#import "TMBackgroundTransfer.h"

@interface TMBackgroundTransferTests : XCTestCase <TMBackgroundTransferDelegate>

@property (nonatomic) PHFetchResult *assetsFetchResults;
@property (nonatomic) NSMutableArray *responses;

@end

@implementation TMBackgroundTransferTests
{
    NSUInteger *uploadCount;
    NSUInteger *completedCount;
    XCTestExpectation *_expectation;
}


- (void)setUp {
    [super setUp];
    
    uploadCount = 0;
    completedCount = 0;
    self.responses = [NSMutableArray array];
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                     subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                     options:nil];
    PHAssetCollection *assetCollection = result.firstObject;
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    self.assetsFetchResults = assetsFetchResult;
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUpload {
    
    _expectation = [self expectationWithDescription:@"Session is connected."];
    
    [self.assetsFetchResults enumerateObjectsUsingBlock:^(PHAsset *  _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            NSString *hash = [imageData MD5HexDigest];
            NSURL *url = [NSURL URLWithString:@"http://localhost:3000/media/upload"];
            NSError *error = nil;
            [[TMBackgroundTransfer sharedTransfer] setDelegate:self];
            [[TMBackgroundTransfer sharedTransfer] uploadTaskWithURL:url data:imageData hash:hash error:&error];
            uploadCount ++ ;
        }];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {

        for (NSHTTPURLResponse *response in self.responses) {
            XCTAssertEqual(response.statusCode, 200);

        }
        
        NSString *tmpDirectoryName = [[TMBackgroundTransfer sharedTransfer] backgroundTmpDirectoryName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsDirectory = [URLs objectAtIndex:0];
        NSURL *tmpDirectory = [documentsDirectory URLByAppendingPathComponent:tmpDirectoryName isDirectory:YES];
    
        NSArray *files = [fileManager contentsOfDirectoryAtURL:tmpDirectory includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        
        XCTAssertEqual(files.count, 0);
        XCTAssertEqual(completedCount, uploadCount);
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
    
}

#pragma mark - delegate

- (void)backgroundTransfer:(TMBackgroundTransfer *)backgroundTransfer session:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    
}

- (void)backgroundTransfer:(TMBackgroundTransfer *)backgroundTransfer session:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    completedCount ++ ;
    [self.responses addObject:(NSHTTPURLResponse *)task.response];
    if (completedCount == uploadCount) {
        [_expectation fulfill];
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
