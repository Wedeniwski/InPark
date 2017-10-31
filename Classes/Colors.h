//
//  Colors.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 09.07.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>24)&0xFF)/255.0 green:((c>>16)&0xFF)/255.0 blue:((c>>8)&0xFF)/255.0 alpha:((c)&0xFF)/255.0]

void rgbToHsv(double redIn, double greenIn, double blueIn, double *hue, double *saturation, double *value);
void hsvToRgb(double h, double s, double v, double *r, double *g, double *b);

@interface Colors : NSObject {
}

+(NSString *)htmlColorCode:(UIColor *)color;

+(UIColor *)hilightText;
+(UIColor *)lightText;
+(UIColor *)darkBlue;
+(UIColor *)blueTransparent;
+(UIColor *)lightBlue;
+(UIColor *)settingColor;
+(UIColor *)noWaitingTime;
+(UIColor *)lowWaitingTime;
+(UIColor *)midWaitingTime;
+(UIColor *)highWaitingTime;

@end
