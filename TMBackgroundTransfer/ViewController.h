//
//  ViewController.h
//  STPBackgroundTransfer
//
//  Created by 1amageek on 2015/11/19.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBackgroundTransfer.h"
#import "NSIndexSet+Convenience.h"
#import "UICollectionView+Convenience.h"
#import "GridCell.h"
#import "NSData+MD5.h"

@import Photos;
@import PhotosUI;

@interface ViewController : UIViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) PHFetchResult *assetsFetchResults;
@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic) UICollectionView *collectionView;

+ (void)loadAssetsLibraryWithComplitionHandler:(void (^)(BOOL authorized))complition;

@end

