//
//  GeneralInfoViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 11.12.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "GeneralInfoViewController.h"
#import "SettingsData.h"
#import "MenuData.h"
#import "ParkData.h"
#import "WaitingTimeData.h"
#import "Update.h"
#import "IPadHelper.h"
#import "Colors.h"

@implementation GeneralInfoViewController

@synthesize titleNavigationItem;
@synthesize topNavigationBar;
@synthesize webView;
@synthesize activityIndicatorView;
@synthesize content, subdirectory;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner fileName:(NSString *)fName title:(NSString *)tName {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    fileName = (fName != nil)? [fName retain] : nil;
    titleName = [tName retain];
    content = nil;
    subdirectory = nil;
  }
  return self;
}

-(void)updateData {
  BOOL iPad = [IPadHelper isIPad];
  //NSDate *creationDate = nil;
  NSString *data = content;
  if (data == nil) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = fileName;
    NSRange found = [fileName rangeOfString:@"/"];
    if (found.length == 0) {
      SettingsData *settings = [SettingsData getSettingsData];
      if (subdirectory != nil) {
        data = [Update onlineDataPath:[NSString stringWithFormat:@"%@/%@.gz", [settings languagePath], fileName] hasPrefix:nil useLocalDataIfNotOlder:24.0 parkId:subdirectory online:nil statusCode:nil];
      }
      if (data == nil) {  // introduced in 1.5.1 that all files are online and not local in park package anymore
        NSString *bPath = [MenuData dataPath];
        if (subdirectory != nil) bPath = [bPath stringByAppendingPathComponent:subdirectory];
        filePath = [[bPath stringByAppendingPathComponent:[settings languagePath]] stringByAppendingPathComponent:fileName];
        if (![fileManager fileExistsAtPath:filePath]) {
          filePath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[settings languagePath]] stringByAppendingPathComponent:fileName];
          if ([fileManager fileExistsAtPath:filePath]) {
            NSLog(@"%@ found in main bundle", fileName);
          }
        }
      }
    }
    NSError *error = nil;
    if (data == nil) data = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
      NSLog(@"Error accessing file %@  (%@)", filePath, [error localizedDescription]);
      /*} else {
       NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
       if (error == nil) creationDate = [[attributes objectForKey:NSFileModificationDate] retain];*/
    }
    data = [data stringByReplacingOccurrencesOfString:@"%ICON%" withString:(iPad)? @"inpark@2x.png" : @"inpark@2x.png"];
    data = [data stringByReplacingOccurrencesOfString:@"%VERSION%" withString:[SettingsData getAppVersion]];
    data = [data stringByReplacingOccurrencesOfString:@"%VERSION_LONG%" withString:[WaitingTimeData encodeToPercentEscapeString:[SettingsData getAppVersionLong]]];
    // ToDo: remove adjusting colors
    data = [data stringByReplacingOccurrencesOfString:@"bgcolor=\"#CCCCCC\"" withString:[NSString stringWithFormat:@"bgcolor=\"%@\"", [Colors htmlColorCode:[Colors lightBlue]]]];
  }
  if (data != nil) {
    int fontSize = (iPad)? 14 : 12;
    BOOL isAbout = [fileName isEqualToString:@"about.txt"];
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:[data length]+500];
    [s setString:@"<html><head>"];
    NSString *linkColor = [Colors htmlColorCode:[Colors hilightText]];
    [s appendFormat:@"<style type=\"text/css\">table {font-family:helvetica;font-size:%dpx;background-color:transparent}\nA:link {color:%@}\nA:visited {color:%@}\nA:active {color:%@}</style>", fontSize, linkColor, linkColor, linkColor];
    [s appendString:@"<script>document.ontouchmove = function(event) { if (document.body.scrollHeight == document.body.clientHeight) event.preventDefault(); }</script>"];
    [s appendFormat:@"</head><body style=\"font-family:helvetica;font-size:%dpxbackground-color:transparent;color:%@\">", fontSize, [Colors htmlColorCode:[Colors lightText]]];
    if (isAbout) {
      [s appendFormat:@"<p>%@ %@</p><table><tr><td>", NSLocalizedString(@"version", nil), [SettingsData getAppVersion]];
      NSString *t = [ParkData getParkDataVersions];
      t = [t stringByReplacingOccurrencesOfString:@":" withString:@"</td><td>"];
      [s appendString:[t stringByReplacingOccurrencesOfString:@"\n" withString:@"</td></tr><tr><td>"]];
      [s appendString:@"</td></tr></table>"];
      //} else if (creationDate != nil) {
      //[s appendFormat:@"<p><font size=\"-3\">%@ %@</font></p>", NSLocalizedString(@"version", nil), [CalendarData stringFromDate:creationDate]];
    }
    [s appendString:data];
    [s appendString:@"</body></html>"];
    [self performSelectorOnMainThread:@selector(updateWebView:) withObject:[NSString stringWithString:s] waitUntilDone:NO];
    [s release];
  }
  //[creationDate release];
}

-(void)updateWebView:(NSString *)webContent {
  BOOL isAbout = [fileName isEqualToString:@"about.txt"];
  NSURL *baseURL = [NSURL fileURLWithPath:(isAbout)? [[NSBundle mainBundle] bundlePath] : [MenuData dataPath]];
  webView.hidden = NO;
  [webView loadHTMLString:webContent baseURL:baseURL];
  [activityIndicatorView stopAnimating];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  topNavigationBar.tintColor = [Colors darkBlue];
  self.view.backgroundColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(titleName, nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  webView.backgroundColor = [Colors darkBlue];
  webView.opaque = NO;
  webView.hidden = YES;
  [activityIndicatorView startAnimating];
  [self performSelectorInBackground:@selector(updateData) withObject:nil];
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
  webView.delegate = nil;
	[delegate dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Web view delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted || (navigationType == UIWebViewNavigationTypeOther && [[request URL] host] != nil)) {
    NSURL *requestURL = [request URL];
    NSString *scheme = [requestURL scheme];
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"mailto"]) return ![[UIApplication sharedApplication] openURL:requestURL];
  }
  return YES;
}

/*-(void)webViewDidFinishLoad:(UIWebView *)localWebView {
  NSString *javascripString = [NSString stringWithFormat:@"document.getElementById(\"linkId\").style.color=\"%@\";", @"white"];
  [webView stringByEvaluatingJavaScriptFromString:javascripString];
}*/

#pragma mark -
#pragma mark Memory Management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  webView = nil;
  activityIndicatorView = nil;
  fileName = nil;
  titleName = nil;
  content = nil;
  subdirectory = nil;
}

-(void)dealloc {
  [topNavigationBar release];
  [titleNavigationItem release];
  [webView release];
  [activityIndicatorView release];
  [fileName release];
  [titleName release];
  [content release];
  [subdirectory release];
  [super dealloc];
}

@end
