//
//  Comment.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 08.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject <NSCoding> {
  double timeInterval;
  NSString *comment;
}

-(id)initWithComment:(NSString *)text;

@property (readonly) double timeInterval;
@property (readonly, nonatomic) NSString *comment;

@end
