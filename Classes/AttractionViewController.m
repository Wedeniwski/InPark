//
//  AttractionViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "AttractionViewController.h"
#import "AttractionListViewController.h"
#import "AttractionRouteViewController.h"
#import "NavigationViewController.h"
#import "TourViewController.h"
#import "ParkMainMenuViewController.h"
#import "ParkingViewController.h"
#import "GeneralInfoViewController.h"
#import "RatingViewController.h"
#import "CalendarViewController.h"
#import "TutorialViewController.h"
#import "WaitTimeOverviewViewController.h"
#import "PathesViewController.h"
#import "IPadHelper.h"
#import "SettingsData.h"
#import "ParkData.h"
#import "ImageData.h"
#import "MenuData.h"
#import "TourData.h"
#import "TourItem.h"
#import "Categories.h"
#import "HelpData.h"
#import "Conversions.h"
#import "Colors.h"

@implementation AttractionViewController

static Attraction *selectedAttraction = nil;
static NSDate *selectedDate = nil;
static NSString *parkId = nil;

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize addToTourButtonItem;
@synthesize helpButton;
@synthesize favoriteView, closedView;
@synthesize closedLabel, copyrightLabel;
@synthesize informationControl;
@synthesize enableAddToTour, enableWalkToAttraction, enableViewAllPicturesButton, enableViewOnMap, enableWaitTime;
@synthesize webView;
@synthesize actionsTable;
@synthesize allPicturesButton;
@synthesize tourCount;
@synthesize selectedTourItemIndex;
@synthesize viewAllPicturesView;
@synthesize prepAllPicturesWaitView;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner attraction:(Attraction *)attraction parkId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    // Custom initialization
    delegate = owner;
    [selectedAttraction release];
    selectedAttraction = [attraction retain];
    [selectedDate release];
    selectedDate = nil;
    [parkId release];
    parkId = [pId retain];
    currentDistance = nil;
    enableAddToTour = (PATHES_EDITION == nil);
    enableWalkToAttraction = (PATHES_EDITION == nil);
    enableViewAllPicturesButton = (PATHES_EDITION == nil);
    enableViewOnMap = YES;
    enableWaitTime = YES;
    tourCount = -1;
    selectedTourItemIndex = -1;
  }
  return self;
}

-(void)setSelectedDate:(NSDate *)newSelectedDate {
  [selectedDate release];
  selectedDate = [newSelectedDate retain];
}

-(void)updateTourCount:(int)tCount {
  tourCount = tCount;
  [actionsTable reloadData];
}

-(void)refreshAvailableUpdates:(NSDictionary *)localData {
  if (PATHES_EDITION != nil) return;  // because of performance
  if (localData == nil) {
    [localImageData release];
    localImageData = [[ImageData localData] retain];
  }
  int numberOfChangingImages = 0;
  NSMutableArray *changes = [[NSMutableArray alloc] initWithCapacity:5];
  [ImageData availableChangesOfParkId:parkId attractionId:selectedAttraction.attractionId betweenLocalData:localImageData andAvailableData:[ImageData availableDataForParkId:parkId reload:NO] resultingChanges:changes numberOfChangingImages:&numberOfChangingImages];
  [changes release];
  if (updatesBadge != nil) {
    [updatesBadge removeFromSuperview];
    [updatesBadge release];
    updatesBadge = nil;
  }
  if (numberOfChangingImages > 0) {
    CoverFlowItemView *cover = [viewAllPicturesView selectedCoverflowView];
    updatesBadge = [[CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d", numberOfChangingImages]] retain];
    updatesBadge.frame = CGRectMake(favoriteView.frame.size.width, 0.0f, updatesBadge.frame.size.width, updatesBadge.frame.size.height);
    [cover addSubview:updatesBadge];
  }
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  informationControl.tintColor = [Colors darkBlue];
  if (PATHES_EDITION == nil) [helpButton setImage:[UIImage imageNamed:@"small_help.png"] forState:UIControlStateNormal];
  helpButton.hidden = (PATHES_EDITION != nil);
  favoriteView.hidden = YES;
  CALayer *layer = [webView layer];
  [layer setCornerRadius:15];
  webView.hidden = NO;
  webView.opaque = NO;
  webView.backgroundColor = [Colors lightBlue];
  webView.clipsToBounds = YES;
  webView.scrollView.delegate = self;
  [layer setBorderColor:[[Colors darkBlue] CGColor]];
  [layer setBorderWidth:5.0f];
  SettingsData *settings = [SettingsData getSettingsData];
  enableWaitTime = (settings.waitingTimesUpdate >= 0);
  BOOL isPortraitScreen = [settings isPortraitScreen];
  CGRect r = [[UIScreen mainScreen] bounds];
  float height = (isPortraitScreen)? r.size.height : r.size.width;
  float width = (isPortraitScreen)? r.size.width : r.size.height;
  BOOL iPad = [IPadHelper isIPad];
  float imageWidth = (iPad)? 600.0f : 200.0f;
  if (isPortraitScreen) {
    float flowViewHight = (iPad)? 750.0f : 233.0f;
    viewAllPicturesView.autoresizingMask = UIViewAutoresizingNone;
    r = viewAllPicturesView.frame;
    viewAllPicturesView.frame = CGRectMake(0.0f, r.origin.y, width, flowViewHight);
    informationControl.autoresizingMask = UIViewAutoresizingNone;
    r = informationControl.frame;
    float yOffset = (iPad)? 90.0f : 27.0f;
    informationControl.frame = CGRectMake(0.0f, viewAllPicturesView.frame.origin.y+flowViewHight-yOffset, width, r.size.height);
    webView.autoresizingMask = UIViewAutoresizingNone;
    //r = webView.frame;
    webView.frame = CGRectMake(0.0f, informationControl.frame.origin.y+informationControl.frame.size.height, width, height-(informationControl.frame.origin.y+informationControl.frame.size.height)-20.0f);
    actionsTable.autoresizingMask = UIViewAutoresizingNone;
    //r = actionsTable.frame;
    actionsTable.frame = webView.frame;
  } else {
    float flowViewHight = (iPad)? 750.0f : 233.0f;
    r = viewAllPicturesView.frame;
    viewAllPicturesView.autoresizingMask = UIViewAutoresizingNone;
    viewAllPicturesView.frame = CGRectMake(0.0f, r.origin.y+23.0f, flowViewHight, flowViewHight);
    r = prepAllPicturesWaitView.frame;
    prepAllPicturesWaitView.autoresizingMask = UIViewAutoresizingNone;
    prepAllPicturesWaitView.frame = CGRectMake(flowViewHight/2, r.origin.y, r.size.width, r.size.height);
    r = closedView.frame;
    r.origin.y = height-1.5f*r.size.height-3;
    if (!iPad) {
      r.size.height /= 2;
      r.size.width /= 2;
      r.origin.y += r.size.height;
    }
    closedView.autoresizingMask = UIViewAutoresizingNone;
    closedView.frame = r;
    r = closedLabel.frame;
    r.origin.x += closedView.frame.origin.x+closedView.frame.size.width;
    r.origin.y = height-1.5*closedView.frame.size.height;
    if (!iPad) r.origin.y -= closedView.frame.size.height;
    closedLabel.autoresizingMask = UIViewAutoresizingNone;
    closedLabel.frame = r;
    float posX = viewAllPicturesView.frame.origin.x + viewAllPicturesView.frame.size.width + 2.0f;
    float posY = viewAllPicturesView.frame.origin.y - 23.0f;
    informationControl.autoresizingMask = UIViewAutoresizingNone;
    r = informationControl.frame;
    informationControl.frame = CGRectMake(posX, posY, width-posX, r.size.height);
    //r = webView.frame;
    webView.autoresizingMask = UIViewAutoresizingNone;
    webView.frame = CGRectMake(posX, posY+informationControl.frame.size.height-3.0f, width-posX, height-(posY+informationControl.frame.size.height-3.0f)-20.0f);
    //r = actionsTable.frame;
    actionsTable.autoresizingMask = UIViewAutoresizingNone;
    actionsTable.frame = webView.frame;
    r = allPicturesButton.frame;
    allPicturesButton.autoresizingMask = UIViewAutoresizingNone;
    allPicturesButton.frame = CGRectMake((informationControl.frame.origin.x-r.size.width)*0.75f, r.origin.y, r.size.width, r.size.height);
  }
  /*if (height < 400.0f) {
    CGRect r = informationControl.frame;
    informationControl.frame = CGRectMake(r.origin.x, r.origin.y-80.0f, r.size.width, r.size.height);
    r = viewAllPicturesView.frame;
    viewAllPicturesView.frame = CGRectMake(r.origin.x+40.0f, r.origin.y, r.size.width-80.0f, r.size.height-80.0f);
    r = viewAllPicturesButton.frame;
    viewAllPicturesButton.frame = CGRectMake(r.origin.x+40.0f, r.origin.y, r.size.width-80.0f, r.size.height-80.0f);
    r = webView.frame;
    webView.frame = CGRectMake(r.origin.x, r.origin.y-80.0f, r.size.width, r.size.height+80.0f);
    r = actionsTable.frame;
    actionsTable.frame = CGRectMake(r.origin.x, r.origin.y-80.0f, r.size.width, r.size.height+80.0f);
    actionsTable.scrollEnabled = YES;
  } else {
    actionsTable.scrollEnabled = NO;
  }*/
  [informationControl removeAllSegments];
  [informationControl insertSegmentWithTitle:NSLocalizedString(@"attraction.details.info", nil) atIndex:0 animated:NO];
  [informationControl insertSegmentWithTitle:NSLocalizedString(@"attraction.details.further.info", nil) atIndex:1 animated:NO];
  if ([actionsTable numberOfRowsInSection:0] > 0) {
    [informationControl insertSegmentWithTitle:NSLocalizedString(@"attraction.details.actions", nil) atIndex:2 animated:NO];
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    tourCount = [tourData getAttractionCount:selectedAttraction.attractionId];
  }
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  imageCopyright = [[[selectedAttraction getAttractionDetails:parkId cache:YES] objectForKey:@"Bild-Copyright"] retain];  
  /*BOOL additionalPhotos = (enableViewAllPicturesButton && (imageCopyright == nil || [imageCopyright length] == 0) && [settings additionalPhotosEnabled] && selectedAttraction.additionalPhotosAvailable);
  viewAllPicturesView.hidden = additionalPhotos;
  viewAllPicturesButton.hidden = !additionalPhotos;*/
  [prepAllPicturesWaitView stopAnimating];
  //prepAllPicturesWaitView.hidden = YES;
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
  titleLabel.backgroundColor = [UIColor clearColor];
  titleLabel.numberOfLines = 2;
  titleLabel.adjustsFontSizeToFitWidth = YES;
  titleLabel.minimumFontSize = 14.0f;
  titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
  titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  titleLabel.textAlignment = UITextAlignmentCenter;
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.text = selectedAttraction.stringAttractionName;
  titleNavigationItem.titleView = titleLabel;
  //self.navigationItem.titleView = titleLabel;
  [titleLabel release];
  ParkData *parkData = [ParkData getParkData:parkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  if ([selectedAttraction isClosed:parkId] || [waitingTimeData isClosed:selectedAttraction.attractionId considerCalendar:YES]) {
    closedView.hidden = NO;
    closedLabel.hidden = NO;
    closedLabel.textColor = [Colors lightText];
    closedLabel.text = NSLocalizedString(@"attraction.details.closed", nil);
    //[s appendFormat:@"<table><tr><td><img src=\"closed.png\" width=\"19\" height=\"19\"></td><td><b style=\"color:#FF0000\">%@</b></td></tr></table>", NSLocalizedString(@"attraction.details.closed", nil)];
  } else {
    closedView.hidden = YES;
    closedLabel.hidden = YES;
  }
  copyrightLabel.textColor = [Colors lightText];
  copyrightLabel.lineBreakMode = UILineBreakModeWordWrap;
  copyrightLabel.numberOfLines = 2;
  if (imageCopyright != nil) copyrightLabel.text = imageCopyright;
  else copyrightLabel.text = @"";
  if (isPortraitScreen) {
    copyrightLabel.frame = CGRectMake(viewAllPicturesView.frame.origin.x, viewAllPicturesView.frame.origin.y-3, copyrightLabel.frame.size.height, copyrightLabel.frame.size.height);
    copyrightLabel.transform = CGAffineTransformMakeRotation(-90.0f * M_PI / 180.0f);
    float h = (iPad)? 108.0f : 28.0f;
    copyrightLabel.frame = CGRectMake(36.0f, viewAllPicturesView.frame.origin.y-h, copyrightLabel.frame.size.height, viewAllPicturesView.frame.size.height-6);
  } else {
    copyrightLabel.frame = CGRectMake(viewAllPicturesView.frame.origin.x+100.0f, height-copyrightLabel.frame.size.height-25.0f, viewAllPicturesView.frame.size.width, copyrightLabel.frame.size.height);
  }
  localImageData = nil; //[[ImageData localData] retain];
  viewAllPicturesView.dataSource = self;
  viewAllPicturesView.coverflowDelegate = self;
  viewAllPicturesView.coverSize = CGSizeMake(imageWidth, imageWidth);
  viewAllPicturesView.numberOfCovers = 0;
  if (PATHES_EDITION == nil) [allPicturesButton setImage:[UIImage imageNamed:@"list.png"] forState:UIControlStateNormal];
  allPicturesButton.hidden = (PATHES_EDITION != nil);
  [localImageData release];
  localImageData = [[ImageData localData] retain];
  allImages = [[ImageData allImagePathesForParkId:parkId attractionId:selectedAttraction.attractionId data:localImageData] retain];
  viewAllPicturesView.numberOfCovers = [allImages count];
  CoverFlowItemView *cover = [viewAllPicturesView selectedCoverflowView];
  favoriteView.frame = CGRectMake(cover.frame.origin.x, viewAllPicturesView.frame.origin.y, favoriteView.frame.size.width, favoriteView.frame.size.height);
  [self refreshAvailableUpdates:localImageData];
  actionsTable.hidden = YES;
  actionsTable.backgroundColor = [Colors darkBlue];
  actionsTable.backgroundView = nil;
  //[actionsTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[actionsTable numberOfRowsInSection:0]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
  actionsTable.scrollEnabled = ([self tableView:actionsTable numberOfRowsInSection:0] > 3);
  [self.view bringSubviewToFront:informationControl];
  informationControl.selectedSegmentIndex = 0;
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
  }
  //[self updateDetailView:self];
  [self performSelector:@selector(updateDetailView:) withObject:self afterDelay:0.1];
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
#pragma mark Cover Flow view delegate

-(void)coverflowView:(CoverFlowView *)coverflow selectionDidChange:(int)index {
}

-(void)coverflowView:(CoverFlowView *)coverflow didSelectAtIndex:(int)index {
  if (!prepAllPicturesWaitView.hidden) return;
  static CGRect originalCoverFlowFrame;
  static CGRect originalFrame;
  static CGRect originalImageFrame;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.7];
  if (topNavigationBar.alpha == 0) {
    [self.view bringSubviewToFront:informationControl];
    topNavigationBar.alpha = 1.0;
    helpButton.alpha = 1.0;
    closedView.alpha = 1.0;
    closedLabel.alpha = 1.0;
    favoriteView.alpha = 1.0;
    copyrightLabel.alpha = 1.0;
    informationControl.alpha = 1.0;
    webView.alpha = 1.0;
    actionsTable.alpha = 1.0;
    allPicturesButton.alpha = 1.0;
    updatesBadge.alpha = 1.0;
    CoverFlowItemView *cover = [viewAllPicturesView selectedCoverflowView];
    cover.frame = originalFrame;
    cover.imageView.imageView.frame = originalImageFrame;
    viewAllPicturesView.layoutEnabled = YES;
    viewAllPicturesView.scrollEnabled = YES;
    viewAllPicturesView.frame = originalCoverFlowFrame;
    prepAllPicturesWaitView.alpha = 1.0;
  } else {
    [self.view sendSubviewToBack:informationControl];
    SettingsData *settings = [SettingsData getSettingsData];
    BOOL isPortraitScreen = [settings isPortraitScreen];
    CGRect r = [[UIScreen mainScreen] bounds];
    float height = (isPortraitScreen)? r.size.height : r.size.width-20.0f;
    float width = (isPortraitScreen)? r.size.width : r.size.height;
    topNavigationBar.alpha = 0;
    helpButton.alpha = 0;
    closedView.alpha = 0;
    closedLabel.alpha = 0;
    favoriteView.alpha = 0;
    copyrightLabel.alpha = 0;
    informationControl.alpha = 0;
    webView.alpha = 0;
    actionsTable.alpha = 0;
    allPicturesButton.alpha = 0;
    updatesBadge.alpha = 0;
    originalCoverFlowFrame = viewAllPicturesView.frame;
    viewAllPicturesView.layoutEnabled = NO;
    float deltaY = (isPortraitScreen)? 0.0f : topNavigationBar.frame.size.height+23.0f;
    float deltaX = viewAllPicturesView.coverSpacing*index;
    viewAllPicturesView.frame = CGRectMake(viewAllPicturesView.frame.origin.x, viewAllPicturesView.frame.origin.y-deltaY, width, height);
    if (viewAllPicturesView.currentIndex != index) viewAllPicturesView.currentIndex = index;
    CoverFlowItemView *cover = [viewAllPicturesView selectedCoverflowView];
    originalFrame = cover.frame;
    originalImageFrame = cover.imageView.imageView.frame;
    if ((width <= height && originalImageFrame.size.width <= originalImageFrame.size.height) || (width >= height && originalImageFrame.size.width >= originalImageFrame.size.height)) {
      float w = MIN(width/originalImageFrame.size.width, height/originalImageFrame.size.height);
      height = w*originalImageFrame.size.height;
      width = w*originalImageFrame.size.width;
    } else {
      float w = MIN(height, width)/MAX(originalImageFrame.size.width, originalImageFrame.size.height);
      height = w*originalImageFrame.size.height;
      width = w*originalImageFrame.size.width;
    }
    cover.imageView.imageView.frame = CGRectMake(0.0f, 0.0f, width, height);
    cover.frame = CGRectMake(deltaX, 0.0f, width, height);
    viewAllPicturesView.scrollEnabled = NO;
    prepAllPicturesWaitView.alpha = 0;
  }
  [UIView commitAnimations];
}

#pragma mark -
#pragma mark Cover Flow view data source

-(CoverFlowItemView *)coverflowView:(CoverFlowView *)coverflow atIndex:(int)index {
	CoverFlowItemView *cover = [coverflow dequeueReusableCoverView];
	if (cover == nil) {
		float f = coverflow.coverSize.width;
		cover = [[[CoverFlowItemView alloc] initWithFrame:CGRectMake(0, 0, f, f)] autorelease];
	}
  if (allImages == nil) {
    [cover setImagePath:[selectedAttraction imagePath:parkId]];
  } else {
    [cover setImagePath:[allImages objectAtIndex:index]];
    NSArray *images = [ImageData imageProperiesForParkId:parkId attractionId:selectedAttraction.attractionId data:localImageData];
    if ((images == nil && index > 0) || (images != nil && index >= [images count])) {
      UIButton *deleteImageButton = [[[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 27.0f, 27.0f)] autorelease];
      [deleteImageButton setImage:[UIImage imageNamed:@"closed.png"] forState:UIControlStateNormal];
      [deleteImageButton addTarget:self action:@selector(deleteUserImage:) forControlEvents:UIControlEventTouchUpInside];
      deleteImageButton.tag = index;
      [cover addSubview:deleteImageButton];
    } else {
      for (id subView in cover.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
          UIButton *button = (UIButton *)subView;
          [button removeFromSuperview];
        }
      }
    }
  }
	return cover;
}

#pragma mark -
#pragma mark Update delegate

-(void)enableViewController:(BOOL)enable {
  if (enable) {
    [prepAllPicturesWaitView startAnimating];
    informationControl.enabled = NO;
    informationControl.alpha = 0.5f;
    titleNavigationItem.leftBarButtonItem.enabled = NO;
    allPicturesButton.enabled = NO;
    allPicturesButton.alpha = 0.5f;
    actionsTable.alpha = 0.5f;
    [actionsTable reloadData];
  } else {
    [prepAllPicturesWaitView stopAnimating];
    actionsTable.alpha = 1.0f;
    [actionsTable reloadData];
    informationControl.enabled = YES;
    informationControl.alpha = 1.0f;
    titleNavigationItem.leftBarButtonItem.enabled = YES;
    allPicturesButton.enabled = YES;
    allPicturesButton.alpha = 1.0f;
  }
}

-(void)updateStatusGUI:(NSArray *)args {
  NSString *status = [args objectAtIndex:0];
  double percentage = [[args objectAtIndex:1] doubleValue];
  if (percentage < 0.0 || percentage == 1.0) {
    if (percentage <= -1.0) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"error", nil)
                             message:status
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
    } else {
      [localImageData release];
      localImageData = [[ImageData localData] retain];
      [allImages release];
      allImages = [[ImageData allImagePathesForParkId:parkId attractionId:selectedAttraction.attractionId data:localImageData] retain];
      viewAllPicturesView.numberOfCovers = [allImages count]; //viewAllPicturesView.tag;
    }
    [self refreshAvailableUpdates:nil];
    [self enableViewController:NO];
  }
}

-(void)status:(NSString *)status percentage:(double)percentage {
  NSNumber *n = [[NSNumber alloc] initWithDouble:percentage];
  NSArray *args = [[NSArray alloc] initWithObjects:status, n, nil];
  [self performSelectorOnMainThread:@selector(updateStatusGUI:) withObject:args waitUntilDone:NO];
}

-(void)downloaded:(NSString *)number {
}

#pragma mark -
#pragma mark Web view delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  /*if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
    imageSmall = !imageSmall;
    [self updateDetailView];
  }*/
  return YES;
}

static int scrollPosition = 0;
-(void)webViewDidFinishLoad:(UIWebView *)wView {
  if (scrollPosition != 0) {
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollTo(0, %d);", scrollPosition]];
    scrollPosition = 0;
  }
}

#pragma mark -
#pragma mark Scroll view delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollPosition != 0) {
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollTo(0, %d);", scrollPosition]];
    scrollPosition = 0;
  }
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  int n = 1;
  if (enableAddToTour) ++n;
  if (enableWalkToAttraction) ++n;
  if (enableViewOnMap) ++n;
  if (updatesBadge != nil) ++n;
  if (enableWaitTime && selectedAttraction.waiting) ++n;
  if (PATHES_EDITION == nil) ++n;
  if (enableViewAllPicturesButton && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) ++n;
  if (enableViewAllPicturesButton && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) ++n;
  return n;
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"AttractionActionsCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.textColor = [Colors lightText];
    cell.backgroundColor = [Colors lightBlue];
    cell.imageView.transform = CGAffineTransformMakeScale(0.5, 0.5);
  }
  int row = indexPath.row;
  if (row >= 0 && !enableAddToTour) ++row;
  if (row >= 1 && !enableWalkToAttraction) ++row;
  if (row >= 2 && !enableViewOnMap) ++row;
  if (row >= 3 && updatesBadge == nil) ++row;
  if (row >= 4 && (!enableWaitTime || !selectedAttraction.waiting)) ++row;
  if (row >= 6 && PATHES_EDITION != nil) ++row;
  if (row >= 7 && !(enableViewAllPicturesButton && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])) ++row;
  if (row >= 8 && !(enableViewAllPicturesButton && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])) return nil;
  switch (row) {
    case 0: {
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      SettingsData *settings = [SettingsData getSettingsData];
      BOOL canAddToTour = (tourCount < settings.maxNumberOfSameAttractionInTour && [tourData canAddToTour:selectedAttraction.attractionId]);
      cell.selectionStyle = (canAddToTour)? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
      cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.textLabel.numberOfLines = 1;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.add.to.tour", nil);
      cell.textLabel.enabled = canAddToTour;
      cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0f];
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d x %@", tourCount, NSLocalizedString(@"attraction.details.in.tour", nil)];
      cell.detailTextLabel.enabled = canAddToTour;
      cell.imageView.image = [UIImage imageNamed:@"add.png"];
      cell.imageView.alpha = (canAddToTour)? 1.0 : 0.5;
      break;
    }
    case 1: {
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      SettingsData *settings = [SettingsData getSettingsData];
      BOOL canAddToTour = (tourCount < settings.maxNumberOfSameAttractionInTour && [tourData canAddToTour:selectedAttraction.attractionId]);
      cell.selectionStyle = (canAddToTour)? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
      cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.textLabel.numberOfLines = 1;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.directly.go.there", nil);
      cell.textLabel.enabled = canAddToTour;
      cell.detailTextLabel.font = [UIFont systemFontOfSize:10.0f];
      cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.detailTextLabel.numberOfLines = 2;
      cell.detailTextLabel.text = NSLocalizedString(@"attraction.details.directly.go.there.details", nil);
      cell.detailTextLabel.enabled = canAddToTour;
      cell.imageView.image = [UIImage imageNamed:@"tour.png"];
      cell.imageView.alpha = (canAddToTour)? 1.0 : 0.5;
      break;
    }
    case 2:
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.show.on.map", nil);
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"map.png"];
      cell.imageView.alpha = 1.0;
      break;
    case 3:
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      NSString *s = [updatesBadge.badgeText isEqualToString:@"1"]? NSLocalizedString(@"attraction.details.download", nil) : NSLocalizedString(@"attraction.details.downloads", nil);
      cell.textLabel.text = [NSString stringWithFormat:s, updatesBadge.badgeText];
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"download.png"];
      cell.imageView.alpha = 1.0;
      break;
    case 4:
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.wait.time", nil);
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"clock.png"];
      cell.imageView.alpha = 1.0;
      break;
    case 5: {
      ParkData *parkData = [ParkData getParkData:parkId];
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      if ([parkData isFavorite:selectedAttraction.attractionId]) cell.textLabel.text = NSLocalizedString(@"attraction.details.remove.from.favorite", nil);
      else cell.textLabel.text = NSLocalizedString(@"attraction.details.add.to.favorite", nil);
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"bookmark.png"];
      cell.imageView.alpha = 1.0;
      break;
    }
    case 6:
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.rating", nil);
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"rating.png"];
      cell.imageView.alpha = 1.0;
      break;
    case 7:
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.own.photo", nil);
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"photos.png"];
      cell.imageView.alpha = 1.0;
      break;
    case 8:
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 2;
      cell.textLabel.text = NSLocalizedString(@"attraction.details.take.picture", nil);
      cell.textLabel.enabled = YES;
      cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.detailTextLabel.numberOfLines = 1;
      cell.detailTextLabel.text = nil;
      cell.imageView.image = [UIImage imageNamed:@"camera.png"];
      cell.imageView.alpha = 1.0;
      break;
    default:
      break;
  }
  //cell.alpha = (prepAllPicturesWaitView.hidden)? 1.0 : 0.5;
  //NSLog(@"cell.alpha: %f", cell.alpha);
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 57.0;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!prepAllPicturesWaitView.hidden) return nil;
  int row = indexPath.row;
  if (enableAddToTour && row == 0) {
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    SettingsData *settings = [SettingsData getSettingsData];
    BOOL canAddToTour = (tourCount < settings.maxNumberOfSameAttractionInTour && [tourData canAddToTour:selectedAttraction.attractionId]);
    if (!canAddToTour) return nil;
  }
  return indexPath;
}

static UIPopoverController *popover = nil;

-(void)updateImages {
  if (PARK_ID_EDITION != nil) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"attraction.details.update.images.title", nil)
                           message:NSLocalizedString(@"attraction.details.update.images", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    [self enableViewController:NO];
  } else {
    NSMutableArray *changes = [[NSMutableArray alloc] initWithCapacity:5];
    int numberOfChangingImages = 0;
    int size = [ImageData availableChangesOfParkId:parkId attractionId:selectedAttraction.attractionId betweenLocalData:localImageData andAvailableData:[ImageData availableDataForParkId:parkId reload:NO] resultingChanges:changes numberOfChangingImages:&numberOfChangingImages];
    Update *update = [[Update alloc] initWithImageArray:changes size:size numberOfImages:numberOfChangingImages parkId:parkId owner:self];
    [update update];
    [update release];
    [changes release];
  }
}

-(void)addImageFromPhotoLibrary {
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.wantsFullScreenLayout = YES;
  //picker.allowsEditing = YES;
  BOOL iPad = [IPadHelper isIPad];
  if (iPad) {
    popover = [[UIPopoverController alloc] initWithContentViewController:picker];
    popover.delegate = self;
    [popover presentPopoverFromRect:topNavigationBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  } else {
    [self presentViewController:picker animated:YES completion:nil];
  }
  [picker release];
  [self enableViewController:NO];
}

-(void)addImageFromCamera {
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:picker animated:YES completion:nil];
  [picker release];
  [self enableViewController:NO];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  int row = indexPath.row;
  if (row >= 0 && !enableAddToTour) ++row;
  if (row >= 1 && !enableWalkToAttraction) ++row;
  if (row >= 2 && !enableViewOnMap) ++row;
  if (row >= 3 && updatesBadge == nil) ++row;
  if (row >= 4 && (!enableWaitTime || !selectedAttraction.waiting)) ++row;
  if (row >= 6 && PATHES_EDITION != nil) ++row;
  if (row >= 7 && !(enableViewAllPicturesButton && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])) ++row;
  if (row >= 8 && !(enableViewAllPicturesButton && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])) return;
  switch (row) {
    case 0:
      [self addToTour:self];
      break;
    case 1:
      [self walkToAttraction:self];
      break;
    case 2:
      [self viewOnMap:self];
      break;
    case 3:
      [self enableViewController:YES];
      [self performSelector:@selector(updateImages) withObject:nil afterDelay:0.05];
      break;
    case 4:
      [self waitTime:self];
      break;
    case 5:
      [self favorites:self];
      break;
    case 6:
      [self rating:self];
      break;
    case 7: {
      if (popover != nil) {
        [popover dismissPopoverAnimated:YES];
        [popover release];
        popover = nil;
      }
      [self enableViewController:YES];
      [self performSelector:@selector(addImageFromPhotoLibrary) withObject:nil afterDelay:0.05];
      break;
    }
    case 8: {
      [self enableViewController:YES];
      [self performSelector:@selector(addImageFromCamera) withObject:nil afterDelay:0.05];
      break;
    }
    default:
      break;
  }
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark Image Picker delegate

//-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
//}

//-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
//}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  if (popover != nil) {
    [popover dismissPopoverAnimated:YES];
    [popover release];
    popover = nil;
  } else {
    [picker dismissViewControllerAnimated:YES completion:nil];
  }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *path = [ImageData userImagesDataPath];
  double time = [[NSDate date] timeIntervalSince1970];
  NSString *myImagePath = [NSString stringWithFormat:@"%@/%@/%@/%f.jpg", path, parkId, selectedAttraction.attractionId, time];
  [MenuData ensurePathStructure:[NSArray arrayWithObjects:parkId, selectedAttraction.attractionId, nil] toBase:path];
  UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
  [UIImageJPEGRepresentation(image, 0.9f) writeToFile:myImagePath atomically:YES];
  [AsynchronousImageView ensureSmallImageCreatedFor:image atPath:myImagePath];
  [allImages release];
  allImages = [[ImageData allImagePathesForParkId:parkId attractionId:selectedAttraction.attractionId data:localImageData] retain];
  viewAllPicturesView.numberOfCovers = [allImages count];
  //wrong: [ImageData updateLocalDataWithAvailableDataOfParkId:parkId attractionId:selectedAttraction.attractionId];
  [self refreshAvailableUpdates:nil];
  [pool release];
  [self imagePickerControllerDidCancel:picker];
}

/*-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  if (error != nil) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"error", nil)
                           message:status@"Unable to save image to Photo Album."
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
}*/

#pragma mark -
#pragma mark Actions

-(IBAction)updateDetailView:(id)sender {
  ParkData *parkData = [ParkData getParkData:parkId];
  favoriteView.hidden = ![parkData isFavorite:selectedAttraction.attractionId];
  [actionsTable reloadData];
  BOOL iPad = [IPadHelper isIPad];
  int fontSize = (iPad)? 14 : 12;
  NSString *textColorCode = [Colors htmlColorCode:[Colors lightText]];
  NSMutableString *s = [[NSMutableString alloc] initWithCapacity:10000];
  [s appendFormat:@"<html><head><style type=\"text/css\">table {width:100%%;display:inline;font-family:helvetica;font-size:%dpx;background-color:transparent;color:%@}</style>", fontSize, textColorCode];
  [s appendFormat:@"</head><body style=\"font-family:helvetica;font-size:%dpx;background-color:transparent;color:%@\">", fontSize, [Colors htmlColorCode:[Colors hilightText]]];
  int idx = informationControl.selectedSegmentIndex;
  if (idx == 0) {
    webView.hidden = NO;
    actionsTable.hidden = YES;
    [s appendString:@"<center><table>"];
    Categories *categories = [Categories getCategories];
    NSArray *categoryNames = [categories getCategoryNames:selectedAttraction.typeId];
    if (categoryNames != nil) {
      int l = [categoryNames count];
      if (l == 1) {
        NSString *c = [categoryNames objectAtIndex:0];
        if (![c isEqualToString:selectedAttraction.typeName]) [s appendFormat:@"<tr><td valign=\"top\"><b>%@:</b>&nbsp;&nbsp;</td><td><b>%@</b></td></tr>", NSLocalizedString(@"attraction.details.category", nil), c];
      } else if (l > 1) {
        [s appendFormat:@"<tr><td valign=\"top\"><b>%@:</b>&nbsp;&nbsp;</td><td><b>%@", NSLocalizedString(@"attraction.details.category", nil), [categoryNames objectAtIndex:0]];
        for (int i = 1; i < l; ++i) {
          [s appendString:@" / "];
          [s appendString:[categoryNames objectAtIndex:i]];
        }
        [s appendString:@"</b></td></tr>"];
      }
    }
    NSString *t = selectedAttraction.typeName;
    if ([t length] > 0) [s appendFormat:@"<tr><td><b>%@:</b>&nbsp;&nbsp;</td><td><b>%@</b></td></tr>", NSLocalizedString(@"attraction.details.type", nil), t];
    NSDictionary *attractionDetails = [selectedAttraction getAttractionDetails:parkId cache:YES];
    t = [MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails];
    if ([t length] > 0) [s appendFormat:@"<tr><td><b>%@:</b>&nbsp;&nbsp;</td><td><b>%@</b></td></tr>", NSLocalizedString(@"attraction.details.themeArea", nil), t];
    [s appendFormat:@"</table></center><span style=\"font-size:%dpx\"><hr>%@</span></body></html>", fontSize, [MenuData objectForKey:ATTRACTION_DESCRIPTION at:attractionDetails]];
  } else if (idx == 1) {
    webView.hidden = NO;
    actionsTable.hidden = YES;
    [s appendString:@"<table>"];
    ParkData *parkData = [ParkData getParkData:parkId];
    BOOL hasTimes = NO;
    BOOL hasDining = NO;
    if ([parkData isEntryOrExitOfPark:selectedAttraction.attractionId]) {
      NSString *startingAndEndTimes = [selectedAttraction startingAndEndTimes:parkId forDate:selectedDate maxTimes:-1];
      if (startingAndEndTimes != nil) {
        startingAndEndTimes = [selectedAttraction moreSpaceStartingAndEndTimes:startingAndEndTimes];
        [s appendFormat:@"<tr><td nowrap valign=\"top\">%@<sup>*</sup>:</td><td>%@</td></tr>", NSLocalizedString(@"attraction.details.opening.end.times", nil), startingAndEndTimes];
        hasTimes = YES;
      }
    } else if (![selectedAttraction needToAttendAtOpeningTime:parkId forDate:selectedDate]) {
      NSString *startingAndEndTimes = [selectedAttraction startingAndEndTimes:parkId forDate:selectedDate maxTimes:-1];
      if (startingAndEndTimes != nil) {
        if ([startingAndEndTimes isEqualToString:NSLocalizedString(@"attraction.today.closed", nil)] || [startingAndEndTimes isEqualToString:NSLocalizedString(@"wait.times.overview.unknown", nil)]) {
          [s appendFormat:@"<tr><td nowrap valign=\"top\">%@<sup>*</sup>:</td><td>%@</td></tr>", NSLocalizedString(@"attraction.details.opening.end.times", nil), startingAndEndTimes];
        } else {
          startingAndEndTimes = [selectedAttraction moreSpaceStartingAndEndTimes:startingAndEndTimes];
          [s appendFormat:@"<tr><td nowrap valign=\"top\">%@<sup>*</sup>:</td><td>%@</td></tr>", NSLocalizedString(@"attraction.details.times.continuously", nil), startingAndEndTimes];
        }
        hasTimes = YES;
      }
    } else {
      BOOL hasMoreThanOneTime = NO;
      NSString *startingTimes = [selectedAttraction startingTimes:parkId forDate:selectedDate onlyNext4Times:NO hasMoreThanOneTime:&hasMoreThanOneTime];
      if (startingTimes != nil) {
        [s appendFormat:@"<tr><td nowrap valign=\"top\">%@<sup>*</sup>:</td><td>%@</td></tr>",  ((hasMoreThanOneTime)? NSLocalizedString(@"attraction.details.opening.times", nil) : NSLocalizedString(@"attraction.details.opening.time", nil)), startingTimes];
        hasTimes = YES;
      }
    }
    if ([selectedAttraction isTrain]) {
      if (selectedAttraction.duration > 0) {
        [s appendFormat:@"<tr><td valign=\"top\">%@:</td><td>", NSLocalizedString(@"attraction.details.train.duration", nil)];
        [s appendFormat:NSLocalizedString(@"attraction.details.duration.format", nil), selectedAttraction.duration];
        [s appendString:@"</td></tr>"];
      }
      NSArray *nextStations = [parkData getNextTrainStationAttractions:selectedAttraction];
      //Attraction *nextStation = [Attraction getAttraction:parkId attractionId:selectedAttraction.nextStationId];
      if (nextStations != nil) {
        [s appendFormat:@"<tr><td nowrap valign=\"top\">%@:</td><td>", NSLocalizedString(@"attraction.details.next.station", nil)];
        BOOL first = YES;
        for (Attraction *nextStation in nextStations) {
          if (!first) [s appendString:@"<br/>"];
          [s appendString:nextStation.stringAttractionName];
          first = NO;
        }
        [s appendString:@"</td></tr>"];
      }
    } else if (selectedAttraction.duration > 0) {
      [s appendFormat:@"<tr><td nowrap valign=\"top\">%@:</td><td>", NSLocalizedString(@"attraction.details.duration", nil)];
      [s appendFormat:NSLocalizedString(@"attraction.details.duration.format", nil), selectedAttraction.duration];
      [s appendString:@"</td></tr>"];
    }
    NSDictionary *attractionDetails = [selectedAttraction getAttractionDetails:parkId cache:YES];
    if ([selectedAttraction isDining]) {
      [s appendString:@"<tr><td nowrap valign=\"top\">"];
      [s appendString:NSLocalizedString(@"attraction.details.meals", nil)];
      [s appendString:@"<sup>*</sup>:</td><td>"];
      NSNumber *n = [attractionDetails objectForKey:@"Breakfast"];
      if (n != nil && [n boolValue]) {
        [s appendString:NSLocalizedString(@"attraction.details.meals.breakfast", nil)];
        hasDining = YES;
      }
      n = [attractionDetails objectForKey:@"Lunch"];
      if (n != nil && [n boolValue]) {
        if (hasDining) [s appendString:@", "];
        [s appendString:NSLocalizedString(@"attraction.details.meals.lunch", nil)];
        hasDining = YES;
      }
      n = [attractionDetails objectForKey:@"Dinner"];
      if (n != nil && [n boolValue]) {
        if (hasDining) [s appendString:@", "];
        [s appendString:NSLocalizedString(@"attraction.details.meals.dinner", nil)];
        hasDining = YES;
      }
      n = [attractionDetails objectForKey:@"Snacks"];
      if (n != nil && [n boolValue]) {
        if (hasDining) [s appendString:@", "];
        [s appendString:NSLocalizedString(@"attraction.details.meals.snacks", nil)];
        hasDining = YES;
      }
      if (!hasDining) [s appendString:@"?"];
      [s appendString:@"</td></tr>"];
      n = [attractionDetails objectForKey:@"Reservation"];
      if (hasDining && n != nil && [n boolValue]) [s appendFormat:@"<tr><td nowrap valign=\"top\">%@:</td><td>%@</td></tr>", NSLocalizedString(@"attraction.details.dining.reservations", nil), NSLocalizedString(@"attraction.details.dining.reservations.recommended", nil)];
      hasDining = NO;
      [s appendString:@"<tr><td nowrap valign=\"top\">"];
      [s appendString:NSLocalizedString(@"attraction.details.dining.type", nil)];
      [s appendString:@"<sup>*</sup>:</td><td>"];
      n = [attractionDetails objectForKey:@"Table"];
      if (n != nil && [n boolValue]) {
        [s appendString:NSLocalizedString(@"attraction.details.dining.type.table", nil)];
        hasDining = YES;
      }
      n = [attractionDetails objectForKey:@"Counter"];
      if (n != nil && [n boolValue]) {
        if (hasDining) [s appendString:@", "];
        [s appendString:NSLocalizedString(@"attraction.details.dining.type.counter", nil)];
        hasDining = YES;
      }
      n = [attractionDetails objectForKey:@"Buffet"];
      if (n != nil && [n boolValue]) {
        if (hasDining) [s appendString:@", "];
        [s appendString:NSLocalizedString(@"attraction.details.dining.type.buffet", nil)];
        hasDining = YES;
      }
      n = [attractionDetails objectForKey:@"Booth"];
      if (n != nil && [n boolValue]) {
        if (hasDining) [s appendString:@", "];
        [s appendString:NSLocalizedString(@"attraction.details.dining.type.booth", nil)];
        hasDining = YES;
      }
      if (!hasDining) [s appendString:@"?"];
      n = [attractionDetails objectForKey:@"Character"];
      if (n != nil && [n boolValue]) {
        [s appendString:@"</td></tr><tr><td></td><td>"];
        [s appendString:NSLocalizedString(@"attraction.details.dining.type.character", nil)];
      }
      hasDining = YES;
      [s appendString:@"</td></tr>"];
    }
    if (closedView.hidden && [selectedAttraction isRealAttraction]) {
      if (selectedAttraction.waiting && !hasTimes && ![selectedAttraction isTrain]) {
        WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
        TourItem *tourItem = [[TourItem alloc] initWithAttractionId:selectedAttraction.attractionId entry:nil exit:nil];
        if ([selectedAttraction isTrain]) {
          tourItem.isWaitingTimeAvailable = YES;
          tourItem.isWaitingTimeUnknown = NO;
          tourItem.waitingTime = selectedAttraction.defaultWaiting;
        } else {
          WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:tourItem.attractionId];
          tourItem.isWaitingTimeAvailable = (waitingTimeItem != nil);
          tourItem.isWaitingTimeUnknown = (waitingTimeItem == nil);
          tourItem.waitingTime = (waitingTimeItem == nil)? 0 : [waitingTimeItem totalWaitingTime];
        }
        NSString *waitingTime = [waitingTimeData setLabel:nil forTourItem:tourItem color:NO extendedFormat:NO];
        NSString *waitingTimeColor = [waitingTimeData colorCodeForTourItem:tourItem];
        [s appendFormat:@"<tr><td nowrap valign=\"top\">%@:</td><td", NSLocalizedString(@"waiting.time", nil)];
        if (waitingTimeColor != nil) [s appendFormat:@" style=\"color:#%@\"", waitingTimeColor];
        [s appendString:@">"];
        [s appendString:waitingTime];
        [s appendString:@"</td></tr>"];
        [tourItem release];
      }
      if (parkData.fastLaneId != nil && selectedAttraction.fastLaneDefined) {
        NSString *t = nil;
        WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
        WaitingTimeItem *waitingTime = [waitingTimeData getWaitingTimeFor:selectedAttraction.attractionId];
        if (waitingTime != nil && waitingTime.fastLaneInfoAvailable) {
          if (waitingTime.fastLaneAvailable > 0) t = NSLocalizedString(@"attraction.details.fastpass.available", nil);
          else if (waitingTime.fastLaneAvailable < 0) t = NSLocalizedString(@"attraction.details.fastpass.limited_availability", nil);
          else t = NSLocalizedString(@"attraction.details.fastpass.unavailable", nil);
        } else {
          t = (selectedAttraction.fastLane)? NSLocalizedString(@"attraction.details.fastpass", nil) : [NSString stringWithFormat:NSLocalizedString(@"attraction.details.fastpass.no", nil), parkData.fastLaneId];
        }
        [s appendFormat:@"<tr><td nowrap valign=\"top\">%@:</td><td>%@</td></tr>", parkData.fastLaneId, t];
      }
    }
    double d;
    [currentDistance release];
    currentDistance = [getCurrentDistance(parkId, selectedAttraction.attractionId, &d) retain];
    if ([currentDistance length] > 0) {
      [s appendFormat:@"<tr><td nowrap valign=\"top\">%@:</td><td>%@</td></tr>", NSLocalizedString(@"distance", nil), currentDistance];
    }
    [s appendString:@"<tr><td colspan=\"2\"><img src=\"water.png\" width=\"0\" height=\"3\" border=\"0\"></td></tr>"];
    int rating = [parkData getPersonalRating:selectedAttraction.attractionId];
    if (rating > 0) {
      [s appendString:@"<tr><td nowrap valign=\"top\">"];
      [s appendString:NSLocalizedString(@"attraction.details.rating.weight", nil)];
      [s appendString:@"</td><td>"];
      do {
        [s appendString:@"<img src=\"thumb_up.png\" width=\"8\" height=\"15\">&nbsp;"];
      } while (--rating > 0);
      [s appendString:@"</td></tr>"];
    }
    int thrillFactor, familyFactor, waterFactor;
    [selectedAttraction getThrillFactor:&thrillFactor familyFactor:&familyFactor waterFactor:&waterFactor];
    if (thrillFactor >= 0) {
      [s appendString:@"<tr><td nowrap valign=\"center\">"];
      [s appendString:NSLocalizedString(@"attraction.details.thrill.factor", nil)];
      [s appendString:@"</td><td>"];
      if (thrillFactor == 0) [s appendString:@"0"];
      else {
        do {
          [s appendString:@"<img src=\"star.png\" width=\"13\" height=\"12\">&nbsp;"];
        } while (--thrillFactor > 0);
      }
      [s appendString:@"</td></tr>"];
    }
    if (familyFactor >= 0) {
      [s appendString:@"<tr><td nowrap valign=\"center\">"];
      [s appendString:NSLocalizedString(@"attraction.details.family.factor", nil)];
      [s appendString:@"</td><td>"];
      if (familyFactor == 0) [s appendString:@"0"];
      else {
        do {
          [s appendString:@"<img src=\"family.png\" width=\"17\" height=\"12\">&nbsp;"];
        } while (--familyFactor > 0);
      }
      [s appendString:@"</td></tr>"];
    }
    if (waterFactor >= 0) {
      [s appendString:@"<tr><td nowrap valign=\"center\">"];
      [s appendString:NSLocalizedString(@"attraction.details.water.factor", nil)];
      [s appendString:@"</td><td>"];
      if (waterFactor == 0) [s appendString:@"0"];
      else {
        do {
          [s appendString:@"<img src=\"water.png\" width=\"18\" height=\"12\">&nbsp;"];
        } while (--waterFactor > 0);
      }
      [s appendString:@"</td></tr>"];
    }
    NSString *t = [selectedAttraction ageRestriction];
    if (t != nil) {
      [s appendString:@"<tr><td nowrap valign=\"top\">"];
      [s appendString:NSLocalizedString(@"attraction.details.age", nil)];
      [s appendString:@"</td><td>"];
      [s appendString:t];
      [s appendString:@"</td></tr>"];
    }
    t = [selectedAttraction heightRestriction];
    if (t != nil) {
      [s appendString:@"<tr><td nowrap valign=\"top\">"];
      [s appendString:NSLocalizedString(@"attraction.details.height", nil)];
      [s appendString:@"</td><td>"];
      [s appendString:t];
      [s appendString:@"</td></tr>"];
    }
    [s appendString:@"</table>"];
    NSNumber *n = [attractionDetails objectForKey:@"Zusatzkosten"];
    BOOL money = (n != nil && [n boolValue]);
    n = [attractionDetails objectForKey:@"Indoor"];
    BOOL roof = (n != nil && [n boolValue]);
    NSString *blueColorCode = [Colors htmlColorCode:[Colors darkBlue]];
    if (selectedAttraction.handicappedAccessible || selectedAttraction.winter || money || roof) {
      [s appendFormat:@"<hr style=\"border:none;height:1px;color:%@;background:%@\"/><center><table border=0 cellpadding=0>", blueColorCode, blueColorCode];
      if (money) {
        [s appendFormat:@"<tr><td valign=\"top\" align=\"right\"><img src=\"money.png\" width=\"20\" height=\"10\">&nbsp;&nbsp;</td><td valign=\"top\">%@</td></tr>", NSLocalizedString(@"attraction.info.money", nil)];
      }
      if (selectedAttraction.handicappedAccessible) {
        [s appendFormat:@"<tr><td valign=\"center\" align=\"right\"><img src=\"handicapped.png\" width=\"10\" height=\"12\">&nbsp;&nbsp;</td><td valign=\"center\">%@</td></tr>", NSLocalizedString(@"attraction.info.handicapped", nil)];
      }
      if (roof) {
        [s appendFormat:@"<tr><td valign=\"top\" align=\"right\"><img src=\"roof.png\" width=\"20\" height=\"10\">&nbsp;&nbsp;</td><td valign=\"top\">%@</td></tr>", [selectedAttraction isDining]? NSLocalizedString(@"attraction.info.dining.roof", nil) : NSLocalizedString(@"attraction.info.roof", nil)];
      }
      if (selectedAttraction.winter) {
        [s appendFormat:@"<tr><td valign=\"top\" align=\"right\" style=\"height:15px\"><img src=\"snow.png\" width=\"16\" height=\"15\">&nbsp;&nbsp;</td><td valign=\"top\">%@</td></tr>", NSLocalizedString(@"attraction.info.snow", nil)];
      }
      [s appendString:@"</table></center>"];
    }
    if (hasTimes || hasDining) [s appendFormat:@"<hr style=\"border:none;height:1px;color:%@;background:%@\"/>", blueColorCode, blueColorCode];
    if (hasTimes) [s appendFormat:@"<font color=\"%@\"><small><sup>*</sup>&nbsp;%@</small></font>", textColorCode, NSLocalizedString(@"attraction.info.showtimes.remark", nil)];
    if (hasDining) [s appendFormat:@"<font color=\"%@\"><small><sup>*</sup>&nbsp;%@</small></font>", textColorCode, NSLocalizedString(@"attraction.info.dining.remark", nil)];
    [s appendString:@"</body></html>"];
  } else {
    actionsTable.hidden = NO;
    webView.hidden = YES;
  }
  NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
  scrollPosition = [[webView stringByEvaluatingJavaScriptFromString: @"scrollY"] intValue];
  [webView loadHTMLString:s baseURL:baseURL];
  [s release];
}

-(IBAction)loadBackView:(id)sender {
  webView.delegate = nil;
  if ([LocationData isLocationDataInitialized]) {
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
  }
	[delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"MENU_ATTRACTION"];
  NSString *title = [helpData.titles objectForKey:@"MENU_ATTRACTION"];
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)addToTour:(id)sender {
  if ([delegate isKindOfClass:[AttractionListViewController class]]) {
    AttractionListViewController *controller = delegate;
    [controller addToTour:selectedTourItemIndex target:self];
  }
}

-(void)addAttractionAtBeginning:(NSString *)exitId {
  NSString *attractionId = selectedAttraction.attractionId;
  ParkData *parkData = [ParkData getParkData:parkId];
  if (exitId == nil) exitId = [parkData getRootAttractionId:[parkData exitAttractionIdOf:attractionId]];
  else exitId = [parkData getRootAttractionId:[parkData exitAttractionIdOf:exitId]];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  TourItem *t = [[TourItem alloc] initWithAttractionId:attractionId entry:[parkData firstEntryAttractionIdOf:attractionId] exit:exitId];
  [tourData insertAfterFirstDone:t startTime:[[NSDate date] timeIntervalSince1970]];
  [t release];
  [tourData dontAskNextTimeForTourOptimization];
  tourData.askTourOptimizationAfterNextSwitchDone = YES;
  id owner = delegate;
  [owner dismissModalViewControllerAnimated:NO];
  while (owner != nil) {
    if ([owner isKindOfClass:[AttractionListViewController class]]) {
      AttractionListViewController *controller = (AttractionListViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[NavigationViewController class]]) {
      NavigationViewController *controller = (NavigationViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[ParkingViewController class]]) {
      ParkingViewController *controller = (ParkingViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[TourViewController class]]) {
      TourViewController *controller = (TourViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[RatingViewController class]]) {
      RatingViewController *controller = (RatingViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[CalendarViewController class]]) {
      CalendarViewController *controller = (CalendarViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[PathesViewController class]]) {
      PathesViewController *controller = (PathesViewController *)owner;
      owner = controller.delegate;
      [controller loadBackView:nil];
    } else if ([owner isKindOfClass:[ParkMainMenuViewController class]]) {
      ParkMainMenuViewController *controller = (ParkMainMenuViewController *)owner;
      [controller performSelector:@selector(tourView:) withObject:nil afterDelay:0.1];
      //[controller tourView:nil];
      break;
    } else {
      break;
    }
  }
}

-(IBAction)walkToAttraction:(id)sender {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  NSString *attractionId = selectedAttraction.attractionId;
  if ([tourData canAddToTour:attractionId]) {
    if ([selectedAttraction isTrain]) {
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:NSLocalizedString(@"tour.add.train.destination.title", nil)
                              delegate:self
                              cancelButtonTitle:nil
                              destructiveButtonTitle:nil
                              otherButtonTitles:nil];
      BOOL oneWay;
      NSArray *trainRouteForSelection = [parkData getTrainAttractionRoute:attractionId oneWay:&oneWay];
      for (Attraction *station in trainRouteForSelection) {
        [sheet addButtonWithTitle:station.stringAttractionName];
      }
      [sheet showInView:self.view];
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
    } else {
      [self addAttractionAtBeginning:nil];
    }
  }
}

-(IBAction)viewOnMap:(id)sender {
  AttractionRouteViewController *controller = [[AttractionRouteViewController alloc] initWithNibName:@"AttractionRouteView" owner:self parkId:parkId attractionId:selectedAttraction.attractionId];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

/*-(void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
  if (data == nil) {
    data = [[NSMutableData alloc] initWithCapacity:MAX([incrementalData length], 4096)];
  }
  [data appendData:incrementalData];
}

-(void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error {
  NSLog(@"more photos download failed (%@)", [error localizedDescription]);
  [data release];
  data = nil;
  [connection release];
  connection = nil;
  viewAllPicturesView.hidden = NO;
  viewAllPicturesButton.hidden = YES;
  selectedAttraction.additionalPhotosAvailable = NO;
  copyrightLabel.text = @"";
  [prepAllPicturesWaitView stopAnimating];
  //prepAllPicturesWaitView.hidden = YES;
  UIAlertView *dialog = [[UIAlertView alloc]
                         initWithTitle:NSLocalizedString(@"attraction.details.view.picture.error.title", nil)
                         message:NSLocalizedString(@"attraction.details.view.picture.error", nil)
                         delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"ok", nil)
                         otherButtonTitles:nil];
  [dialog show];
  [dialog release];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
  viewAllPicturesView.hidden = NO;
  viewAllPicturesButton.hidden = YES;
  selectedAttraction.additionalPhotosAvailable = NO;
  copyrightLabel.text = @"";
  if (data != nil) {
    NSString *allPictureNames = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *picturePrefix = [NSString stringWithFormat:@"%@ - %@ ", parkId, selectedAttraction.attractionId];
    if ([allPictureNames hasPrefix:picturePrefix]) {
      NSArray *images = [allPictureNames componentsSeparatedByString:@"\n"];
      if (images != nil) {
        int l = [images count];
        if (l > 0) {
          NSMutableString *s = [[NSMutableString alloc] initWithCapacity:1000];
          int j = 1;
          for (int i = 0; i < l; ++i) {
            NSString *imageName = [images objectAtIndex:i];
            if ([imageName hasPrefix:picturePrefix]) {
              int imgSize = ([IPadHelper isIPad])? 600: 300;
              [s appendFormat:@"<h1><a name=\"%d\">%@ %d</a></h1><p><center><img src=\"%@%@/%@/%@\" width=\"%d\" height=\"%d\"></center></p>",
               j, NSLocalizedString(@"attraction.details.view.picture", nil), j, [Update sourceDataPath], parkId, selectedAttraction.attractionId, imageName, imgSize, imgSize];
              ++j;
            }
          }
          HelpData *helpData = [[HelpData alloc] initWithContent:s];
          TutorialViewController *controller = [[TutorialViewController alloc] initWithNibName:@"TutorialView" owner:self helpData:helpData];
          controller.navigationTitle = selectedAttraction.stringAttractionName;
          if (l > 1) {
            controller.thumbnailIndex = YES;
            controller.startHtmlAnchor = @"0";
          } else {
            controller.startHtmlAnchor = @"1";
          }
          [self presentModalViewController:controller animated:YES];
          [controller release];
          [helpData release];
          [s release];
          viewAllPicturesView.hidden = YES;
          viewAllPicturesButton.hidden = NO;
          selectedAttraction.additionalPhotosAvailable = YES;
          copyrightLabel.text = NSLocalizedString(@"attraction.details.additional.photos", nil);
        }
      }
    }
    [allPictureNames release];
    [data release];
    data = nil;
  }
  [connection release];
  connection = nil;
  if (!selectedAttraction.additionalPhotosAvailable) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"attraction.details.view.picture.error.title", nil)
                           message:NSLocalizedString(@"attraction.details.view.picture.error", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
}
*/

-(IBAction)viewAllPictures:(id)sender {
  NSMutableString *s = [[NSMutableString alloc] initWithCapacity:1000];
  int j = 1;
  int imgSize = ([IPadHelper isIPad])? 600: 300;
  for (NSString *imagePath in allImages) {
    NSString *path = [AsynchronousImageView smallImagePathFor:imagePath];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    float f = imgSize/MAX(image.size.width, image.size.height);
    [s appendFormat:@"<h1><a name=\"%d\">%@ %d</a></h1><p><center><img src=\"%@\" width=\"%d\" height=\"%d\"></center></p>", j, NSLocalizedString(@"attraction.details.view.picture", nil), j, path, (int)(image.size.width*f), (int)(image.size.height*f)];
    [image release];
    ++j;
  }
  HelpData *helpData = [[HelpData alloc] initWithContent:s];
  TutorialViewController *controller = [[TutorialViewController alloc] initWithNibName:@"TutorialView" owner:self helpData:helpData];
  controller.navigationTitle = selectedAttraction.stringAttractionName;
  if ([allImages count] > 1) {
    controller.thumbnailIndex = YES;
    controller.startHtmlAnchor = @"0";
  } else {
    controller.startHtmlAnchor = @"1";
  }
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
  [helpData release];
  [s release];
}

-(IBAction)waitTime:(id)sender {
  WaitTimeOverviewViewController *controller = [[WaitTimeOverviewViewController alloc] initWithNibName:@"WaitTimeOverviewView" owner:self parkId:parkId attractionId:selectedAttraction.attractionId];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(IBAction)favorites:(id)sender {
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([parkData isFavorite:selectedAttraction.attractionId]) [parkData removeFavorite:selectedAttraction.attractionId];
  else [parkData addFavorite:selectedAttraction.attractionId];
  [self updateDetailView:sender];
}

-(IBAction)rating:(id)sender {
  RatingViewController *controller = [[RatingViewController alloc] initWithNibName:@"RatingView" owner:self parkId:parkId attractionId:selectedAttraction.attractionId];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(IBAction)deleteUserImage:(id)sender {
  if ([sender isKindOfClass:[UIButton class]]) {
    UIButton *button = (UIButton *)sender;
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"attraction.details.delete.own.photo.title", nil)
                           message:NSLocalizedString(@"attraction.details.delete.own.photo", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"no", nil)
                           otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
    dialog.tag = button.tag;
    [dialog show];
    [dialog release];
  }
}

#pragma mark -
#pragma mark Location data delegate

-(void)didUpdateLocationData {
  if (informationControl.selectedSegmentIndex == 1) {
    if (currentDistance == nil) [self updateDetailView:nil];
    else {
      double d;
      NSString *dist = getCurrentDistance(parkId, selectedAttraction.attractionId, &d);
      if (![dist isEqualToString:currentDistance]) [self updateDetailView:nil];
      // no update of waiting time if distance is not changing (probability is too low)
    }
  }
}

-(void)didUpdateLocationError {
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if ([buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
    NSArray *images = [ImageData imageProperiesForParkId:parkId attractionId:selectedAttraction.attractionId data:localImageData];
    if (alertView.tag < [allImages count] && ((images != nil && alertView.tag >= [images count]) || (images == nil && alertView.tag > 0))) {
      [ImageData deleteUserImage:[allImages objectAtIndex:alertView.tag]];
      [allImages release];
      allImages = [[ImageData allImagePathesForParkId:parkId attractionId:selectedAttraction.attractionId data:localImageData] retain];
      int currentIndex = viewAllPicturesView.currentIndex;
      if (currentIndex >= [allImages count]) --currentIndex;
      viewAllPicturesView.numberOfCovers = [allImages count];
      if (topNavigationBar.alpha == 0) { // large picture
        [self coverflowView:viewAllPicturesView didSelectAtIndex:currentIndex];
      }
      viewAllPicturesView.currentIndex = currentIndex;
      [self refreshAvailableUpdates:nil];
    }
  }
}

#pragma mark -
#pragma mark Action sheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  const char *buttonTitle = [[actionSheet buttonTitleAtIndex:buttonIndex] UTF8String];
  ParkData *parkData = [ParkData getParkData:parkId];
  BOOL oneWay;
  NSArray *trainRouteForSelection = [parkData getTrainAttractionRoute:selectedAttraction.attractionId oneWay:&oneWay];
  for (Attraction *station in trainRouteForSelection) {
    if (strcmp(station.attractionName, buttonTitle) == 0) {
      [self addAttractionAtBeginning:station.attractionId];
      break;
    }
  }
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
  /*selectedAttraction = nil;
  selectedDate = nil;*/
  topNavigationBar = nil;
  titleNavigationItem = nil;
  addToTourButtonItem = nil;
  helpButton = nil;
  favoriteView = nil;
  closedView = nil;
  closedLabel = nil;
  copyrightLabel = nil;
  informationControl = nil;
  webView = nil;
  actionsTable = nil;
  allPicturesButton = nil;
  viewAllPicturesView = nil;
  prepAllPicturesWaitView = nil;
}

-(void)dealloc {
  /*[selectedAttraction release];
  [selectedDate release];
  [parkId release];*/
  [localImageData release];
  [currentDistance release];
  currentDistance = nil;
  [allImages release];
  [imageCopyright release];
  [topNavigationBar release];
  [titleNavigationItem release];
  [addToTourButtonItem release];
  [helpButton release];
  [favoriteView release];
  [closedView release];
  [closedLabel release];
  [copyrightLabel release];
  [informationControl release];
  [webView release];
  [actionsTable release];
  [allPicturesButton release];
  [viewAllPicturesView release];
  [prepAllPicturesWaitView release];
  [updatesBadge removeFromSuperview];
  [updatesBadge release];
  updatesBadge = nil;
  [super dealloc];
}

@end
