//
//  CellOwner.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CellOwner.h"


@implementation CellOwner

@synthesize cell;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
*/

-(BOOL)loadNibNamed:(NSString *)nibName owner:(id)delegate {
  if ([[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil] == nil) {
    NSLog(@"Warning! Could not load %@ file.\n", nibName);
    return NO;
  }
  cell.delegate = delegate;
  return YES;
}

-(void)dealloc {
  [cell release];
  [super dealloc];
}

@end
