//
//  CoverFlowView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import "CoverFlowItemView.h"

@protocol CoverFlowViewDelegate, CoverFlowViewDataSource;

@interface CoverFlowView : UIScrollView <UIScrollViewDelegate> {
	NSMutableArray *coverViews;
	NSMutableArray *views;
	NSMutableArray *yard;
  BOOL layoutEnabled;
	float origin;
	BOOL movingRight;
	int pos;
	long velocity;
  
	UIView *currentTouch;
	NSRange deck;
	
	int margin, coverBuffer, currentIndex, numberOfCovers;
	CGSize coverSize,currentSize;
	float coverSpacing,coverAngle,spaceFromCurrent;
	CATransform3D leftTransform, rightTransform;
	
	id <CoverFlowViewDelegate> coverflowDelegate;
	id <CoverFlowViewDataSource> dataSource;
}

-(id)initWithFrame:(CGRect)frame;
-(id)initWithCoder:(NSCoder *)coder;

-(CoverFlowItemView *)dequeueReusableCoverView;
-(void)bringCoverAtIndexToFront:(int)index animated:(BOOL)animated;

@property (nonatomic, assign) id <CoverFlowViewDelegate> coverflowDelegate;
@property (nonatomic, assign) id <CoverFlowViewDataSource> dataSource;
@property BOOL layoutEnabled;
@property (nonatomic, assign) CGSize coverSize;
@property (readonly) int margin;
@property (nonatomic, assign) int numberOfCovers;
@property (nonatomic, assign) float coverSpacing;
@property (nonatomic, assign) float coverAngle;
@property (nonatomic, assign) NSInteger currentIndex;
@property (readonly, nonatomic) CoverFlowItemView *selectedCoverflowView;

@end

@protocol CoverFlowViewDelegate <NSObject>
@required
-(void)coverflowView:(CoverFlowView *)coverflowView selectionDidChange:(int)index;
@optional
-(void)coverflowView:(CoverFlowView *)coverflowView didSelectAtIndex:(int)index;
@end

@protocol CoverFlowViewDataSource <NSObject>
@required
-(CoverFlowItemView *)coverflowView:(CoverFlowView *)coverflowView atIndex:(int)index;
@end
