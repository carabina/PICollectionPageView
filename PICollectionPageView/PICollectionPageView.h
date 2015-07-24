//
//  PICollectionPageView.h
//  NewPiki
//
//  Created by Pham Quy on 7/13/15.
//  Copyright (c) 2015 Pikicast Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PICollectionPageView;
@protocol PICollectionPageViewDelegate <UICollectionViewDelegateFlowLayout>
@optional
- (void) pageViewCurrentIndexDidChanged:(PICollectionPageView *) pageView;
- (void) pageView:(PICollectionPageView *) pageView willDisplayPageAtIndex:(NSInteger) index; // NOT SUPPORTED YET
- (void) pageView:(PICollectionPageView *) pageView completeDisplayPageAtIndex:(NSInteger) index;
- (void) pageView:(PICollectionPageView *) pageView displayPageAtIndex:(NSInteger) index percentage:(CGFloat) percentage; // NOT SUPPORTED YET
@end

@protocol PICollectionPageViewDataSource <UICollectionViewDataSource>
@required
- (NSInteger) numberOfPageInPageView:(PICollectionPageView *) pageView;
@optional
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
@end

@interface PICollectionPageView : UICollectionView

@property (nonatomic, weak) id<PICollectionPageViewDelegate> delegate;
@property (nonatomic, weak) id<PICollectionPageViewDataSource> dataSource;
@property (nonatomic, readonly) NSInteger numberOfPages;
@property (nonatomic) NSInteger currentPageIndex;

- (void) scrollToPageAtIndex:(NSInteger)currentIndex animated:(BOOL) animated;
- (void) scrollByNumberOfPages:(NSInteger)count animated:(BOOL) animated;
- (void) scrollByPageOffset:(CGFloat) pageOffset animated:(BOOL) animated;
- (void) scrollByOffset:(CGFloat) scrollOffset animated:(BOOL) animated;
@end
