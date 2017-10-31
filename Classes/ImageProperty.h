//
//  ImageProperty.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageProperty : NSObject <NSCoding> {
  char *imageName;
  int size;
  double timestamp;
}

-(id)initWithImageName:(const char *)name size:(int)sz timestamp:(double)time;
-(BOOL)isEqual:(id)object;
-(BOOL)isEqualImageName:(const char *)iName;
-(BOOL)isEqualToString:(NSString *)aString;
-(BOOL)isSuffixOf:(NSString *)aString;
-(const char*)imageName;

@property (readonly) int size;
@property (readonly) double timestamp;

@end
