//
//  Colors.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 09.07.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "Colors.h"

void rgbToHsv(double redIn, double greenIn, double blueIn, double *hue, double *saturation, double *value) {
  double min,max;
  if (redIn < greenIn) {
    min = (redIn < blueIn)? redIn : blueIn;
    max = (greenIn > blueIn)? greenIn : blueIn;
  } else {
    min = (greenIn < blueIn)? greenIn : blueIn;
    max = (redIn > blueIn)? redIn : blueIn;
  }
  if (max != 0) {
    double d = max - min;
    *saturation = d/max;
    if (redIn == max) d = (greenIn - blueIn)/d;
    else if (greenIn == max) d = 2 + (blueIn - redIn)/d;
    else d = 4 + (redIn - greenIn)/d;
    d *= 60.0;
    if (d < 0) d += 360.0;
    *hue = d;
  } else {
    *saturation = 0;
    *hue = -1.0;
  }
  *value = max;
}

void hsvToRgb(double h, double s, double v, double *r, double *g, double *b) {
  if (s == 0) { // achromatic (grey)
    *r = *g = *b = v;
  } else {
    h /= 60;         // sector 0 to 5
    int i = floor(h);
    float f = h - i;          // factorial part of h
    float p = v * (1 - s);
    float q = v * (1 - s*f);
    float t = v * (1 - s*(1 - f));
    switch (i) {
      case 0:
        *r = v;
        *g = t;
        *b = p;
        break;
      case 1:
        *r = q;
        *g = v;
        *b = p;
        break;
      case 2:
        *r = p;
        *g = v;
        *b = t;
        break;
      case 3:
        *r = p;
        *g = q;
        *b = v;
        break;
      case 4:
        *r = t;
        *g = p;
        *b = v;
        break;
      default:        // case 5:
        *r = v;
        *g = p;
        *b = q;
        break;
    }
  }
}

@implementation Colors

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>24)&0xFF)/255.0 green:((c>>16)&0xFF)/255.0 blue:((c>>8)&0xFF)/255.0 alpha:((c)&0xFF)/255.0]

+(NSString *)htmlColorCode:(UIColor *)color {
  //const CGFloat* components = CGColorGetComponents(color.CGColor);
  //return [NSString stringWithFormat:@"#%02X%02X%02X" , (int)(components[0]*255.0), (int)(components[1]*255.0), (int)(components[2]*255.0)];
  CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
  unsigned char resultingPixel[4];
  CGContextRef context = CGBitmapContextCreate(&resultingPixel, 1, 1, 8, 4, rgbColorSpace, kCGImageAlphaNoneSkipLast);
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
  CGContextRelease(context);
  CGColorSpaceRelease(rgbColorSpace);
  return [NSString stringWithFormat:@"#%02X%02X%02X" , (int)resultingPixel[0], (int)resultingPixel[1], (int)resultingPixel[2]];
}

+(UIColor *)hilightText {
  static UIColor *hilightText = nil;
  if (hilightText == nil) hilightText = [[UIColor whiteColor] retain];
  return hilightText;
}

+(UIColor *)lightText {
  static UIColor *lightText = nil;
  if (lightText == nil) lightText = [[UIColor alloc] initWithRed:249/255.0 green:233/255.0 blue:212/255.0 alpha:1.0];
  return lightText;
}

+(UIColor *)darkBlue {
  static UIColor *darkBlue = nil;
  if (darkBlue == nil) darkBlue = [[UIColor alloc] initWithRed:4/255.0 green:43/255.0 blue:115/255.0 alpha:1.0];
  return darkBlue;
}

+(UIColor *)blueTransparent {
  static UIColor *blueTransparent = nil;
  if (blueTransparent == nil) blueTransparent = [[UIColor alloc] initWithRed:40/255.0 green:88/255.0 blue:160/255.0 alpha:0.3];
  return blueTransparent;
}

+(UIColor *)lightBlue {
  static UIColor *lightBlue = nil;
  if (lightBlue == nil) lightBlue = [[UIColor alloc] initWithRed:77/255.0 green:133/255.0 blue:206/255.0 alpha:1.0];
  return lightBlue;
}

+(UIColor *)settingColor {
  static UIColor *settingColor = nil;
  if (settingColor == nil) settingColor = [[UIColor whiteColor] retain];//[[UIColor alloc] initWithRed:0.22f green:0.33f blue:0.53f alpha:1.0f];
  return settingColor;
}

+(UIColor *)noWaitingTime {
  static UIColor *noWaitingTime = nil;
  if (noWaitingTime == nil) noWaitingTime = [[UIColor alloc] initWithRed:54.0f/255.0f green:54.0f/255.0f blue:54.0f/255.0f alpha:1.0f];
  return noWaitingTime;
}

+(UIColor *)lowWaitingTime {
  static UIColor *lowWaitingTime = nil;
  //if (lowWaitingTime == nil) lowWaitingTime = [[UIColor alloc] initWithRed:188.0f/255.0f green:252.0f/255.0f blue:97.0f/255.0f alpha:1.0f];
  if (lowWaitingTime == nil) lowWaitingTime = [[UIColor alloc] initWithRed:54.0f/255.0f green:212.0f/255.0f blue:66.0f/255.0f alpha:1.0f];
  return lowWaitingTime;
}

+(UIColor *)midWaitingTime {
  static UIColor *midWaitingTime = nil;
  //if (midWaitingTime == nil) midWaitingTime = [[UIColor alloc] initWithRed:255.0f/255.0f green:127.0f/255.0f blue:80.0f/255.0f alpha:1.0f];
  if (midWaitingTime == nil) midWaitingTime = [[UIColor alloc] initWithRed:255.0f/255.0f green:179.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
  return midWaitingTime;
}

+(UIColor *)highWaitingTime {
  static UIColor *highWaitingTime = nil;
  //if (highWaitingTime == nil) highWaitingTime = [[UIColor alloc] initWithRed:187.0f/255.0f green:21.0f/255.0f blue:100.0f/255.0f alpha:1.0f];
  if (highWaitingTime == nil) highWaitingTime = [[UIColor alloc] initWithRed:214.0f/255.0f green:30.0f/255.0f blue:36.0f/255.0f alpha:1.0f];
  return highWaitingTime;
}

@end
