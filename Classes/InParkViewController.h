//
//  InParkViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.11.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InParkViewController : UIViewController {
  BOOL releaseNotesViewed;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@property BOOL releaseNotesViewed;

@end

