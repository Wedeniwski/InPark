//
//  TutorialView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 24.05.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TutorialView.h"
#import "CustomBadge.h"
#import "Colors.h"

@implementation TutorialView

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    delegate = nil;
    self.backgroundColor = [UIColor clearColor];
    frames = [[NSMutableArray alloc] initWithCapacity:5];
    text = [[NSMutableArray alloc] initWithCapacity:5];
    directions = [[NSMutableArray alloc] initWithCapacity:5];
    position = [[NSMutableArray alloc] initWithCapacity:5];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y+20.0f, frame.size.width, 23.0f)];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:28.0f];
    label.text = NSLocalizedString(@"tutorial.title", nil);
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blueColor];
    label.shadowOffset = CGSizeMake(0, 1);
    label.backgroundColor = [UIColor clearColor];
    [self addSubview:label];
    [label release];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    [button addTarget:self action:@selector(endTutorial:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:button];
  }
  return self;
}

-(void)dealloc {
  [frames release];
  [text release];
  [directions release];
  [position release];
  [super dealloc];
}

-(void)setOwner:(UIViewController<TutorialViewDelegate> *)owner {
  NSLog(@"define owner of the tutorial view");
  delegate = owner;
  for (id subview in owner.view.subviews) {
    if ([subview isKindOfClass:[UIControl class]]) {
      UIControl *v = subview;
      v.alpha = 0.4f;
      v.enabled = NO;
    } else if ([subview isKindOfClass:[UIView class]]) {
      UIView *v = subview;
      v.alpha = 0.4f;
    }
  }
}

-(void)addFrame:(CGRect)rect alignmentLeft:(BOOL)alignmentLeft alignmentBottom:(BOOL)alignmentBottom withText:(NSString *)t {
  [frames addObject:[NSValue valueWithCGRect:rect]];
  [text addObject:t];
  CustomBadge *badge = [CustomBadge customBadgeWithString:t withStringColor:[UIColor whiteColor] withInsetColor:[UIColor darkGrayColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor redColor] withScale:1.0f withShining:YES];
  float x = rect.origin.x-14.0f;
  float y = rect.origin.y+rect.size.height+10.0f;
  float maxTextWidth = 0.0f;
  UIFont *font = [UIFont boldSystemFontOfSize:16];
  NSArray *a = [t componentsSeparatedByString:@"\n"];
  for (NSString *s in a) {
    CGSize stringSize = [s sizeWithFont:font];
    if (stringSize.width > maxTextWidth) maxTextWidth = stringSize.width;
  }
  maxTextWidth += 10.0f;
  if (x+maxTextWidth > self.frame.origin.x+self.frame.size.width) x = self.frame.origin.x+self.frame.size.width-maxTextWidth;
  else if (!alignmentLeft) x = rect.origin.x+rect.size.width-maxTextWidth;
  if (!alignmentBottom || y+60.0f > self.frame.size.height) y = rect.origin.y-70.0f;
  [directions addObject:[NSNumber numberWithBool:(y >= rect.origin.y)]];
  float pos = (alignmentLeft)? x+25.0f : x+maxTextWidth-25.0f;
  if (pos > rect.origin.x+rect.size.width) pos = rect.origin.x+rect.size.width-25.0f;
  [position addObject:[NSNumber numberWithFloat:pos]];
  badge.frame = CGRectMake(x, y, maxTextWidth, 60.0f);
  badge.badgeCornerRoundness = 0.1;
  [self addSubview:badge];
}

-(void)addLabelFrame:(CGRect)rect withText:(NSString *)t {
  UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
  label.adjustsFontSizeToFitWidth = YES;
  label.minimumFontSize = 9.0;
  label.numberOfLines = 6;
  label.text = t;
  label.textColor = [Colors lightText];
  label.backgroundColor = [Colors darkBlue];
  [self addSubview:label];
}

-(void)clear {
  NSLog(@"clear tutorial view");
  [frames removeAllObjects];
  [text removeAllObjects];
  [directions removeAllObjects];
  [position removeAllObjects];
  [self setNeedsDisplay];
}

-(void)drawRoundedRectWithContext:(CGContextRef)context withRect:(CGRect)rect pos:(float)pos direction:(BOOL)direction {
	CGContextSaveGState(context);
  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:10.0f];
  if (direction) {
    [path moveToPoint:CGPointMake(pos, rect.origin.y+rect.size.height)];
    [path addLineToPoint:CGPointMake(pos, rect.origin.y+rect.size.height+20.0f)];
  } else {
    [path moveToPoint:CGPointMake(pos, rect.origin.y)];
    [path addLineToPoint:CGPointMake(pos, rect.origin.y-20.0f)];
  }
  CGContextAddPath(context, path.CGPath);
  CGContextSetLineWidth(context, 6.0f);
  CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
  CGContextStrokePath(context);
	CGContextRestoreGState(context);
}

-(void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  const int l = (int)[frames count];
  for (int i = 0; i < l; ++i) {
    NSValue *value = [frames objectAtIndex:i];
    [self drawRoundedRectWithContext:context withRect:[value CGRectValue] pos:[[position objectAtIndex:i] floatValue] direction:[[directions objectAtIndex:i] boolValue]];
  }
}

-(IBAction)endTutorial:(id)sender {
  NSLog(@"close tutorial view");
  [self clear];
  for (id subview in delegate.view.subviews) {
    if ([subview isKindOfClass:[UIControl class]]) {
      UIControl *v = subview;
      v.alpha = 1.0f;
      v.enabled = YES;
    } else if ([subview isKindOfClass:[UIView class]]) {
      UIView *v = subview;
      if (v.alpha > 0.0f) v.alpha = 1.0f;
    }
  }
  if ([delegate respondsToSelector:@selector(endTutorial)]) [delegate endTutorial];
}

@end
