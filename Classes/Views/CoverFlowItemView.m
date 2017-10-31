//
//  CoverFlowItemView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CoverFlowItemView.h"

@implementation CoverFlowItemView

@synthesize imageView;

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    float w = self.frame.size.width;
    imageView = [[AsynchronousImageView alloc] initWithFrame:CGRectMake(0, 0, w, w)];
    [imageView setBorderWidth:2.0f];
    [self addSubview:imageView];
  }
  return self;
}

-(void)dealloc {
  [imageView removeFromSuperview];
	[imageView release];
  [super dealloc];
}

-(BOOL)isEqual:(id)object {
  if ([object isKindOfClass:[AsynchronousImageView class]]) {
    AsynchronousImageView *view = (AsynchronousImageView *)object;
    return [imageView isEqual:view];
  } else if ([object isKindOfClass:[CoverFlowItemView class]]) {
    CoverFlowItemView *view = (CoverFlowItemView *)object;
    return [imageView isEqual:view.imageView];
  }
  return NO;
}

-(void)setImagePath:(NSString *)path {
  [imageView setImagePath:path];
}

-(UIImage*)image {
	return imageView.imageView.image;
}

@end
