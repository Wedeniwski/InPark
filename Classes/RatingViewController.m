//
//  RatingViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 19.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "RatingViewController.h"
#import "GeneralInfoViewController.h"
#import "TourViewController.h"
#import "Attraction.h"
#import "Comment.h"
#import "ParkData.h"
#import "HelpData.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "IPadHelper.h"
#import "Colors.h"

@implementation RatingViewController

static NSString *parkId = nil;
static NSString *attractionId = nil;

@synthesize delegate;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize helpButton;
@synthesize webView;
@synthesize ratingLabel;
@synthesize commentLabel;
@synthesize ratingView;
@synthesize commentsTextView;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    // Custom initialization
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [attractionId release];
    attractionId = [aId retain];
  }
  return self;
}

-(void)updateData {
  ParkData *parkData = [ParkData getParkData:parkId];
  [ratingView setRating:[parkData getPersonalRating:attractionId]];
  Attraction *a = [Attraction getAttraction:parkId attractionId:attractionId];
  BOOL iPad = [IPadHelper isIPad];
  int fontSize = (iPad)? 14 : 12;
  int imgSize = (iPad)? 200: 110;
  NSMutableString *s = [[NSMutableString alloc] initWithFormat:@"<html><head><style type=\"text/css\">table {font-family:helvetica;font-size:%dpx;background-color:transparent;}</style>", fontSize];
  [s appendString:@"<script>document.ontouchmove = function(event) { if (document.body.scrollHeight == document.body.clientHeight) event.preventDefault(); }</script>"];
  [s appendFormat:@"</head><body style=\"font-family:helvetica;font-size:%dpxbackground-color:transparent;color:%@\">", fontSize, [Colors htmlColorCode:[Colors lightText]]];
  [s appendFormat:@"<p><center><b>%@</b><br/>", a.stringAttractionName];
  [s appendFormat:@"<img src=\"%@\" width=\"%d\" height=\"%d\"></center></p><p>", [a imageName:parkId], imgSize, imgSize];
  [s appendString:NSLocalizedString(@"rating.comments.history", nil)];
  [s appendString:[parkData getCommentsHistory:attractionId]];
  [s appendString:@"</p></body></html>"];
  NSURL *baseURL = [NSURL fileURLWithPath:[MenuData parkDataPath:parkId]];
  commentsTextView.text = @"";
  webView.opaque = NO;
  webView.backgroundColor = [UIColor clearColor];
  [webView loadHTMLString:s baseURL:baseURL];
  [s release];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  titleNavigationItem.rightBarButtonItem.title = NSLocalizedString(@"save", nil);
  saveButton = [titleNavigationItem.rightBarButtonItem retain];
  titleNavigationItem.rightBarButtonItem = nil;
  ratingLabel.textColor = [Colors lightText];
  ratingLabel.text = NSLocalizedString(@"rating.rating", nil);
  commentLabel.textColor = [Colors lightText];
  commentLabel.text = NSLocalizedString(@"rating.comment", nil);
  [ratingView setForegroundImage:[UIImage imageNamed:@"thumbs_up.png"]];
  [ratingView setBackgroundImage:nil];
  ratingView.backgroundColor = [Colors darkBlue];
  commentsTextView.backgroundColor = [Colors lightBlue];
  [self updateData];
}

-(BOOL)shouldAutorotate {
  UIInterfaceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
  SettingsData *settings = [SettingsData getSettingsData];
  if ([settings isPortraitScreen]) return (interfaceOrientation == UIInterfaceOrientationPortrait);
  return ([settings isLeftHandedLandscapeScreen])? (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) : (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  SettingsData *settings = [SettingsData getSettingsData];
  if ([settings isPortraitScreen]) return UIInterfaceOrientationPortrait;
  if ([settings isLeftHandedLandscapeScreen]) return UIInterfaceOrientationLandscapeLeft;
  return UIInterfaceOrientationLandscapeRight;
}

#pragma mark -
#pragma mark Actions

-(IBAction)decreaseRating:(id)sender {
  [commentsTextView resignFirstResponder];
  int r = [ratingView getRating];
  if (r > 0) [ratingView setRating:(r-1)];
}

-(IBAction)increaseRating:(id)sender {
  [commentsTextView resignFirstResponder];
  int r = [ratingView getRating];
  if (r < 5) [ratingView setRating:(r+1)];
}

-(IBAction)loadBackView:(id)sender {
  if (sender != nil) {
    if ([commentsTextView.text length] > 0) {
      UIAlertView *alertDialog = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"save", nil)
                                  message:NSLocalizedString(@"rating.save", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"no", nil)
                                  otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
      [alertDialog show];
      [alertDialog release];
      return;
    }
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData setPersonalRating:[ratingView getRating] attractionId:attractionId];
    [parkData save:NO];
  }
  if ([delegate isKindOfClass:[TourViewController class]]) {
    TourViewController *controller = (TourViewController *)delegate;
    [controller updateViewValues:0.0 enableScroll:NO];
  }
  webView.delegate = nil;
	[delegate dismissModalViewControllerAnimated:(sender != nil)];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"MENU_ATTRACTION_RATING"];
  NSString *title = [helpData.titles objectForKey:@"MENU_ATTRACTION_RATING"]; 
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)detailsView:(id)sender {
  if (titleNavigationItem.rightBarButtonItem != nil) {
    [commentsTextView resignFirstResponder];
    if ([commentsTextView.text length] > 0) {
      ParkData *parkData = [ParkData getParkData:parkId];
      [parkData setPersonalRating:[ratingView getRating] attractionId:attractionId];
      [parkData addComment:commentsTextView.text attractionId:attractionId];
      [parkData save:NO];
      [self updateData];
    }
  }
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if ([buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData setPersonalRating:[ratingView getRating] attractionId:attractionId];
    [parkData addComment:commentsTextView.text attractionId:attractionId];
    [parkData save:NO];
  }
  [self loadBackView:nil];
}

#pragma mark -
#pragma mark Text view delegate

-(void)textViewDidBeginEditing:(UITextView *)textView {
  titleNavigationItem.rightBarButtonItem = saveButton;
}

-(void)textViewDidEndEditing:(UITextView *)textView {
  titleNavigationItem.rightBarButtonItem = nil;
}

-(void)textViewDidChange:(UITextView *)textView {
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  helpButton = nil;
  webView = nil;
  ratingLabel = nil;
  commentLabel = nil;
  ratingView = nil;
  commentsTextView = nil;
}

-(void)dealloc {
  [saveButton release];
  saveButton = nil;
  [topNavigationBar release];
  [titleNavigationItem release];
  [helpButton release];
  [webView release];
  [ratingLabel release];
  [commentLabel release];
  [ratingView release];
  [commentsTextView release];
  [super dealloc];
}

@end
