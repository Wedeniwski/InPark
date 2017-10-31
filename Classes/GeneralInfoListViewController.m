//
//  GeneralInfoListViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 20.03.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "GeneralInfoListViewController.h"
#import "GeneralInfoViewController.h"
#import "SettingsData.h"
#import "Colors.h"

@implementation GeneralInfoListViewController

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize newsTableView;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner helpData:(HelpData *)hData title:(NSString *)tName {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    helpData = [hData retain];
    titleName = [tName retain];
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.title = titleName;
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  newsTableView.backgroundColor = [Colors darkBlue];
  newsTableView.backgroundView = nil;
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
#pragma mark UITableViewDataSource Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [helpData.keys count];
}

/*-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44.0;
}*/

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"NewsCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    cell.backgroundColor = [Colors lightBlue];
    cell.textLabel.font = [UIFont systemFontOfSize:11.0];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.numberOfLines = 2;
    
  }
  cell.textLabel.text = [helpData.titles objectForKey:[helpData.keys objectAtIndex:indexPath.row]];
  return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *key = [helpData.keys objectAtIndex:indexPath.row];
  NSString *headline = [helpData.titles objectForKey:key];
  NSString *content = [helpData.pages objectForKey:key];
  NSString *title = titleName;
  NSRange range = [content rangeOfString:@"<p>"];
  if (range.length > 0) {
    NSRange range2 = [content rangeOfString:@"</p>"];
    if (range2.length > 0 && range2.location > range.location+range.length) {
      range2.length = range2.location-range.location-range.length;
      range2.location = range.location+range.length;
      title = [content substringWithRange:range2];
      content = [NSString stringWithFormat:@"<p><b>%@</b></p>%@", headline, [content substringFromIndex:range2.location+range2.length]];
    }
  }
  GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
  controller.content = content;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
  [newsTableView deselectRowAtIndexPath:indexPath animated:NO];
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
  newsTableView = nil;
}

-(void)dealloc {
  [topNavigationBar release];
  [titleNavigationItem release];
  [newsTableView release];
  [helpData release];
  [titleName release];
  [super dealloc];
}

@end
