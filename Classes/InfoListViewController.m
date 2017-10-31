//
//  InfoListViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "InfoListViewController.h"
#import "GeneralInfoViewController.h"
#import "SettingsData.h"
#import "Colors.h"

@implementation InfoListViewController

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize infoTableView;

#pragma mark -
#pragma mark - View lifecycle

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(@"pathes.more.inpark", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  infoTableView.backgroundColor = [Colors darkBlue];
  infoTableView.backgroundView = nil;
  infoTableView.rowHeight = 106;
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

-(IBAction)loadBackView:(id)sender {
	[delegate dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark table view data source methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 5;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.row >= 3)? 40.0f : tableView.rowHeight;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"InfoListCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.detailTextLabel.textColor = [Colors lightText];
    cell.backgroundColor = [Colors lightBlue];
    //cell.imageView.transform = CGAffineTransformIdentity;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  cell.imageView.layer.masksToBounds = YES;
  cell.imageView.layer.cornerRadius = 7.0;
  cell.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
  cell.imageView.layer.borderWidth = 2.0;
  float n = tableView.rowHeight-6;
  CGRect r = cell.imageView.frame;
  cell.imageView.frame = CGRectMake(r.origin.x, r.origin.y, n, n);
  switch (indexPath.row) {
    case 0:
      cell.imageView.image = [UIImage imageNamed:@"inpark@2x.png"];
      cell.textLabel.text = NSLocalizedString(@"inpark.full", nil);
      break;
    case 1:
      cell.imageView.image = [UIImage imageNamed:@"facebook_logo.png"];
      cell.textLabel.text = NSLocalizedString(@"inpark.more", nil);
      break;
    case 2:
      cell.imageView.image = [UIImage imageNamed:@"best_inpark.png"];
      cell.textLabel.text = NSLocalizedString(@"inpark.best", nil);
      break;
    case 3:
      cell.imageView.image = nil;
      cell.textLabel.text = NSLocalizedString(@"tutorial.title", nil);
      break;
    default:
      cell.imageView.image = nil;
      cell.textLabel.text = NSLocalizedString(@"about.title", nil);
      break;
  }
  if (indexPath.row < 3) {
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator.png"]];
    cell.accessoryView = indicatorView;
    [indicatorView release];
  }
  return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  GeneralInfoViewController *controller;
  switch (indexPath.row) {
    case 0:
      controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"inpark_full.txt" title:@"inpark.full"];
      break;
    case 1:
      controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"inpark_more.txt" title:@"inpark.more"];
      break;
    case 2:
      controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"inpark_best.txt" title:@"inpark.best"];
      break;
    case 3:
      [self loadBackView:self];
      [delegate performSelector:@selector(showTutorial) withObject:nil afterDelay:0.3];
      return;
    default:
      controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"about.txt" title:@"about.title"];
      break;
  }
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentModalViewController:controller animated:YES];
  [controller release];  
  [infoTableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark Memory Management Methods

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  infoTableView = nil;
}

-(void)dealloc {
  [topNavigationBar release];
  [titleNavigationItem release];
  [infoTableView release];
  [super dealloc];
}

@end
