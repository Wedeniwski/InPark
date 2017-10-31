//
//  PreferenceFitView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreferenceFitView : UIView {
  double preferenceFit;
  UIImageView *backgroundImageView;
  UIImageView *foregroundImageView;
}

-(id)initWithFrame:(CGRect)frame;
-(id)initWithCoder:(NSCoder *)coder;
-(void)setBackgroundImage:(UIImage *)image;
-(void)setForegroundImage:(UIImage *)image;
-(void)setPreferenceFit:(double)newPreferenceFit;
-(void)setHidden:(BOOL)hidden;
-(int)getRating;
-(void)setRating:(int)newRating;

@property (readonly) double preferenceFit;

@end
