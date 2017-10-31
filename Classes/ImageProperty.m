//
//  ImageProperty.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ImageProperty.h"

@implementation ImageProperty

@synthesize size;
@synthesize timestamp;

-(id)initWithImageName:(const char *)name size:(int)sz timestamp:(double)time {
  self = [super init];
  if (self != nil) {
    if (name == NULL) {
      imageName = malloc(sizeof(char));
      *imageName = '\0';
    } else {
      int l = strlen(name);
      imageName = malloc(sizeof(char)*(l+1));
      strcpy(imageName, name);
    }
    size = sz;
    timestamp = time;
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self != nil) {
    if ([coder containsValueForKey:@"IMAGE"]) {
      NSUInteger l = 0;
      const uint8_t *data = [coder decodeBytesForKey:@"IMAGE" returnedLength:&l];
      imageName = malloc(sizeof(char)*(l+1));
      memcpy(imageName, data, l);
      imageName[l] = '\0';
    } else {
      NSString *s = [coder decodeObjectForKey:@"NAME"];
      const char *c = [s UTF8String];
      int l = strlen(c);
      imageName = malloc(sizeof(char)*(l+1));
      strcpy(imageName, c);
    }
    size = [coder decodeIntForKey:@"SIZE"];
    timestamp = [coder decodeDoubleForKey:@"TIMESTAMP"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
  const int l = strlen(imageName);
  [coder encodeBytes:(uint8_t *)imageName length:l forKey:@"IMAGE"];
  //[coder encodeObject:[NSString stringWithFormat:@"%s", imageName] forKey:@"NAME"];
  [coder encodeInt:size forKey:@"SIZE"];
  [coder encodeDouble:timestamp forKey:@"TIMESTAMP"];
}

-(void)dealloc {
  free(imageName);
  [super dealloc];
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[ImageProperty class]]) return NO;
  ImageProperty *imageProperty = (ImageProperty *)object;
  return (strcmp(imageName, imageProperty->imageName) == 0);
}

-(BOOL)isEqualImageName:(const char *)iName {
  return (strcmp(imageName, iName) == 0);
}

-(BOOL)isEqualToString:(NSString *)aString {
  return (strcmp(imageName, [aString UTF8String]) == 0);
}

-(BOOL)isSuffixOf:(NSString *)aString {
  const char *c = [aString UTF8String];
  const int n = strlen(c);
  const int m = strlen(imageName);
  if (m > n) return NO;
	return (strcmp(c+n-m, imageName) == 0);
}

-(const char*)imageName {
  return imageName;
}

@end
