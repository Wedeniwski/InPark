//
//  CustomSwitch.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.11.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CustomSwitch.h"

@implementation CustomSwitch

@synthesize delegate;
@synthesize on;
@synthesize tintColor, clippingView;
@synthesize leftImageView, rightImageView;

-(id)initWithFrame:(CGRect)rect {
  self = [super initWithFrame:CGRectMake(rect.origin.x,rect.origin.y,95,27)];
  if (self != nil) [self awakeFromNib];
  return self;
}

-(void)awakeFromNib {
  [super awakeFromNib];
	self.backgroundColor = [UIColor clearColor];
  [self setThumbImage:[UIImage imageNamed:@"switchThumb.png"] forState:UIControlStateNormal];
  [self setMinimumTrackImage:[UIImage imageNamed:@"switchBlueBg.png"] forState:UIControlStateNormal];
  [self setMaximumTrackImage:[UIImage imageNamed:@"switchOffPlain.png"] forState:UIControlStateNormal];
  self.minimumValue = 0;
  self.maximumValue = 1;
  self.continuous = NO;
	self.on = NO;
	self.value = 0.0;

  clippingView = [[UIView alloc] initWithFrame:CGRectMake(4,2,87,23)];
  clippingView.clipsToBounds = YES;
  clippingView.userInteractionEnabled = NO;
  clippingView.backgroundColor = [UIColor clearColor];
  [self addSubview:clippingView];

  leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 23)];
  leftImageView.contentMode = UIViewContentModeScaleAspectFit;
  rightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(95, 0, 48, 23)];
  rightImageView.contentMode = UIViewContentModeScaleAspectFit;
  [clippingView addSubview:leftImageView];
  [clippingView addSubview:rightImageView];
}

-(void)layoutSubviews {
  [super layoutSubviews];
  [self bringSubviewToFront:clippingView];
  float width = self.bounds.size.width - self.currentThumbImage.size.width;
  float inset = self.clippingView.frame.origin.x;
  float x = (self.value-1)*width - inset;
  leftImageView.frame = CGRectMake(x, 0, width, 23);
  x += self.bounds.size.width; 
  rightImageView.frame = CGRectMake(x, 0, width, 23);
}

-(UIImage *)image:(UIImage*)image tintedWithColor:(UIColor *)tint {	
  if (tint == nil) return image;
  UIGraphicsBeginImageContext(image.size);
  CGContextRef currentContext = UIGraphicsGetCurrentContext();
  CGImageRef maskImage = [image CGImage];
  CGContextClipToMask(currentContext, CGRectMake(0, 0, image.size.width, image.size.height), maskImage);
  CGContextDrawImage(currentContext, CGRectMake(0,0, image.size.width, image.size.height), image.CGImage);
  [image drawAtPoint:CGPointMake(0,0)];
  [tint setFill];
  UIRectFillUsingBlendMode(CGRectMake(0,0,image.size.width,image.size.height),kCGBlendModeColor);
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

-(void)setTintColor:(UIColor*)color {
  if (color != tintColor) {
    [tintColor release];
    tintColor = [color retain];
    [self setMinimumTrackImage:[self image:[UIImage imageNamed:@"switchBlueBg.png"] tintedWithColor:tintColor] forState:UIControlStateNormal];
  }
}

-(void)setOn:(BOOL)turnOn animated:(BOOL)animated {
  on = turnOn;
  if (animated) {
    [UIView beginAnimations:@"CustomSwitch" context:nil];
    [UIView setAnimationDuration:0.2];
    self.value = (on)? 1.0 : 0.0;
    [UIView commitAnimations];
  } else {
    self.value = (on)? 1.0 : 0.0;
  }
  if ([delegate respondsToSelector:@selector(customSwitchDelegate:selectionDidChange:)]) {
    [delegate customSwitchDelegate:self selectionDidChange:turnOn];
  }
}

-(void)setOn:(BOOL)turnOn {
  [self setOn:turnOn animated:NO];
}

static BOOL touched;
-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [super endTrackingWithTouch:touch withEvent:event];
  touched = YES;
  [self setOn:on animated:YES];
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesBegan:touches withEvent:event];
  touched = NO;
  on = !on;
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesEnded:touches withEvent:event];
  if (!touched) {
    [self setOn:on animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
  }
}

-(void)dealloc {
  [tintColor release];
  [clippingView release];
  [leftImageView release];
  [rightImageView release];
  [super dealloc];
}

@end
