//
//  GeneralInfoViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 11.12.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeneralInfoViewController : UIViewController {
	id delegate;
  NSString *fileName;
  NSString *titleName;
  NSString *content;
  NSString *subdirectory;
  
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UIWebView *webView;
  IBOutlet UIActivityIndicatorView *activityIndicatorView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner fileName:(NSString *)fName title:(NSString *)tName;

-(IBAction)loadBackView:(id)sender;

@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) UIWebView *webView;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) NSString *content;
@property (retain, nonatomic) NSString *subdirectory;

@end
