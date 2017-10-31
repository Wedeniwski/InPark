//
//  ApplicationCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ApplicationCell.h"
#import "AttractionListViewController.h"
#import "SettingsData.h"
#import "Conversions.h"
#import "Colors.h"

@implementation ApplicationCell

@synthesize addButton;
@synthesize addButton2;
@synthesize iconView, favoriteView, closedView;
@synthesize categoryLabel, parkNameLabel, distanceLabel;
@synthesize fitPreferenceView;
@synthesize fitPreferenceLabel;
@synthesize locationLabel;
@synthesize tourCountLabel;
@synthesize inTourLabel;


-(void)dealloc {
  [addButton release];
  [addButton2 release];
  [iconView release];
  [favoriteView release];
  [closedView release];
  [categoryLabel release];
  [parkNameLabel release];
  [distanceLabel release];
  [fitPreferenceView release];
  [fitPreferenceLabel release];
  [locationLabel release];
  [tourCountLabel release];
  [inTourLabel release];
  [super dealloc];
}

-(void)setIconPath:(NSString *)newIconPath {
  [iconView setImagePath:newIconPath];
}

-(void)setClosed:(BOOL)closed {
  closedView.hidden = !closed;
  addButton.hidden = closed;
  addButton2.hidden = closed;
  tourCountLabel.hidden = closed;
  inTourLabel.hidden = closed;
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

-(void)setTourCount:(int)tourCount {
  tourCountLabel.text = [NSString stringWithFormat:@"%d x", tourCount];
  if (tourCount > 0) {
    tourCountLabel.textColor = [UIColor whiteColor];
    tourCountLabel.font = [UIFont boldSystemFontOfSize:tourCountLabel.font.pointSize];
    inTourLabel.textColor = [UIColor whiteColor];
    inTourLabel.font = [UIFont boldSystemFontOfSize:inTourLabel.font.pointSize];
  } else {
    tourCountLabel.textColor = [Colors hilightText];
    tourCountLabel.font = [UIFont systemFontOfSize:tourCountLabel.font.pointSize];
    inTourLabel.textColor = [Colors hilightText];
    inTourLabel.font = [UIFont systemFontOfSize:inTourLabel.font.pointSize];
  }
}

-(IBAction)add:(id)sender {
  if ([sender isKindOfClass:[UIButton class]]) {
    UIButton *b = (UIButton *)sender;
    if ([self.delegate isKindOfClass:[AttractionListViewController class]]) {
      [(AttractionListViewController *)self.delegate addToTour:(int)b.tag target:nil];
    }
  }
}

@end
