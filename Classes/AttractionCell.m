//
//  AttractionCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AttractionCell.h"
#import "SettingsData.h"

@implementation AttractionCell

@synthesize favoriteView, iconView;
@synthesize categoryLabel, attractionNameLabel;
@synthesize fitPreferenceView;
@synthesize fitPreferenceLabel;
@synthesize locationLabel;

-(void)dealloc {
  [favoriteView release];
  [iconView release];
  [categoryLabel release];
  [attractionNameLabel release];
  [fitPreferenceView release];
  [fitPreferenceLabel release];
  [locationLabel release];
  [super dealloc];
}

-(void)setIconPath:(NSString *)newIconPath {
  [iconView setImagePath:newIconPath];
}

-(void)setCategory:(NSString *)newCategory {
  categoryLabel.text = (newCategory != nil)? newCategory : @"";
}

-(void)setAttractionName:(NSString *)newAttractionName {
  attractionNameLabel.text = (newAttractionName != nil)? newAttractionName : @"";
}

-(void)setLocation:(NSString *)newLocation {
  locationLabel.text = (newLocation != nil)? newLocation : @"";
}

-(void)setPreferenceFit:(double)newPreferenceFit {
  [fitPreferenceView setPreferenceFit:newPreferenceFit];
  NSString *s = NSLocalizedString(@"attraction.list.cell.fit", nil);
  fitPreferenceLabel.text = [NSString stringWithFormat:s, (int)(100.0*newPreferenceFit)];
}

-(void)setPreferenceHidden:(BOOL)hidden {
  [fitPreferenceView setHidden:hidden];
  fitPreferenceLabel.hidden = hidden;
}

@end
