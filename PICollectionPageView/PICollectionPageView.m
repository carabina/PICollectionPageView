//
//  PICollectionPageView.m
//  NewPiki
//
//  Created by Pham Quy on 7/13/15.
//  Copyright (c) 2015 Pikicast Inc. All rights reserved.
//

#import "PICollectionPageView.h"
#import <objc/runtime.h>


//------------------------------------------------------------------------------
@interface NSObject (Swizzling)
+ (void) swizzleInstanceSelector:(SEL)originalSelector
                 withNewSelector:(SEL)newSelector;
@end

//------------------------------------------------------------------------------


@implementation NSObject (Swizzling)
+ (void) swizzleInstanceSelector:(SEL)originalSelector
                 withNewSelector:(SEL)newSelector
{
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method newMethod = class_getInstanceMethod(self, newSelector);

    BOOL methodAdded = class_addMethod([self class],
                                       originalSelector,
                                       method_getImplementation(newMethod),
                                       method_getTypeEncoding(newMethod));

    if (methodAdded) {
        class_replaceMethod([self class],
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}
@end

//------------------------------------------------------------------------------
#pragma mark - Collection View Proxy
static BOOL _isInterceptedSelector(SEL sel)
{
    return (

            // Intercept the UICollectionViewDelegateFlowLayout
            sel == @selector(collectionView:layout:sizeForItemAtIndexPath:) ||
            sel == @selector(collectionView:layout:insetForSectionAtIndex:) ||
            sel == @selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:) ||
            sel == @selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:) ||
            sel == @selector(collectionView:layout:referenceSizeForFooterInSection:) ||
            sel == @selector(collectionView:layout:referenceSizeForHeaderInSection:) ||

            // Intercept data source
            sel == @selector(collectionView:numberOfItemsInSection:) ||
            sel == @selector(numberOfSectionsInCollectionView:) ||
            sel == @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)
            );
}


typedef id<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource> PICollectionPageViewInterceptor;
//------------------------------------------------------------------------------
@interface _PICollectionPageViewProxy : NSProxy
- (instancetype)initWithTarget:(id<NSObject>)target interceptor:(PICollectionPageViewInterceptor)interceptor;

@end



//------------------------------------------------------------------------------
@implementation _PICollectionPageViewProxy {
    id<NSObject> __weak _target;
    PICollectionPageViewInterceptor __weak _interceptor;
}

- (instancetype)initWithTarget:(id<NSObject>)target
                   interceptor:(PICollectionPageViewInterceptor)interceptor
{
    // -[NSProxy init] is undefined
    if (!self) {
        return nil;
    }

    NSAssert(target, @"target must not be nil");
    NSAssert(interceptor, @"interceptor must not be nil");

    _target = target;
    _interceptor = interceptor;

    return self;
}

//------------------------------------------------------------------------------
- (BOOL)respondsToSelector:(SEL)aSelector
{
    return (_isInterceptedSelector(aSelector) || [_target respondsToSelector:aSelector]);
}

//------------------------------------------------------------------------------
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (_isInterceptedSelector(aSelector)) {
        return _interceptor;
    }

    return [_target respondsToSelector:aSelector] ? _target : nil;
}

@end





//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


#pragma mark - PICollectionPageView Impelementation


@interface PICollectionPageView ()
<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    _PICollectionPageViewProxy* _proxyDataSource;
    _PICollectionPageViewProxy* _proxyDelegate;
    id<PICollectionPageViewDelegate> __weak _externalDelegate;
    id<PICollectionPageViewDataSource> __weak _externalDatasource;
}

@end

//------------------------------------------------------------------------------
@implementation PICollectionPageView
@dynamic delegate;
@dynamic dataSource;
@synthesize currentPageIndex=_currentPageIndex;

- (instancetype) initWithFrame:(CGRect)frame {
    UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    layout.headerReferenceSize = CGSizeZero;
    layout.footerReferenceSize = CGSizeZero;
    layout.sectionInset = UIEdgeInsetsZero;

    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

//------------------------------------------------------------------------------
- (instancetype) initWithFrame:(CGRect)frame
          collectionViewLayout:(UICollectionViewLayout *)inputLayout
{
    NSLog(@"Input layout will be ignored, alway using UICollectionViewLayout instead");
    UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    layout.headerReferenceSize = CGSizeZero;
    layout.footerReferenceSize = CGSizeZero;
    layout.sectionInset = UIEdgeInsetsZero;

    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

//------------------------------------------------------------------------------
- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self= [super initWithCoder:aDecoder];
    NSAssert([self.collectionViewLayout isKindOfClass:UICollectionViewFlowLayout.class], @"only flow layouts are currently supported");

    if (self) {
        [self setup];
    }
    return self;
}

//------------------------------------------------------------------------------
- (void) dealloc{
    [self removeObserver:self forKeyPath:@"contentOffset"];
//    [self removeObserver:self forKeyPath:@"currentPageIndex"];
}
//------------------------------------------------------------------------------
- (void) setup
{
    [self addObserver:self forKeyPath:@"contentOffset" options:(NSKeyValueObservingOptionNew) context:nil];
//    [self addObserver:self forKeyPath:@"currentPageIndex" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
}


- (void) setCurrentPageIndex:(NSInteger)currentPageIndex
{
    if (_currentPageIndex != currentPageIndex) {

        NSLog(@"CHANGE FROM %@ TO %@", @(_currentPageIndex), @(currentPageIndex));
        _currentPageIndex = currentPageIndex;
        [self.delegate pageViewCurrentIndexDidChanged:self];

    }
}
//------------------------------------------------------------------------------
- (NSInteger) numberOfPages
{
    return [self numberOfItemsInSection:0];
}

//------------------------------------------------------------------------------
- (CGFloat) pageSize
{
    return ([(UICollectionViewFlowLayout*)self.collectionViewLayout scrollDirection] ==  UICollectionViewScrollDirectionHorizontal ? self.bounds.size.width : self.bounds.size.height);
}
//------------------------------------------------------------------------------
- (CGFloat) scrollOffset
{
    return ([(UICollectionViewFlowLayout*)self.collectionViewLayout scrollDirection] ==  UICollectionViewScrollDirectionHorizontal ? self.contentOffset.x : self.contentOffset.y);
}
//------------------------------------------------------------------------------
#pragma mark - Page indexing and scrolling
- (void) scrollByOffset:(CGFloat) scrollOffset animated:(BOOL) animated
{
    CGPoint currentOffset = self.contentOffset;
    CGFloat currentScrollOffset;
    if ([(UICollectionViewFlowLayout*)self.collectionViewLayout scrollDirection] ==  UICollectionViewScrollDirectionHorizontal) {
        currentOffset.x = MIN(MAX(0, currentOffset.x + scrollOffset), self.contentSize.width - self.bounds.size.width);
        currentScrollOffset = currentOffset.x;
    }else{
        currentOffset.y = MIN(MAX(0, currentOffset.y + scrollOffset), self.contentSize.height - self.bounds.size.height);
        currentScrollOffset  = currentOffset.y;
    }

    CGFloat pageOffset = currentScrollOffset / [self pageSize];
    NSInteger pageIdx =  floor(pageOffset + 0.5);
    pageIdx = MIN(MAX(pageIdx,0), [self numberOfPages]-1);

    [self setCurrentPageIndex:pageIdx];
    [self setContentOffset:currentOffset animated:animated];
}

//------------------------------------------------------------------------------
- (void) scrollByPageOffset:(CGFloat) pageOffset animated:(BOOL) animated
{
    CGFloat scrollOffsetChange = pageOffset * [self pageSize];
    [self scrollByOffset:scrollOffsetChange animated:animated];

}
//------------------------------------------------------------------------------
- (void) scrollByNumberOfPages:(NSInteger)count animated:(BOOL) animated
{

    NSInteger gotoPage = MIN(MAX(self.currentPageIndex + count, 0), [self numberOfPages]-1);
    [self scrollToPageAtIndex:gotoPage animated:animated];
}
//------------------------------------------------------------------------------
- (void) scrollToPageAtIndex:(NSInteger)currentPageIndex animated:(BOOL) animated
{

    NSLog(@"Scroll from %@ to %@", @(self.currentPageIndex), @(currentPageIndex));
    [self setCurrentPageIndex:currentPageIndex];
    [self
     scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentPageIndex inSection:0]
     atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically)
     animated:animated];
}


//------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"contentOffset"] && (object == self)) {
        CGPoint newOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGFloat scrollOffset  = ([(UICollectionViewFlowLayout*)self.collectionViewLayout scrollDirection] ==  UICollectionViewScrollDirectionHorizontal ? newOffset.x : newOffset.y);

        CGFloat pageSize = [self pageSize];
        scrollOffset = scrollOffset < 0. ? 0. : scrollOffset;

        NSInteger pageIdx;
        if (scrollOffset == 0 || pageSize == 0) {
            pageIdx = 0;
        }else{
            CGFloat pageOffset = scrollOffset / pageSize;
            pageIdx =  floor(pageOffset + 0.5);
            pageIdx = MIN(MAX(0,pageIdx), [self numberOfPages]-1);
        }


        if ((pageIdx != _currentPageIndex) && (self.isDragging || self.isDecelerating) ) {
            [self setCurrentPageIndex:pageIdx];
        }


        // If exact page offset
        if (fabs(scrollOffset - (pageIdx * [self pageSize])) < FLT_EPSILON) {
            if ([self.delegate respondsToSelector:@selector(pageView:completeDisplayPageAtIndex:)]) {
                [self.delegate pageView:self completeDisplayPageAtIndex:pageIdx];
            }
        }
    }


    if ([keyPath isEqualToString:@"currentPageIndex"] && (object == self)) {
        NSInteger newIdx = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        NSInteger oldIdx = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];

        if ((newIdx != oldIdx) && [self.delegate respondsToSelector:@selector(pageViewCurrentIndexDidChanged:)]) {
            NSLog(@"CHANGE FROM %@ TO %@", @(oldIdx), @(newIdx));
            [self.delegate pageViewCurrentIndexDidChanged:self];
        }
    }
}

//------------------------------------------------------------------------------
#pragma mark - Override Delegate and Datasource


- (void) setDataSource:(id<PICollectionPageViewDataSource> __nullable)dataSource
{
    if (dataSource == _externalDatasource) {
        return;
    }

    if (dataSource == nil) {
        _externalDatasource = nil;
        _proxyDataSource = nil;
        super.dataSource = nil;
    }else{
        _externalDatasource = dataSource;
        _proxyDataSource = [[_PICollectionPageViewProxy alloc] initWithTarget:_externalDatasource interceptor:self];
        super.dataSource = (id<UICollectionViewDataSource>)_proxyDataSource;
    }
}
//------------------------------------------------------------------------------
- (void) setDelegate:(id<PICollectionPageViewDelegate>)delegate
{
    if (delegate == _externalDelegate) {
        return;
    }

    if (delegate == nil) {
        _externalDelegate = nil;
        _proxyDelegate = nil;
        [super setDelegate:nil];
    }else{
        _externalDelegate = delegate;
        _proxyDelegate = [[_PICollectionPageViewProxy alloc] initWithTarget:_externalDelegate interceptor:self];
        super.delegate = (id<UICollectionViewDelegateFlowLayout>)_proxyDelegate;
    }
}


//------------------------------------------------------------------------------
#pragma mark - Intercepted Selectors

//------------------------------------------------------------------------------
// Flow layout settup
//------------------------------------------------------------------------------
- (CGSize) collectionView:(nonnull UICollectionView *)collectionView
                   layout:(nonnull UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return self.bounds.size;
}
//------------------------------------------------------------------------------
- (UIEdgeInsets) collectionView:(nonnull UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

//------------------------------------------------------------------------------
- (CGFloat) collectionView:(nonnull UICollectionView *)collectionView
                    layout:(nonnull UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

//------------------------------------------------------------------------------ 
- (CGFloat) collectionView:(nonnull UICollectionView *)collectionView
                    layout:(nonnull UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

//------------------------------------------------------------------------------
- (CGSize) collectionView:(nonnull UICollectionView *)collectionView
                   layout:(nonnull UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeZero;
}

//------------------------------------------------------------------------------
- (CGSize) collectionView:(nonnull UICollectionView *)collectionView
                   layout:(nonnull UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

//------------------------------------------------------------------------------
// Intercept data source
//------------------------------------------------------------------------------

- (NSInteger) collectionView:(nonnull UICollectionView *)collectionView
      numberOfItemsInSection:(NSInteger)section
{
    NSAssert([_externalDatasource respondsToSelector:@selector(numberOfPageInPageView:)], @"Required methods is not implemented");
    return [_externalDatasource numberOfPageInPageView:self];

}

- (NSInteger) numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionReusableView*) collectionView:(nonnull UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(nonnull NSString *)kind
                                 atIndexPath:(nonnull NSIndexPath *)indexPath
{
    return nil;
}

@end
