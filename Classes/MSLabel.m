//
//  MSLabel.m
//  Miso
//
//  Created by Joshua Wu on 11/15/11.
//  Copyright (c) 2011 Miso. All rights reserved.
//

#import "MSLabel.h"

// small buffer to allow for characters like g,y etc 
static const int kAlignmentBuffer = 0;//5;

@interface MSLabel ()

- (void)setup;
- (NSArray *)stringsFromText:(NSString *)string;

@end

@implementation MSLabel

@synthesize lineHeight = _lineHeight;
@synthesize verticalAlignment = _verticalAlignment;


#pragma mark - Initilisation

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) [self setup];
  return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) [self setup];
  return self;
}

#pragma mark - Drawing

-(void)drawTextInRect:(CGRect)rect {
  NSArray *slicedStrings = [self stringsFromText:self.text];
  if (self.highlighted) [self.highlightedTextColor set];
  else [self.textColor set];
  int numLines = (int)slicedStrings.count;
  if (numLines > self.numberOfLines && self.numberOfLines != 0) numLines = (int)self.numberOfLines;
  int drawY = (self.frame.size.height / 2 - (_lineHeight * numLines) / 2) - kAlignmentBuffer;
  for (int i = 0; i < numLines; ++i) {
    NSString *line = [slicedStrings objectAtIndex:i];
    // calculate draw Y based on alignment
    switch (_verticalAlignment) {
      case MSLabelVerticalAlignmentTop:
        drawY = i * _lineHeight;
        break;
      case MSLabelVerticalAlignmentMiddle:
        if (i > 0) drawY += _lineHeight;
        break;
      case MSLabelVerticalAlignmentBottom:
        drawY = (self.frame.size.height - _lineHeight * numLines) + ((i  * _lineHeight) - kAlignmentBuffer);
        break;
      default:
        if (i > 0) drawY += _lineHeight;
        break;
    }
    // calculate draw X based on textAlignmentment
    int drawX = 0;
    if (self.textAlignment == UITextAlignmentCenter) drawX = floorf((self.frame.size.width - [line sizeWithFont:self.font].width) / 2);
    else if (self.textAlignment == UITextAlignmentRight) drawX = (self.frame.size.width - [line sizeWithFont:self.font].width);
    [line drawAtPoint:CGPointMake(drawX, drawY) forWidth:self.frame.size.width withFont:self.font fontSize:self.font.pointSize lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentNone];
  }
}


#pragma mark - Properties

-(void)setLineHeight:(int)lineHeight {
  if (_lineHeight != lineHeight) {
    _lineHeight = lineHeight;
    [self setNeedsDisplay];
  }
}


#pragma mark - Private Methods

-(void)setup {
  _lineHeight = 10;
  _verticalAlignment = MSLabelVerticalAlignmentMiddle;
}

-(NSArray *)stringsFromText:(NSString *)string {
  NSMutableArray *stringsArray = [[[string componentsSeparatedByString:@" "] mutableCopy] autorelease];
  int n = (int)[stringsArray count];
  NSMutableArray *slicedString = [[[NSMutableArray alloc] initWithCapacity:n] autorelease];
  while (n != 0) {
    NSString *line = @"";
    NSMutableIndexSet *wordsToRemove = [NSMutableIndexSet indexSet];
    for (int i = 0; i < n; ++i) {
      NSString *word = [stringsArray objectAtIndex:i];
      NSString *line2 = [line stringByAppendingFormat:@"%@ ", word];
      if ([line2 sizeWithFont:self.font].width <= self.frame.size.width) {
        line = line2;
        [wordsToRemove addIndex:i];
      } else {
        if (line.length == 0) {
          line = line2;
          [wordsToRemove addIndex:i];
        }
        break;
      }
    }
    [slicedString addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    [stringsArray removeObjectsAtIndexes:wordsToRemove];
    n = (int)[stringsArray count];
  }
  n = (int)self.numberOfLines;
  if (n != 0 && slicedString.count > n) {
    NSString *line = [slicedString objectAtIndex:n-1];
    if ([line length] >= 3) {
      line = [line stringByReplacingCharactersInRange:NSMakeRange(line.length - 3, 3) withString:@"..."];
    } else {
      line = @"...";
    }
    [slicedString removeObjectAtIndex:n-1];
    [slicedString insertObject:line atIndex:n-1];
  }
  return slicedString;
}

@end
