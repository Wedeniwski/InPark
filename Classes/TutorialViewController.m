//
//  TutorialViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 11.12.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TutorialViewController.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "IPadHelper.h"
#import "Colors.h"

@implementation TutorialViewController

@synthesize thumbnailIndex;
@synthesize topNavigationBar;
@synthesize navigationTitle, startHtmlAnchor;
@synthesize titleNavigationItem;
@synthesize scrollView;
@synthesize pageControl;

-(void)updatePageWidthHeight:(UIInterfaceOrientation)toInterfaceOrientation {
  //InParkAppDelegate *app = (InParkAppDelegate *)[[UIApplication sharedApplication] delegate];
  //CGRect r = app.window.frame;
  CGRect r = [[UIScreen mainScreen] bounds];
  if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
    pageWidth = r.size.width;
    pageHeight = r.size.height-100;
  } else {
    pageHeight = r.size.width;
    pageWidth = r.size.height;
  }
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner helpData:(HelpData *)hData {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    helpData = [hData retain];
    numberOfPages = (int)[helpData.keys count]+1;
    webPages = nil;
    navigationTitle = nil;
    startHtmlAnchor = nil;
    thumbnailIndex = NO;
  }
  return self;
}

-(void)updateView {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL iPad = [IPadHelper isIPad];
  int fontSize = (iPad)? 14 : 12;
  
  scrollView.contentSize = CGSizeMake(pageWidth * numberOfPages, pageHeight);
  
  NSString *linkColor = [Colors htmlColorCode:[Colors hilightText]];
  NSMutableString *s = [[NSMutableString alloc] initWithCapacity:2000];
  if (thumbnailIndex) {
    [s appendString:@"<html><body><center><table>"];
    int maxColumns = (iPad)? 3 : 2;
    int imageSize = (iPad)? 200 : 130;
    SettingsData *settings = [SettingsData getSettingsData];
    if (![settings isPortraitScreen]) {
      maxColumns = (iPad)? 5 : 4;
      imageSize = (iPad)? 195 : 110;
    }
    int column = 0;
    for (NSString *pageKey in helpData.keys) {
      if (column == maxColumns) {
        [s appendString:@"</tr><tr>"];
        column = 0;
      } else if (column == 0) [s appendString:@"<tr>"];
      NSString *content = [helpData.pages objectForKey:pageKey];
      NSRange range1 = [content rangeOfString:@"<img src=\""];
      NSRange range2 = [content rangeOfString:@"\" width=\""];
      NSRange range3 = [content rangeOfString:@"\" height=\""];
      NSRange range4 = [content rangeOfString:@"\"></center>"];
      if (range1.length > 0 && range2.length > 0 && range3.length > 0 && range4.length > 0) {
        range1.location += 10;
        range1.length = range2.location-range1.location;
        NSString *imagePath = [content substringWithRange:range1];
        range2.location += 9;
        range2.length = range3.location-range2.location;
        range3.location += 10;
        range3.length = range4.location-range3.location;
        double width = [[content substringWithRange:range2] doubleValue];
        double height = [[content substringWithRange:range3] doubleValue];
        if (width > height) {
          height = imageSize*height/width;
          width = imageSize;
        } else {
          width = imageSize*width/height;
          height = imageSize;
        }
        //UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
        //float f = imageSize/MAX(image.size.width, image.size.height);
        [s appendFormat:@"<td><a href=\"#%@\"><img src=\"%@\" width=\"%d\" height=\"%d\"/></a></td>", pageKey, imagePath, (int)width, (int)height];
        //[image release];
        ++column;
      }
    }
    [s appendString:@"</tr></table></center></body></html>"];
  } else {
    [s appendFormat:@"<html><head><style type=\"text/css\">A:link {color:%@}\nA:visited {color:%@}\nA:active {color:%@}</style></head><body style=\"font-family:helvetica;font-size:%dpx background-color:transparent;color:%@\"><ul>", linkColor, linkColor, linkColor, fontSize, [Colors htmlColorCode:[Colors lightText]]];
    for (NSString *pageKey in helpData.keys) {
      [s appendFormat:@"<li><a href=\"#%@\">%@</a></li>", pageKey, [helpData.titles objectForKey:pageKey]];
    }
    [s appendString:@"</ul></body></html>"];
  }
  NSURL *baseURL = [NSURL fileURLWithPath:[MenuData dataPath]];//[[NSBundle mainBundle] bundlePath]];
  CGRect frame = scrollView.frame;
  frame.origin.x = 10;
  frame.origin.y = 10;
  frame.size.width = pageWidth-20;
  frame.size.height = pageHeight-20;
  NSMutableArray *pages = nil;
  if (webPages == nil) {
    pages = [[NSMutableArray alloc] initWithCapacity:numberOfPages];
    UIWebView *webPage = [[UIWebView alloc] initWithFrame:frame];
    webPage.opaque = NO;
    webPage.backgroundColor = [Colors darkBlue];
    webPage.delegate = self;
    //webPage.scalesPageToFit = YES;
    [webPage loadHTMLString:[NSString stringWithString:s] baseURL:baseURL];
    [pages addObject:webPage];
    [scrollView addSubview:webPage];
    [webPage release];
  } else {
    UIWebView *webPage = [webPages objectAtIndex:0];
    webPage.frame = frame;
    [webPage loadHTMLString:[NSString stringWithString:s] baseURL:baseURL];
  }
  int page = 1;
  for (NSString *pageKey in helpData.keys) {
    frame.origin.x = pageWidth*page + 10;
    [s setString:@"<html><head>"];
    [s appendFormat:@"<style type=\"text/css\">A:link {color:%@}\nA:visited {color:%@}\nA:active {color:%@}</style>", linkColor, linkColor, linkColor];
    NSString *content = [helpData.pages objectForKey:pageKey];
    if (thumbnailIndex) {
      NSRange range = [content rangeOfString:@"<img src=\"http://"];
      if (range.length > 0) [s appendString:@"<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=3.0; user-scalable=1;'/>"];
    }
    [s appendFormat:@"</head><body style=\"font-family:helvetica;font-size:%dpxbackground-color:transparent;color:%@\"><h2>", fontSize, [Colors htmlColorCode:[Colors lightText]]];
    [s appendString:[helpData.titles objectForKey:pageKey]];
    [s appendString:@"</h2>"];
    [s appendString:content];
    [s appendString:@"</body></html>"];
    if (webPages == nil) {
      UIWebView *webPage = [[UIWebView alloc] initWithFrame:frame];
      webPage.opaque = NO;
      webPage.backgroundColor = [Colors darkBlue];
      webPage.delegate = self;
      [webPage loadHTMLString:[NSString stringWithString:s] baseURL:baseURL];
      [pages addObject:webPage];
      [scrollView addSubview:webPage];
      [webPage release];
    } else {
      UIWebView *webPage = [webPages objectAtIndex:page];
      webPage.frame = frame;
      [webPage loadHTMLString:[NSString stringWithString:s] baseURL:baseURL];
    }
    ++page;
  }
  [s release];
  if (pages != nil) webPages = pages;
  [pool release];
}

-(int)pageNumber:(NSString *)htmlAnchor {
  if (htmlAnchor == nil) return 0;
  int page = 1;
  for (NSString *pageKey in helpData.keys) {
    if ([pageKey isEqualToString:htmlAnchor]) break;
    ++page;
  }
  return (page >= numberOfPages)? 0 : page;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void)viewDidLoad {
  [super viewDidLoad];
  topNavigationBar.tintColor = [Colors darkBlue];
  self.view.backgroundColor = [Colors darkBlue];
  titleNavigationItem.title = (navigationTitle != nil)? navigationTitle : NSLocalizedString(@"tutorial.title", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);

  pageControl.numberOfPages = numberOfPages;
  pageControl.currentPage = [self pageNumber:startHtmlAnchor];

  scrollView.pagingEnabled = YES;
  scrollView.showsHorizontalScrollIndicator = NO;
  scrollView.showsVerticalScrollIndicator = NO;
  scrollView.scrollsToTop = NO;
  scrollView.delegate = self;
  SettingsData *settings = [SettingsData getSettingsData];
  [self updatePageWidthHeight:([settings isPortraitScreen])? UIInterfaceOrientationPortrait : UIInterfaceOrientationLandscapeLeft];
  [self updateView];
  [self changePage:self];
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

/*-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [self updatePageWidthHeight:toInterfaceOrientation];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self updateView];
  [self changePage:self];
}*/

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
    pageControl.currentPage = [self pageNumber:[[request URL] fragment]];
    [self changePage:self];
    return NO;
  }
  return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)sender {
  // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
  // which a scroll event generated from the user hitting the page control triggers updates from
  // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
  if (pageControlUsed) return; // do nothing - the scroll was initiated from the page control, not the user dragging

  // Switch the indicator when more than 50% of the previous/next page is visible
  int page = floor((scrollView.contentOffset.x - pageWidth/2) / pageWidth) + 1;
  pageControl.currentPage = page;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  pageControlUsed = NO;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  pageControlUsed = NO;
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  for (UIWebView *webPage in webPages) webPage.delegate = nil;
	[delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)homePage:(id)sender {
  pageControl.currentPage = 0;
  [self changePage:sender];
}

-(IBAction)changePage:(id)sender {
	// update the scroll view to the appropriate page
  CGRect frame = scrollView.frame;
  frame.origin.x = pageWidth * pageControl.currentPage;
  frame.origin.y = 10;
  [scrollView scrollRectToVisible:frame animated:YES];
  pageControlUsed = YES;
}

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  navigationTitle = nil;
  startHtmlAnchor = nil;
  titleNavigationItem = nil;
  scrollView = nil;
  pageControl = nil;
}

-(void)dealloc {
  [helpData release];
  [webPages release];
  [topNavigationBar release];
  [navigationTitle release];
  [startHtmlAnchor release];
  [titleNavigationItem release];
  [scrollView release];
  [pageControl release];
  [super dealloc];
}

@end
