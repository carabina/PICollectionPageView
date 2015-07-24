//
//  ViewController.m
//  PICollectionPageViewExample
//
//  Created by Pham Quy on 7/24/15.
//  Copyright (c) 2015 Jkorp. All rights reserved.
//

#import "ViewController.h"
#import <PICollectionPageView/PICollectionPageView.h>

@interface ViewController ()<PICollectionPageViewDataSource, PICollectionPageViewDelegate>
@property (weak, nonatomic) IBOutlet PICollectionPageView *pageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.pageView setPagingEnabled:YES];
    [(UICollectionViewFlowLayout*)self.pageView.collectionViewLayout setScrollDirection:(UICollectionViewScrollDirectionHorizontal)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeDirection:(id)sender {
    if(([(UISegmentedControl*)sender selectedSegmentIndex] == 0) || ([(UISegmentedControl*)sender selectedSegmentIndex]==UISegmentedControlNoSegment))
    {
        [(UICollectionViewFlowLayout*)self.pageView.collectionViewLayout setScrollDirection:(UICollectionViewScrollDirectionHorizontal)];
    }else{
        [(UICollectionViewFlowLayout*)self.pageView.collectionViewLayout setScrollDirection:(UICollectionViewScrollDirectionVertical)];
    }
}

//------------------------------------------------------------------------------
- (NSInteger) numberOfPageInPageView:(PICollectionPageView *) pageView
{
    return 10;
}

//------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{

    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"pageViewCell" forIndexPath:indexPath];
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    [cell.contentView setBackgroundColor:color];
    return cell;
}

//------------------------------------------------------------------------------
- (void) collectionView:(nonnull UICollectionView *)collectionView
didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSLog(@"Select item at index path: %@", indexPath);
}
//------------------------------------------------------------------------------
- (void) pageViewCurrentIndexDidChanged:(PICollectionPageView *)pageView
{
    NSLog(@"Move to page at index: %@", @(pageView.currentPageIndex));
}

@end
