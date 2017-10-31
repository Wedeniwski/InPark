//
//  InParkViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.05.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "InParkViewController.h"
#import "ParkSelectionViewController.h"
#import "SettingsData.h"
#import "ParkData.h"
#import "Colors.h"

@implementation InParkViewController

@synthesize releaseNotesViewed;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self != nil) {
    releaseNotesViewed = NO;
  }
  return self;
}

-(IBAction)loadParkSelectionView:(id)sender {
	ParkSelectionViewController *controller = [[ParkSelectionViewController alloc] initWithNibName:@"ParkSelectionView"];
	[self presentViewController:controller animated:YES completion:nil];
	[controller release];
  while ([ParkData isAvailableUpdatesActive]) [NSThread sleepForTimeInterval:0.75];
}

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  [super dismissModalViewControllerAnimated:animated];
  [self performSelector:@selector(loadParkSelectionView:) withObject:self afterDelay:0.8];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
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

-(void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
}

-(void)dealloc {
  [super dealloc];
}

@end
