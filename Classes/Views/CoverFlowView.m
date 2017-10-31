//
//  CoverFlowView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CoverFlowView.h"

#define COVER_SPACING 70.0
#define CENTER_COVER_OFFSET 70
#define SIDE_COVER_ANGLE 1.4
#define SIDE_COVER_ZPOSITION -80
#define COVER_SCROLL_PADDING 4

#pragma mark -
@interface CoverFlowView (hidden)

-(void)animateToIndex:(int)index animated:(BOOL)animated;
-(void)load;
-(void)setup;
-(void)newrange;
-(void)setupTransforms;
-(void)adjustViewHeirarchy;
-(void)deplaceAlbumsFrom:(int)start to:(int)end;
-(void)deplaceAlbumsAtIndex:(int)cnt;
-(BOOL)placeAlbumsFrom:(int)start to:(int)end;
-(void)placeAlbumAtIndex:(int)cnt;
-(void)snapToAlbum:(BOOL)animated;

@end

#pragma mark -

@implementation CoverFlowView (hidden)

#pragma mark Setup

-(void)setupTransforms {
	leftTransform = CATransform3DMakeRotation(coverAngle, 0, 1, 0);
	leftTransform = CATransform3DConcat(leftTransform,CATransform3DMakeTranslation(-spaceFromCurrent, 0, -300));
	rightTransform = CATransform3DMakeRotation(-coverAngle, 0, 1, 0);
	rightTransform = CATransform3DConcat(rightTransform,CATransform3DMakeTranslation(spaceFromCurrent, 0, -300));
}

-(void)load {
	super.delegate = self;
  self.backgroundColor = [UIColor clearColor];
	self.showsHorizontalScrollIndicator = NO;
  layoutEnabled = YES;
	numberOfCovers = 0;
	coverSpacing = COVER_SPACING;
	coverAngle = SIDE_COVER_ANGLE;
	origin = self.contentOffset.x;
	yard = [[NSMutableArray alloc] initWithCapacity:10];
	views = [[NSMutableArray alloc] initWithCapacity:10];
	coverSize = CGSizeMake(224, 224);
	spaceFromCurrent = coverSize.width/2.4;
	[self setupTransforms];

	CATransform3D sublayerTransform = CATransform3DIdentity;
	sublayerTransform.m34 = -0.001;
	[self.layer setSublayerTransform:sublayerTransform];

	currentIndex = -1;
	currentSize = self.frame.size;
}

-(void)setup {
	currentIndex = -1;
	for (UIView *v in views) [v removeFromSuperview];
	[yard removeAllObjects];
	[views removeAllObjects];
	[coverViews release];
	coverViews = nil;
	if (numberOfCovers < 1){
		self.contentOffset = CGPointZero;
		return;
	} 
	coverViews = [[NSMutableArray alloc] initWithCapacity:numberOfCovers];
	for (unsigned i = 0; i < numberOfCovers; ++i) [coverViews addObject:[NSNull null]];
	deck = NSMakeRange(0, 0);
	
	currentSize = self.frame.size;
	margin = (self.frame.size.width / 2);
	self.contentSize = CGSizeMake( (coverSpacing) * (numberOfCovers-1) + (margin*2) , currentSize.height);
	coverBuffer = 5;//(int) ((currentSize.width - coverSize.width) / coverSpacing) + 3;

	movingRight = YES;
	currentSize = self.frame.size;
	currentIndex = 0;
	self.contentOffset = CGPointZero;

	[self newrange];
	[self animateToIndex:currentIndex animated:NO];
}

#pragma mark Manage Visible Covers
-(void)deplaceAlbumsFrom:(int)start to:(int)end{
	for (int i = start; i < end; ++i) [self deplaceAlbumsAtIndex:i];
}

-(void)deplaceAlbumsAtIndex:(int)i {
  if (i < [coverViews count]) {
    id obj = [coverViews objectAtIndex:i];
    if (obj != [NSNull null]) {
      UIView *v = obj;
      [v removeFromSuperview];
      [views removeObject:v];
      [yard addObject:v];
      [coverViews replaceObjectAtIndex:i withObject:[NSNull null]];
    }
	}
}

-(BOOL)placeAlbumsFrom:(int)start to:(int)end {
	if (start >= end) return NO;
	for (int i = start; i <= end; ++i) [self placeAlbumAtIndex:i];
	return YES;
}

-(void)placeAlbumAtIndex:(int)i {
	if (i < [coverViews count] && [coverViews objectAtIndex:i] == [NSNull null]) {
		CoverFlowItemView *cover = [dataSource coverflowView:self atIndex:i];
		[coverViews replaceObjectAtIndex:i withObject:cover];
		CGRect r = cover.frame;
		r.origin.y = currentSize.height/2 - (coverSize.height/2) - (coverSize.height/16);
		r.origin.x = (currentSize.width/2 - (coverSize.width/2)) + (coverSpacing) * i;
		cover.frame = r;
		[self addSubview:cover];
		if (i > currentIndex){
			cover.layer.transform = rightTransform;
			[self sendSubviewToBack:cover];
		} else {
			cover.layer.transform = leftTransform;
    }
		[views addObject:cover];
	}
}

#pragma mark Manage Range and Animations
-(void)newrange {
	int loc = deck.location, len = deck.length, buff = coverBuffer;
	int newLocation = MAX(currentIndex-buff, 0);
	int newLength = (currentIndex+buff > numberOfCovers)? numberOfCovers-newLocation : currentIndex+buff-newLocation;
	if (loc != newLocation || newLength != len) {
    if (movingRight){
      [self deplaceAlbumsFrom:loc to:MIN(newLocation, loc+len)];
      [self placeAlbumsFrom:MAX(loc+len, newLocation) to:newLocation+newLength];
    } else {
      [self deplaceAlbumsFrom:MAX(newLength+newLocation, loc) to:loc+len];
      [self placeAlbumsFrom:newLocation to:newLocation+newLength];
    }
    deck = NSIntersectionRange(NSMakeRange(0, numberOfCovers), NSMakeRange(newLocation, newLength));
  }
}

-(void)adjustViewHeirarchy {
	int i = currentIndex-1;
	if (i >= 0) 
		for (; i > deck.location; --i) [self sendSubviewToBack:[coverViews objectAtIndex:i]];
	i = currentIndex+1;
	if (i < numberOfCovers-1) 
		for (NSUInteger l = deck.location+deck.length; i < l; ++i) [self sendSubviewToBack:[coverViews objectAtIndex:i]];
	UIView *v = [coverViews objectAtIndex:currentIndex];
	if ((NSObject *)v != [NSNull null]) [self bringSubviewToFront:[coverViews objectAtIndex:currentIndex]];
}

-(void)snapToAlbum:(BOOL)animated {
	UIView *v = [coverViews objectAtIndex:currentIndex];
	if ((NSObject *)v != [NSNull null]) [self setContentOffset:CGPointMake(v.center.x - (currentSize.width/2), 0) animated:animated];
	else [self setContentOffset:CGPointMake(coverSpacing*currentIndex, 0) animated:animated];
}

-(void)animateToIndex:(int)index animated:(BOOL)animated {
	NSString *string = [NSString stringWithFormat:@"%d", currentIndex];
	if (velocity > 200) animated = NO;
	if (animated) {
		float speed = (velocity > 80)? 0.05 : 0.2;
		[UIView beginAnimations:string context:nil];
		[UIView setAnimationDuration:speed];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)]; 
	}
	for (UIView *v in views) {
		int i = [coverViews indexOfObject:v];
		if (i < index) v.layer.transform = leftTransform;
		else if (i > index) v.layer.transform = rightTransform;
		else v.layer.transform = CATransform3DIdentity;
	}
	if (animated) [UIView commitAnimations];
	else [coverflowDelegate coverflowView:self selectionDidChange:currentIndex];
}

-(void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([finished boolValue]) {
    [self adjustViewHeirarchy];
    if ([animationID intValue] == currentIndex) [coverflowDelegate coverflowView:self selectionDidChange:currentIndex];
  }
}

@end


#pragma mark -
@implementation CoverFlowView

@synthesize layoutEnabled;
@synthesize margin;
@synthesize coverflowDelegate, dataSource, coverSize, numberOfCovers, coverSpacing, coverAngle;

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    [self load];
    currentSize = frame.size;
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self != nil) {
    [self load];
  }
  return self;
}

-(void)dealloc {	
  [yard release];
  yard = nil;
  [views release];
  views = nil;
  [coverViews release];
  coverViews = nil;
  currentTouch = nil;
  coverflowDelegate = nil;
  dataSource = nil;
  [super dealloc];
}

-(void)layoutSubviews {
  if (!layoutEnabled || (self.frame.size.width == currentSize.width && self.frame.size.height == currentSize.height)) return;
	currentSize = self.frame.size;
	margin = (self.frame.size.width / 2);
	self.contentSize = CGSizeMake( (coverSpacing) * (numberOfCovers-1) + (margin*2) , self.frame.size.height);
	coverBuffer = 5;//(int)((currentSize.width - coverSize.width) / coverSpacing) + 3;
	for(UIView *v in views){
		v.layer.transform = CATransform3DIdentity;
		CGRect r = v.frame;
		r.origin.y = currentSize.height / 2 - (coverSize.height/2) - (coverSize.height/16);
		v.frame = r;
    
	}
	for(int i= deck.location; i < deck.location + deck.length; i++){
		if([coverViews objectAtIndex:i] != [NSNull null]){
			UIView *cover = [coverViews objectAtIndex:i];
			CGRect r = cover.frame;
			r.origin.x = (currentSize.width/2 - (coverSize.width/ 2)) + (coverSpacing) * i;
			cover.frame = r;
		}
	}
	[self newrange];
	[self animateToIndex:currentIndex animated:NO];
}

#pragma mark Public Methods
-(CoverFlowItemView *)coverflowView:(CoverFlowView *)coverflowView atIndex:(int)index {
  id cover = [coverViews objectAtIndex:index];
  return (cover != [NSNull null])? cover : nil;
}

-(NSInteger)indexOfFrontCoverView {
  return currentIndex;
}

-(CoverFlowItemView *)dequeueReusableCoverView {
  if ([yard count] < 1) return nil;
  CoverFlowItemView *cover = [[[yard lastObject] retain] autorelease];
  cover.layer.transform = CATransform3DIdentity;
  [yard removeLastObject];
  return cover;
}

-(void)bringCoverAtIndexToFront:(int)index animated:(BOOL)animated {
  if (index != currentIndex) {
    currentIndex = index;
    [self snapToAlbum:animated];
    [self newrange];
    [self animateToIndex:index animated:animated];
  }
}

#pragma mark Touch Events
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if (touch.view != self && [touch locationInView:touch.view].y < coverSize.height) currentTouch = touch.view;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if (touch.view == currentTouch && [[coverViews objectAtIndex:currentIndex] isEqual:currentTouch]) {
    if (touch.tapCount == 1 && [coverflowDelegate respondsToSelector:@selector(coverflowView:didSelectAtIndex:)]) {
      [coverflowDelegate coverflowView:self didSelectAtIndex:currentIndex];
    }
	}
	currentTouch = nil;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  currentTouch = nil;
}

#pragma mark UIScrollView Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  float f = self.contentOffset.x;
  movingRight = (f > origin);
  origin = f;
  f = scrollView.contentOffset.x;
  velocity = abs(pos-f);
  pos = f;
	int n = numberOfCovers-1;
	int index = (int)(0.5f + n*f/(self.contentSize.width-currentSize.width));
  if (index < 0) index = 0;
  else if (index > n) index = n;
  if (index != currentIndex) {
    currentIndex = index;
    [self newrange];
    if (velocity < 180 || currentIndex < 15 || currentIndex > numberOfCovers-16) [self animateToIndex:index animated:YES];
  }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (!scrollView.tracking && !scrollView.decelerating) {
    [self snapToAlbum:YES];
    [self adjustViewHeirarchy];
  } 
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!self.decelerating && !decelerate) {
    [self snapToAlbum:YES];
    [self adjustViewHeirarchy];
  }
}

#pragma mark Properties
-(void)setNumberOfCovers:(int)cov {
  numberOfCovers = cov;
  [self setup];
}

-(void)setCoverSpacing:(float)space {
  coverSpacing = space;
  [self setupTransforms];
  [self setup];
  [self layoutSubviews];
}

-(void)setCoverAngle:(float)f {
  coverAngle = f;
  [self setupTransforms];
  [self setup];
}

-(void)setCoverSize:(CGSize)s {
  coverSize = s;
  spaceFromCurrent = coverSize.width/2.4;
  [self setupTransforms];
  [self setup];
}

-(void)setCurrentIndex:(NSInteger)index {
  [self bringCoverAtIndexToFront:index animated:NO];
}

-(NSInteger)currentIndex {
  return currentIndex;
}

-(CoverFlowItemView *)selectedCoverflowView {
  return [self coverflowView:self atIndex:currentIndex];
}

@end
