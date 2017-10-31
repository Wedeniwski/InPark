//
//  WildcardGestureRecognizer.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.08.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "WildcardGestureRecognizer.h"

@implementation WildcardGestureRecognizer
@synthesize touchesBeganCallback;

-(id)init {
  self = [super init];
  if (self) self.cancelsTouchesInView = NO;
  return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if (touchesBeganCallback) touchesBeganCallback(touches, event);
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)reset {
}

-(void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event {
}

-(BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
  return NO;
}

-(BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
  return NO;
}

@end
