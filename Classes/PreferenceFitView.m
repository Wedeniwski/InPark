//
//  PreferenceFitView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "PreferenceFitView.h"
#import "Colors.h"

@implementation PreferenceFitView

@synthesize preferenceFit;

-(void)initContent {
  backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"StarsBackground.png"]];
  backgroundImageView.contentMode = UIViewContentModeLeft;
  [self addSubview:backgroundImageView];
  //[backgroundImageView release];
  
  foregroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"StarsForeground.png"]];
  foregroundImageView.contentMode = UIViewContentModeLeft;
  foregroundImageView.clipsToBounds = YES;
  [self addSubview:foregroundImageView];
  //[foregroundImageView release];
  self.backgroundColor = [Colors lightBlue];
}

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    [self initContent];
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self != nil) {
    [self initContent];
  }
  return self;
}

-(void)setBackgroundImage:(UIImage *)image {
  backgroundImageView.image = image;
}

-(void)setForegroundImage:(UIImage *)image {
  foregroundImageView.image = image;
}

-(void)setPreferenceFit:(double)newPreferenceFit {
  preferenceFit = newPreferenceFit;
  foregroundImageView.frame = CGRectMake(0.0, 0.0, backgroundImageView.frame.size.width * preferenceFit, foregroundImageView.bounds.size.height);
}

-(void)setHidden:(BOOL)hidden {
  backgroundImageView.hidden = hidden;
  foregroundImageView.hidden = hidden;
}

-(int)getRating {
  return (int)(preferenceFit*5);
}

-(void)setRating:(int)newRating {
  [self setPreferenceFit:(0.2*newRating)];
}

-(void)dealloc {
  [backgroundImageView release];
  [foregroundImageView release];
  [super dealloc];
}

@end
