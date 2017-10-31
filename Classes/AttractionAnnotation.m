//
//  AttractionAnnotation.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "AttractionAnnotation.h"
#import "MapPin.h"
#import "Attraction.h"
#import "Categories.h"
#import "RouteView.h"
#import "ParkData.h"
#import "MenuData.h"

/*@interface UIImage (TPAdditions)
-(UIImage*)imageScaledToSize:(CGSize)size;
@end

@implementation UIImage (TPAdditions)
-(UIImage*)imageScaledToSize:(CGSize)size {
  UIGraphicsBeginImageContext(size);
  [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}
@end*/

@implementation AttractionAnnotation

//Add text to UIImage
-(UIImage *)addText:(UIImage *)img text:(NSString *)text1 {
  int w = img.size.width;
  int h = img.size.height;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4*w, colorSpace, kCGImageAlphaPremultipliedFirst);
  
  CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
  char* text	= (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding];// "05/05/09";
  if (text == NULL) {
    NSLog(@"Error: No text for %@", text1);
    text = "";
  }
  CGContextSetTextDrawingMode(context, kCGTextFill);
  CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
  if (w <= 15 && h <= 15) {
    CGContextSelectFont(context, "Arial", 7, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context, 0.0f, 4.0f, text, strlen(text));
  } else {
    CGContextSelectFont(context, "Arial", 24, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context, 8.0f, 24.0f, text, strlen(text));
  }
  CGImageRef imageMasked = CGBitmapContextCreateImage(context);
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  UIImage *resultImage = [UIImage imageWithCGImage:imageMasked];
	CGImageRelease(imageMasked);
  return resultImage;
}

-(void)updateImage:(float)zoomScale {
  static NSMutableDictionary *scaledImgCache = nil;
  static NSMutableDictionary *imgCache = nil;
  if (scaledImgCache == nil) scaledImgCache = [[NSMutableDictionary alloc] initWithCapacity:40];
  if (imgCache == nil) imgCache = [[NSMutableDictionary alloc] initWithCapacity:20];
  self.backgroundColor = [UIColor clearColor];
  self.clipsToBounds = NO;
	if (![self.annotation isKindOfClass:[MapPin class]]) return;
  if (zoomScale <= 0.0f) {
    self.image = nil;
    return;
  }
  MapPin *mapPin = (MapPin *)self.annotation;
  NSString *parkId = mapPin.parkId;
  NSString *attractionId = mapPin.attractionId;
  NSString *imageName = nil;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  if (attraction == nil) {
    if (![Attraction isInternalId:attractionId]) NSLog(@"NO annotation for attraction %@", attractionId);
#ifdef DEBUG_MAP
    imageName = @"small_button_yellow.png";
#else
    self.image = nil;
    return;
#endif
  } else {
    Categories *categories = [Categories getCategories];
    imageName = [categories getIconForTypeIdOrCategoryId:attraction.typeId];
#ifdef DEBUG_MAP
    if (imageName == nil && ([attractionId hasPrefix:@"WP"] || [attraction.typeName length] == 0)) {
      NSLog(@"%@ -> attraction '%s' (type '%@')", attractionId, attraction.attractionName, attraction.typeName);
      imageName = @"small_button_yellow.png";
    }
#endif
    if (imageName == nil) {
      NSLog(@"NO image name for type %@ (of attraction %@)", attraction.typeName, attractionId);
      self.image = nil;
      return;
    }
  }
#ifdef DEBUG_MAP
  NSString *imageText = attractionId;
  if (attraction.nextStationId != nil) {
    Attraction *nextAttraction = [Attraction getAttraction:parkId attractionId:attraction.nextStationId];
    if (nextAttraction == nil) NSLog(@"NO annotation for next station attraction %@", attraction.nextStationId);
  }
#else
  NSString *imageText = @"";
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([attraction isRealAttraction]) {
    if ([parkData isExitAttractionId:attractionId]) imageText = NSLocalizedString(@"exit", nil);
    else if ([parkData isFastLaneEntryAttractionId:attractionId]) imageText = NSLocalizedString(@"fast", nil);
  } 
#endif
  NSString *imageNameScale = [[NSString alloc] initWithFormat:@"%@,%.5f,%@", imageName, zoomScale, imageText];
  UIImage *theImage = [scaledImgCache objectForKey:imageNameScale];
  if (theImage == nil) {
    theImage = [imgCache objectForKey:imageName];
    if (theImage == nil) {
      theImage = [UIImage imageWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:imageName]];
      if (theImage == nil) {
        NSLog(@"NO image for %@", imageName);
#ifdef DEBUG_MAP
        imageName = @"small_button_yellow.png";
        theImage = [UIImage imageWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:imageName]];
#else
        self.image = nil;
        [imageNameScale release];
        return;
#endif
      }
      //NSLog(@"caching image %@", imageName);
      [imgCache setObject:theImage forKey:imageName];
    }
    if ([imageText length] > 0) theImage = [self addText:theImage text:imageText];
    double s = [[UIScreen mainScreen] scale];
    if (s > 1.0) s = sqrt(s);//exp(0.4*log(s));
    zoomScale *= s/2;
    //NSLog(@"width:%f, zoomScale:%f  scale:%f", theImage.size.width, zoomScale, [[UIScreen mainScreen] scale]);
    if (theImage.size.width > 19.0f) theImage = [UIImage imageWithCGImage:theImage.CGImage scale:(theImage.size.width/19.0f)*zoomScale orientation:UIImageOrientationUp];
    //NSLog(@"caching scaled image %@", imageNameScale);
    [scaledImgCache setObject:theImage forKey:imageNameScale];
  }
  self.image = theImage;
  self.transform = CGAffineTransformIdentity;
  self.alpha = (mapPin.overlap)? 0.7f : 1.0f;
  [imageNameScale release];
}

-(void)dealloc {
  [super dealloc];
}

@end
