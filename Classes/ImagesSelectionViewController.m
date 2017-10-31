//
//  ImagesSelectionViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 18.09.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ImagesSelectionViewController.h"
#import "Attraction.h"
#import "AQGridViewCell.h"
#import "MenuData.h"
#import "ImageData.h"
#import "SettingsData.h"
#import "AsynchronousImageView.h"
#import "CustomBadge.h"
#import "Colors.h"

@interface ImageCell : AQGridViewCell {
  AsynchronousImageView *imageView;
  UITextView *title;
  CustomBadge *numberOfImages;
}
@property (nonatomic, readonly) AsynchronousImageView *imageView;
@property (nonatomic, retain) UITextView *title;
@property (nonatomic, retain) CustomBadge *numberOfImages;
@end

@implementation ImageCell
@synthesize imageView, title, numberOfImages;

-(id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)aReuseIdentifier {
  self = [super initWithFrame:frame reuseIdentifier:aReuseIdentifier];
  if (self != nil) {
    CGRect r = CGRectMake(frame.origin.x+5.0f, frame.origin.y+20.0f, frame.size.width-10.0f, frame.size.width-10.0f);
    imageView = [[AsynchronousImageView alloc] initWithFrame:r];
    [imageView setBorderWidth:2.0f];
    r = CGRectMake(frame.origin.x+10.0f, frame.origin.y, frame.size.width-20.0f, 20.0f);
    title = [[UITextView alloc] initWithFrame:r];
    title.font = [UIFont boldSystemFontOfSize:12.0];
    title.textColor = [Colors lightText];
    //title.scrollEnabled = NO;
    //title.highlightedTextColor = [UIColor whiteColor];
    //title.adjustsFontSizeToFitWidth = YES;
    //title.minimumFontSize = 10.0;
    self.backgroundColor = [Colors darkBlue];
    self.contentView.backgroundColor = self.backgroundColor;
    imageView.backgroundColor = self.backgroundColor;
    title.backgroundColor = [Colors lightBlue];
    numberOfImages = [[CustomBadge customBadgeWithString:@"1"] retain];
    r = numberOfImages.frame;
    numberOfImages.frame = CGRectMake(frame.origin.x, frame.origin.y+r.size.height/2, r.size.width, r.size.height);
    [self.contentView addSubview:imageView];
    [self.contentView addSubview:title];
    [self.contentView addSubview:numberOfImages];
  }
  return self;
}

-(void)dealloc {
  [imageView release];
  [title release];
  [numberOfImages release];
  [super dealloc];
}

-(void)layoutSubviews {
  [super layoutSubviews];
  CGSize imageSize = imageView.imageView.image.size;
  CGRect bounds = CGRectInset(self.contentView.bounds, 10.0, 10.0);
  [title sizeToFit];
  CGRect frame = title.frame;
  frame.size.height = 50.0f;
  //frame.size.width = MIN(frame.size.width, bounds.size.width);
  frame.origin.y = CGRectGetMaxY(bounds) - 40.0f;
  frame.origin.x = 5.0f+floorf((bounds.size.width - 200.0f) * 0.5);
  frame.size.width = 210.0f;
  title.frame = frame;
  // adjust the frame down for the image layout calculation
  bounds.size.height = frame.origin.y - bounds.origin.y;
  if (imageSize.width <= bounds.size.width && imageSize.height <= bounds.size.height) return;
  // scale it down to fit
  CGFloat ratio = MIN(bounds.size.height / imageSize.height, bounds.size.width / imageSize.width);
  [imageView sizeToFit];
  frame = imageView.frame;
  frame.size.width = floorf(imageSize.width * ratio);
  frame.size.height = floorf(imageSize.height * ratio);
  frame.origin.x = floorf((bounds.size.width - frame.size.width) * 0.5);
  frame.origin.y = floorf((bounds.size.height - frame.size.height) * 0.5);
  imageView.frame = frame;
  numberOfImages.frame = CGRectMake(frame.origin.x-numberOfImages.frame.size.width, frame.origin.y+numberOfImages.frame.size.height+5.0f, numberOfImages.frame.size.width, numberOfImages.frame.size.height);
}
@end

@interface TripleTextCell : AQGridViewCell {
  UILabel *titleName;
  UITextView *textName;
  UILabel *titleLocation;
  UITextView *textLocation;
  UILabel *titleDescription;
  UITextView *textDescription;
}
@property (nonatomic, retain) UILabel *titleName;
@property (nonatomic, retain) UITextView *textName;
@property (nonatomic, retain) UILabel *titleLocation;
@property (nonatomic, retain) UITextView *textLocation;
@property (nonatomic, retain) UILabel *titleDescription;
@property (nonatomic, retain) UITextView *textDescription;
@end

@implementation TripleTextCell
@synthesize titleName, textName, titleLocation, textLocation, titleDescription, textDescription;

-(id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)aReuseIdentifier {
  self = [super initWithFrame:frame reuseIdentifier:aReuseIdentifier];
  if (self != nil) {
    self.backgroundColor = [Colors darkBlue];
    self.contentView.backgroundColor = self.backgroundColor;
    CGRect r = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 20.0f);
    titleName = [[UILabel alloc] initWithFrame:r];
    titleName.font = [UIFont boldSystemFontOfSize:12.0];
    titleName.textColor = [Colors lightText];
    r = CGRectMake(frame.origin.x+5.0f, frame.origin.y+20.0f, frame.size.width-10.0f, 40.0f);
    textName = [[UITextView alloc] initWithFrame:r];
    textName.font = [UIFont boldSystemFontOfSize:12.0];
    textName.textColor = [Colors lightText];
    titleName.backgroundColor = self.backgroundColor;
    textName.backgroundColor = [Colors lightBlue];
    [self.contentView addSubview:titleName];
    [self.contentView addSubview:textName];

    r = CGRectMake(frame.origin.x, frame.origin.y+65.0f, frame.size.width, 20.0f);
    titleLocation = [[UILabel alloc] initWithFrame:r];
    titleLocation.font = [UIFont boldSystemFontOfSize:12.0];
    titleLocation.textColor = [Colors lightText];
    r = CGRectMake(frame.origin.x+5.0f, frame.origin.y+85.0f, frame.size.width-10.0f, 40.0f);
    textLocation = [[UITextView alloc] initWithFrame:r];
    textLocation.font = [UIFont boldSystemFontOfSize:12.0];
    textLocation.textColor = [Colors lightText];
    titleLocation.backgroundColor = self.backgroundColor;
    textLocation.backgroundColor = [Colors lightBlue];
    [self.contentView addSubview:titleLocation];
    [self.contentView addSubview:textLocation];

    r = CGRectMake(frame.origin.x, frame.origin.y+130.0f, frame.size.width, 20.0f);
    titleDescription = [[UILabel alloc] initWithFrame:r];
    titleDescription.font = [UIFont boldSystemFontOfSize:12.0];
    titleDescription.textColor = [Colors lightText];
    r = CGRectMake(frame.origin.x+5.0f, frame.origin.y+150.0f, frame.size.width-10.0f, frame.size.height-150.0f);
    textDescription = [[UITextView alloc] initWithFrame:r];
    textDescription.font = [UIFont boldSystemFontOfSize:12.0];
    textDescription.textColor = [Colors lightText];
    titleDescription.backgroundColor = self.backgroundColor;
    textDescription.backgroundColor = [Colors lightBlue];
    [self.contentView addSubview:titleDescription];
    [self.contentView addSubview:textDescription];
  }
  return self;
}

-(void)dealloc {
  [titleName release];
  [textName release];
  [titleLocation release];
  [textLocation release];
  [titleDescription release];
  [textDescription release];
  [super dealloc];
}
@end

@interface InternalImagesSelectionViewController : UIViewController <AQGridViewDelegate, AQGridViewDataSource> {
	id delegate;
  NSString *parkId;
  NSString *attractionId;
  NSArray *imagePathes;
  int attractionPos;

  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet AQGridView *gridView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId imagePathes:(NSArray *)pathes attractionPos:(int)aPos;

-(IBAction)loadBackView:(id)sender;
-(IBAction)cancel:(id)sender;

@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) AQGridView *gridView;

@end

@implementation InternalImagesSelectionViewController

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize gridView;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId imagePathes:(NSArray *)pathes attractionPos:(int)aPos {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    parkId = [pId retain];
    attractionId = [aId retain];
    imagePathes = [pathes retain];
    attractionPos = aPos;
  }
  return self;
}

#pragma mark -
#pragma mark View lifecycle

-(void)viewDidLoad {
  [super viewDidLoad];
  topNavigationBar.tintColor = [Colors darkBlue];
  self.view.backgroundColor = [Colors darkBlue];
  gridView.backgroundColor = [Colors darkBlue];
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  titleNavigationItem.title = attraction.stringAttractionName;
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"cancel", nil);
  titleNavigationItem.rightBarButtonItem = nil;
	gridView.delegate = self;
	gridView.dataSource = self;
  [gridView reloadData];
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  gridView = nil;
}

-(void)dealloc {
  [parkId release];
  parkId = nil;
  [attractionId release];
  attractionId = nil;
  [imagePathes release];
  imagePathes = nil;
  [topNavigationBar release];
  [titleNavigationItem release];
  [gridView release];
  [super dealloc];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  SettingsData *settings = [SettingsData getSettingsData];
  if ([settings isPortraitScreen]) return (interfaceOrientation == UIInterfaceOrientationPortrait);
  return ([settings isLeftHandedLandscapeScreen])? (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) : (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
	[delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)cancel:(id)sender {
  [self loadBackView:sender];
}

#pragma mark -
#pragma mark Grid View Data Source

-(NSUInteger)numberOfItemsInGridView:(AQGridView *)aGridView {
  return [imagePathes count];
}

-(AQGridViewCell *)gridView:(AQGridView *)aGridView cellForItemAtIndex:(NSUInteger)index {
  static NSString *FilledCellIdentifier = @"InternalImageCellIdentifier";
  ImageCell *cell = (ImageCell *)[aGridView dequeueReusableCellWithIdentifier:FilledCellIdentifier];
  if (cell == nil) {
    cell = [[[ImageCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0) reuseIdentifier:FilledCellIdentifier] autorelease];
    cell.selectionStyle = AQGridViewCellSelectionStyleBlueGray;
    cell.numberOfImages.hidden = YES;
    cell.title.hidden = YES;
  }
  [cell.imageView setImagePath:[imagePathes objectAtIndex:index]];
  return cell;
}

-(CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView {
  return CGSizeMake(200.0, 200.0);
}

#pragma mark -
#pragma mark Grid View Delegate

-(void)gridView:(AQGridView *)gView didSelectItemAtIndex:(NSUInteger)index {
  [delegate setImagePath:[imagePathes objectAtIndex:index] atIndex:attractionPos];
  [self loadBackView:self];
}

#pragma mark -
#pragma mark Memory Management

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end

#pragma mark -
#pragma mark Main Implementation

@implementation ImagesSelectionViewController

@synthesize canceled;
@synthesize titleName, location, description;
@synthesize information, imagePathes;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize gridView;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractions:(NSArray *)att titleName:(NSString *)tName location:(NSString *)loc description:(NSString *)text information:(NSArray *)info {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    canceled = NO;
    parkId = [pId retain];
    attractions = [att retain];
    titleName = [tName retain];
    location = [loc retain];
    description = [text retain];
    information = [[NSMutableArray alloc] initWithArray:info];
    imagePathes = [[NSMutableArray alloc] initWithCapacity:[att count]];
    localImageData = [[ImageData localData] retain];
    for (Attraction *attraction in attractions) {
      //[information addObject:attraction.stringAttractionName];
      NSArray *p = [ImageData allImagePathesForParkId:parkId attractionId:attraction.attractionId data:localImageData];
      [imagePathes addObject:[p objectAtIndex:0]];
    }
  }
  return self;
}

#pragma mark -
#pragma mark View lifecycle

-(void)viewDidLoad {
  [super viewDidLoad];
  topNavigationBar.tintColor = [Colors darkBlue];
  self.view.backgroundColor = [Colors darkBlue];
  gridView.backgroundColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(@"facebook.publish.title", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"publish", nil);
  titleNavigationItem.rightBarButtonItem.title = NSLocalizedString(@"cancel", nil);
	gridView.delegate = self;
	gridView.dataSource = self;
  //gridView.separatorStyle = AQGridViewCellSeparatorStyleSingleLine;
  //gridView.layoutDirection = AQGridViewLayoutDirectionVertical;
  [gridView reloadData];
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  gridView = nil;
}

-(void)dealloc {
  [titleName release];
  titleName = nil;
  [location release];
  location = nil;
  [description release];
  description = nil;
  [localImageData release];
  localImageData = nil;
  [information release];
  information = nil;
  [imagePathes release];
  imagePathes = nil;
  [titleNameTextView release];
  titleNameTextView = nil;
  [locationTextView release];
  locationTextView = nil;
  [descriptionTextView release];
  descriptionTextView = nil;
  [topNavigationBar release];
  [titleNavigationItem release];
  [gridView release];
  [parkId release];
  parkId = nil;
  [attractions release];
  attractions = nil;
  [super dealloc];
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

-(void)setImagePath:(NSString *)imagePath atIndex:(int)index {
  [imagePathes replaceObjectAtIndex:index withObject:imagePath];
  [gridView reloadData];
}

-(const char *)attractionNameAtIndex:(int)index {
  Attraction *attraction = [attractions objectAtIndex:index];
  return attraction.attractionName;
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
	[delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)cancel:(id)sender {
  canceled = YES;
  [information release];
  information = nil;
  [imagePathes release];
  imagePathes = nil;
  [self loadBackView:sender];
}

#pragma mark -
#pragma mark Grid View Data Source

-(NSUInteger)numberOfItemsInGridView:(AQGridView *)aGridView {
  return [attractions count]+1;
}

-(AQGridViewCell *)gridView:(AQGridView *)aGridView cellForItemAtIndex:(NSUInteger)index {
  if (index == 0) {
    static NSString *TripleTextCellIdentifier = @"TripleTextCellIdentifier";
    TripleTextCell *cell = (TripleTextCell *)[aGridView dequeueReusableCellWithIdentifier:TripleTextCellIdentifier];
    if (cell == nil) {
      cell = [[[TripleTextCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 265.0) reuseIdentifier:TripleTextCellIdentifier] autorelease];
      cell.selectionStyle = AQGridViewCellSelectionStyleNone;
    }
    cell.titleName.text = NSLocalizedString(@"facebook.albums.name.title", nil);
    cell.textName.text = titleName;
    cell.textName.tag = -1;
    cell.titleLocation.text = NSLocalizedString(@"facebook.albums.location.title", nil);
    cell.textLocation.text = location;
    cell.textLocation.tag = -2;
    cell.titleDescription.text = NSLocalizedString(@"facebook.albums.description.title", nil);
    cell.textDescription.text = description;
    cell.textDescription.tag = -3;
    return cell;
  } else {
    --index;
    static NSString *FilledCellIdentifier = @"ImageCellIdentifier";
    ImageCell *cell = (ImageCell *)[aGridView dequeueReusableCellWithIdentifier:FilledCellIdentifier];
    if (cell == nil) {
      cell = [[[ImageCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 265.0) reuseIdentifier:FilledCellIdentifier] autorelease];
      cell.title.delegate = self;
    }
    Attraction *attraction = [attractions objectAtIndex:index];
    NSArray *p = [ImageData allImagePathesForParkId:parkId attractionId:attraction.attractionId data:localImageData];
    int n = [p count];
    [cell.numberOfImages autoBadgeSizeWithString:[NSString stringWithFormat:@"%d", n]];
    cell.selectionStyle = AQGridViewCellSelectionStyleNone;
    //cell.selectionStyle = (n <= 1)? AQGridViewCellSelectionStyleNone : AQGridViewCellSelectionStyleBlueGray;
    [cell.imageView setImagePath:[imagePathes objectAtIndex:index]];
    cell.title.text = [information objectAtIndex:index];
    cell.title.tag = index;
    return cell;
  }
}

-(CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView {
  return CGSizeMake(200.0, 265.0);
}

#pragma mark -
#pragma mark Grid View Delegate

-(void)gridView:(AQGridView *)gView willDisplayCell:(AQGridViewCell *)cell forItemAtIndex:(NSUInteger)index {
  if (index == 0) {
    TripleTextCell *tCell = (TripleTextCell *)cell;
    [tCell.textName resignFirstResponder];
    [tCell.textLocation resignFirstResponder];
    [tCell.textDescription resignFirstResponder];
  } else {
    ImageCell *iCell = (ImageCell *)cell;
    [iCell.title resignFirstResponder];
  }
}

-(void)gridView:(AQGridView *)gView didSelectItemAtIndex:(NSUInteger)index {
  if (index > 0) {
    ImageCell *cell = (ImageCell *)[gView cellForItemAtIndex:index];
    [cell.title resignFirstResponder];
    Attraction *attraction = [attractions objectAtIndex:index-1];
    NSArray *p = [ImageData allImagePathesForParkId:parkId attractionId:attraction.attractionId data:localImageData];
    InternalImagesSelectionViewController *controller = [[InternalImagesSelectionViewController alloc] initWithNibName:@"ImagesSelectionView" owner:self parkId:parkId attractionId:attraction.attractionId imagePathes:p attractionPos:index-1];
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
  [gView deselectItemAtIndex:index animated:NO];
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
  int n = textView.tag;
  if (n+1 < [information count]) [gridView scrollToItemAtIndex:n+1 atScrollPosition:AQGridViewScrollPositionMiddle animated:YES];
  else {
    CGPoint bottomOffset = CGPointMake(0, [gridView contentSize].height-210.0f);
    [gridView setContentOffset:bottomOffset animated:YES];
  }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
  [textView resignFirstResponder];
}

-(void)textViewDidChange:(UITextView *)textView {
  if (textView.tag >= 0) [information replaceObjectAtIndex:textView.tag withObject:textView.text];
  else if (textView.tag == -1) {
    [titleName release];
    titleName = [textView.text retain];
  } else if (textView.tag == -2) {
    [location release];
    location = [textView.text retain];
  } else if (textView.tag == -3) {
    [description release];
    description = textView.text;
  }
}

#pragma mark -
#pragma mark Memory Management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc that aren't in use.
}

@end
