//
//  RatingViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 19.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TourItem.h"
#import "PreferenceFitView.h"
  
@interface RatingViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate> {
@private
	id delegate;
  UIBarButtonItem *saveButton;

@public
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UIButton *helpButton;
  IBOutlet UIWebView *webView;
  IBOutlet UILabel *ratingLabel;
  IBOutlet UILabel *commentLabel;
  IBOutlet PreferenceFitView *ratingView;
  IBOutlet UITextView *commentsTextView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId;

-(IBAction)decreaseRating:(id)sender;
-(IBAction)increaseRating:(id)sender;
-(IBAction)loadBackView:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)detailsView:(id)sender;

@property (readonly) id delegate;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) UIButton *helpButton;
@property (retain, nonatomic) UIWebView *webView;
@property (retain, nonatomic) UILabel *ratingLabel;
@property (retain, nonatomic) UILabel *commentLabel;
@property (retain, nonatomic) PreferenceFitView *ratingView;
@property (retain, nonatomic) UITextView *commentsTextView;

@end
