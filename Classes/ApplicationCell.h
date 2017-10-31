//
//  ApplicationCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PreferenceFitView.h"
#import "TableCell.h"
#import "AsynchronousImageView.h"

@interface ApplicationCell : TableCell {
  IBOutlet UIButton *addButton;
  IBOutlet UIButton *addButton2;
  IBOutlet AsynchronousImageView *iconView;
  IBOutlet UIImageView *favoriteView;
  IBOutlet UIImageView *closedView;
  
  IBOutlet UILabel *categoryLabel;
  IBOutlet UILabel *parkNameLabel;
  IBOutlet UILabel *distanceLabel;
  IBOutlet PreferenceFitView *fitPreferenceView;
  IBOutlet UILabel *fitPreferenceLabel;
  IBOutlet UILabel *locationLabel;
  IBOutlet UILabel *tourCountLabel;
  IBOutlet UILabel *inTourLabel;
}

-(void)setIconPath:(NSString *)newIconPath;
-(void)setClosed:(BOOL)closed;
-(void)setPreferenceFit:(double)newPreferenceFit;
-(void)setPreferenceHidden:(BOOL)hidden;
-(void)setTourCount:(int)tourCount;

-(IBAction)add:(id)sender;

@property (retain, nonatomic) UIButton *addButton;
@property (retain, nonatomic) UIButton *addButton2;
@property (retain, nonatomic) AsynchronousImageView *iconView;
@property (retain, nonatomic) UIImageView *favoriteView;
@property (retain, nonatomic) UIImageView *closedView;
@property (retain, nonatomic) UILabel *categoryLabel;
@property (retain, nonatomic) UILabel *parkNameLabel;
@property (retain, nonatomic) UILabel *distanceLabel;
@property (retain, nonatomic) PreferenceFitView *fitPreferenceView;
@property (retain, nonatomic) UILabel *fitPreferenceLabel;
@property (retain, nonatomic) UILabel *locationLabel;
@property (retain, nonatomic) UILabel *tourCountLabel;
@property (retain, nonatomic) UILabel *inTourLabel;

@end
