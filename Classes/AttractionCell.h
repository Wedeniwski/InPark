//
//  AttractionCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PreferenceFitView.h"
#import "TableCell.h"
#import "AsynchronousImageView.h"

@interface AttractionCell : TableCell {
  IBOutlet UIImageView *favoriteView;
  IBOutlet AsynchronousImageView *iconView;
  IBOutlet UILabel *categoryLabel;
  IBOutlet UILabel *attractionNameLabel;
  IBOutlet PreferenceFitView *fitPreferenceView;
  IBOutlet UILabel *fitPreferenceLabel;
  IBOutlet UILabel *locationLabel;
}

-(void)setIconPath:(NSString *)newIconPath;
-(void)setCategory:(NSString *)newCategory;
-(void)setAttractionName:(NSString *)newAttractionName;
-(void)setLocation:(NSString *)newLocation;
-(void)setPreferenceFit:(double)newPreferenceFit;
-(void)setPreferenceHidden:(BOOL)hidden;

@property (retain, nonatomic) UIImageView *favoriteView;
@property (retain, nonatomic) AsynchronousImageView *iconView;
@property (retain, nonatomic) UILabel *categoryLabel;
@property (retain, nonatomic) UILabel *attractionNameLabel;
@property (retain, nonatomic) PreferenceFitView *fitPreferenceView;
@property (retain, nonatomic) UILabel *fitPreferenceLabel;
@property (retain, nonatomic) UILabel *locationLabel;

@end
