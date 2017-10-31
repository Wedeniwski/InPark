//
//  Comment.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 08.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "Comment.h"

@implementation Comment

@synthesize timeInterval;
@synthesize comment;

-(id)initWithComment:(NSString *)text {
  self = [super init];
  if (self != nil) {
    comment = [text retain];
    timeInterval = [[NSDate date] timeIntervalSince1970];
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self != nil) {
    comment = [[coder decodeObjectForKey:@"COMMENT"] retain];
    timeInterval = [coder decodeDoubleForKey:@"TIME"];
  }
  return self;
}

-(void)dealloc {
  [comment release];
  comment = nil;
  [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:comment forKey:@"COMMENT"];
  [coder encodeDouble:timeInterval forKey:@"TIME"];
}


@end
