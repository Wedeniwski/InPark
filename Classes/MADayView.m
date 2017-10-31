/*
 * Copyright (c) 2010 Matias Muhonen <mmu@iki.fi>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MADayView.h"

#import "MAEvent.h"               /* MAEvent */
#import <QuartzCore/QuartzCore.h> /* CALayer */
#import "TapDetectingView.h"      /* TapDetectingView */
#import "Colors.h"
#import "CalendarData.h"
#import "SettingsData.h"

//static const unsigned int MINUTES_IN_HOUR                = 60;
static const unsigned int SPACE_BETWEEN_HOUR_LABELS      = 19;
static const unsigned int DEFAULT_LABEL_FONT_SIZE        = 10;
static const unsigned int SMALL_LABEL_FONT_SIZE          = 8;
static const unsigned int ALL_DAY_VIEW_EMPTY_SPACE       = 3;
#define NUMBER_OF_HOURS 26

static const CGFloat kCornerRadius = 10.0;
static const CGFloat kCorner       = 5.0;

static const NSString * HOURS_AM_PM[NUMBER_OF_HOURS] = {
	@" 12 am", @" 1 am", @" 2 am", @" 3 am", @" 4 am", @" 5 am", @" 6 am", @" 7 am", @" 8 am", @" 9 am", @" 10 am", @" 11 am",
	@" noon", @" 1 pm", @" 2 pm", @" 3 pm", @" 4 pm", @" 5 pm", @" 6 pm", @" 7 pm", @" 8 pm", @" 9 pm", @" 10 pm", @" 11 pm", @" 12 am", @" 1 am"
};

static const NSString * HOURS2_AM_PM[NUMBER_OF_HOURS] = {
	@" 12:30 am", @" 1:30 am", @" 2:30 am", @" 3:30 am", @" 4:30 am", @" 5:30 am", @" 6:30 am", @" 7:30 am", @" 8:30 am", @" 9:30 am", @" 10:30 am", @" 11:30 am",
	@" 12:30 pm", @" 1:30 pm", @" 2:30 pm", @" 3:30 pm", @" 4:30 pm", @" 5:30 pm", @" 6:30 pm", @" 7:30 pm", @" 8:30 pm", @" 9:30 pm", @" 10:30 pm", @" 11:30 pm", @" 0:30 am", @" 1:30 am"
};

static const NSString * HOURS_24[NUMBER_OF_HOURS] = {
	@" 0:00", @" 1:00", @" 2:00", @" 3:00", @" 4:00", @" 5:00", @" 6:00", @" 7:00", @" 8:00", @" 9:00", @" 10:00", @" 11:00",
	@" 12:00", @" 13:00", @" 14:00", @" 15:00", @" 16:00", @" 17:00", @" 18:00", @" 19:00", @" 20:00", @" 21:00", @" 22:00", @" 23:00", @" 0:00", @" 1:00"
};

static const NSString * HOURS2_24[NUMBER_OF_HOURS] = {
	@" 0:30", @" 1:30", @" 2:30", @" 3:30", @" 4:30", @" 5:30", @" 6:30", @" 7:30", @" 8:30", @" 9:30", @" 10:30", @" 11:30",
	@" 12:30", @" 13:30", @" 14:30", @" 15:30", @" 16:30", @" 17:30", @" 18:30", @" 19:30", @" 20:30", @" 21:30", @" 22:30", @" 23:30", @" 0:30", @" 1:30"
};

#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]

//#define DAY_VIEW_DEBUG 1

@interface MADayEventView : TapDetectingView <TapDetectingViewDelegate> {
	NSString *_title;
	UIImage *image;
	MADayView *_dayView;
	MAEvent *_event;
	CGRect _textRect;
  CGFloat offset;
}

- (void)setupCustomInitialisation;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIFont *textFont;
@property (nonatomic, retain) MADayView *dayView;
@property (nonatomic, retain) MAEvent *event;
@property (nonatomic, readonly) CGRect textRect;
@property CGFloat offset;

@end

@interface MA_AllDayGridView : UIView {
	MADayView *_dayView;
	unsigned int _eventCount;
	NSDate *_day;
	CGFloat _eventHeight;
	UIFont *_textFont;
}

@property (nonatomic, assign) CGFloat eventHeight;
@property (nonatomic, retain) MADayView *dayView;
@property (nonatomic, retain) UIFont *textFont;
@property (nonatomic,copy) NSDate *day;

- (void)addEvent:(MAEvent *)event;
- (void)resetCachedData;

@end

@interface MADayTimeLineView : UIView {
  int startHour, endHour;
	UIColor *_textColor;
	UIFont *_textFont;
	CGRect _textRect[NUMBER_OF_HOURS];
  CGRect _textRect2[NUMBER_OF_HOURS];
}

-(id)initWithFrame:(CGRect)frame startHour:(int)start endHour:(int)end;

@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIFont *textFont;

@end

@interface MADayGridView : UIView {
  int startHour, endHour;
	UIColor *_textColor;
	UIFont *_textFont;
	MADayView *_dayView;
  CGFloat maxOverallWidth;
	CGFloat _lineX;
	CGFloat _lineY[NUMBER_OF_HOURS], _dashedLineY[NUMBER_OF_HOURS];
	CGRect _textRect[NUMBER_OF_HOURS];
}

-(id)initWithFrame:(CGRect)frame startHour:(int)start endHour:(int)end;

- (void)addEvent:(MAEvent *)event;

@property (nonatomic, retain) MADayView *dayView;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIFont *textFont;

@end

@interface CurrentTimeLineView : UIView {
  int startHour, endHour;
  CGFloat currentTimeLineY;
}

-(id)initWithFrame:(CGRect)frame;

@property CGFloat currentTimeLineY;

@end

@interface MADayView (PrivateMethods)
- (void)setupCustomInitialisation;
//- (void)changeDay:(UIButton *)sender;
- (NSDate *)nextDayFromDate:(NSDate *)date;
- (NSDate *)previousDayFromDate:(NSDate *)date;
- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer;

@property (readonly) UIScrollView *scrollView;
@property (readonly) MA_AllDayGridView *allDayGridView;
@property (readonly) MADayGridView *gridView;
@property (readonly) MADayTimeLineView *timeLineView;
@property (readonly) UIFont *regularFont;
@property (readonly) UIFont *boldFont;
@property (readonly) UISwipeGestureRecognizer *swipeLeftRecognizer;
@property (readonly) UISwipeGestureRecognizer *swipeRightRecognizer;
@property (readonly) NSString *titleText;
@end

@implementation MADayView

@synthesize labelFontSize=_labelFontSize;
@synthesize delegate=_delegate;
@synthesize currentTimeLineView;
@synthesize day=_day;
@synthesize scrollToNow;

-(id)initWithFrame:(CGRect)frame startHour:(int)start endHour:(int)end day:(NSDate *)date {
  self = [super initWithFrame:frame];
  if (self != nil) {
    self.backgroundColor = [Colors darkBlue];
    startHour = start;
    endHour = (end <= start)? NUMBER_OF_HOURS : end;
    _day = (date == nil)? [[NSDate date] retain] : [date retain];
    scrollToNow = NO;
		[self setupCustomInitialisation];
  }
  return self;
}

-(void)setupCustomInitialisation {
	self.labelFontSize = DEFAULT_LABEL_FONT_SIZE;
	[self addSubview:self.scrollView];
	[self addSubview:self.timeLineView];
	[_scrollView addSubview:self.allDayGridView];
	[_scrollView addSubview:self.gridView];
  self.allDayGridView.day = _day;
  if ([CalendarData isToday:_day]) {
    currentTimeLineView = [[CurrentTimeLineView alloc] initWithFrame:_allDayGridView.frame];
    currentTimeLineView.backgroundColor = [UIColor clearColor];
    currentTimeLineView.alpha = 0.6f;
    currentTimeLineView.userInteractionEnabled = NO;
    [_scrollView addSubview:currentTimeLineView];
  }
}

- (void)dealloc {
	[_scrollView release], _scrollView = nil;
	[_allDayGridView release], _allDayGridView = nil;
	[_gridView release], _gridView = nil;
	[_timeLineView release], _timeLineView = nil;
	[currentTimeLineView release], currentTimeLineView = nil;

	[_regularFont release], _regularFont = nil;
	[_boldFont release], _boldFont = nil;
	
	//[_swipeLeftRecognizer release], _swipeLeftRecognizer = nil;
	//[_swipeRightRecognizer release], _swipeRightRecognizer = nil;
	
	[_day release], _day = nil;
	[super dealloc];
}

- (UIScrollView *)scrollView {
	if (!_scrollView) {
		/*CGRect rect = CGRectMake(CGRectGetMinX(self.bounds),
								 CGRectGetMaxY(self.topBackground.bounds),
								 CGRectGetWidth(self.bounds),
								 CGRectGetHeight(self.bounds) - CGRectGetHeight(self.topBackground.bounds));*/
		_scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
		_scrollView.backgroundColor      = [UIColor clearColor];
		_scrollView.contentSize          = CGSizeMake(CGRectGetWidth(self.allDayGridView.bounds), CGRectGetHeight(self.allDayGridView.bounds) + CGRectGetHeight(self.gridView.bounds));
		_scrollView.scrollEnabled        = YES;
		_scrollView.alwaysBounceVertical = YES;
    _scrollView.delegate = self;
	}
	return _scrollView;
}

- (MA_AllDayGridView *)allDayGridView {
	if (!_allDayGridView) {
		CGRect rect = CGRectMake(0, 0, // Top left corner of the scroll view
								 CGRectGetWidth(self.bounds),
								 ALL_DAY_VIEW_EMPTY_SPACE);
		_allDayGridView = [[MA_AllDayGridView alloc] initWithFrame:rect];
		_allDayGridView.backgroundColor = [UIColor clearColor];
		_allDayGridView.dayView = self;
		_allDayGridView.textFont = self.boldFont;
		_allDayGridView.eventHeight = [@"FOO" sizeWithFont:self.regularFont].height * 2.f;
	}
	return _allDayGridView;
}

- (MADayGridView *)gridView {
	if (!_gridView){    
		_gridView = [[MADayGridView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.allDayGridView.bounds),
																	CGRectGetMaxY(self.allDayGridView.bounds),
																	CGRectGetWidth(self.bounds),
																	[@"FOO" sizeWithFont:self.boldFont].height * SPACE_BETWEEN_HOUR_LABELS * (endHour - startHour))
                 startHour:startHour endHour:endHour];
		_gridView.backgroundColor = [UIColor clearColor];
		_gridView.textFont = self.boldFont;
		_gridView.textColor = [Colors lightText];
		_gridView.dayView = self;
	}
	return _gridView;
}

-(MADayTimeLineView *)timeLineView {
	if (!_timeLineView){
    CGFloat maxTextWidth = 0;
    CGFloat maxTextHeight = 0;
    SettingsData *settings = [SettingsData getSettingsData];
    BOOL h = settings.timeIs24HourFormat;
    const NSString **HOURS = (h)? HOURS_24 : HOURS_AM_PM;
    const NSString **HOURS2 = (h)? HOURS2_24 : HOURS2_AM_PM;
    UIFont *small = [UIFont systemFontOfSize:SMALL_LABEL_FONT_SIZE];
    for (int i = startHour; i < endHour; ++i) {
      CGSize h = [HOURS[i] sizeWithFont:self.boldFont];
      if (h.width > maxTextWidth) maxTextWidth = h.width;
      if (h.height > maxTextHeight) maxTextHeight = h.height;
      h = [HOURS2[i] sizeWithFont:small];
      if (h.width > maxTextWidth) maxTextWidth = h.width;
    }
		_timeLineView = [[MADayTimeLineView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.allDayGridView.bounds),
                                                                CGRectGetMinY(self.allDayGridView.bounds),
                                                                maxTextWidth + 4.0f,
                                                                maxTextHeight * SPACE_BETWEEN_HOUR_LABELS * (endHour - startHour))
                                           startHour:startHour endHour:endHour];
		_timeLineView.backgroundColor = [UIColor clearColor];
		_timeLineView.textFont = self.boldFont;
		_timeLineView.textColor = [Colors lightText];
    _timeLineView.opaque = YES;
    _timeLineView.userInteractionEnabled = NO;
    //_timeLineView.alpha = 0.5f;
	}
	return _timeLineView;
}

-(UIFont *)regularFont {
	if (_regularFont == nil) _regularFont = [[UIFont systemFontOfSize:_labelFontSize] retain];
	return _regularFont;
}

-(UIFont *)boldFont {
	if (_boldFont == nil) _boldFont = [[UIFont boldSystemFontOfSize:_labelFontSize] retain];
	return _boldFont;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGRect frame = _timeLineView.frame;
  frame.origin.y = -_scrollView.contentOffset.y;
  _timeLineView.frame = frame;
  [self updateEventOffsets];
}

/*- (UISwipeGestureRecognizer *)swipeLeftRecognizer {
	if (!_swipeLeftRecognizer) {
		_swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
		_swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
	}
	return _swipeLeftRecognizer;
}

- (UISwipeGestureRecognizer *)swipeRightRecognizer {
	if (!_swipeRightRecognizer) {
		_swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
		_swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
	}
	return _swipeRightRecognizer;
}*/

- (void)setDataSource:(id <MADayViewDataSource>)dataSource {
	[_dataSource release], _dataSource = dataSource;
	[self reloadData];
}

- (id <MADayViewDataSource>)dataSource {
	return _dataSource;
}

-(void)updateEventOffsets {
  CGRect visibleRect = CGRectApplyAffineTransform(_scrollView.bounds, CGAffineTransformMakeScale(1.0/_scrollView.zoomScale, 1.0/_scrollView.zoomScale));
	for (id view in self.gridView.subviews) {
    if ([view isKindOfClass:[MADayEventView class]]) {
      MADayEventView *event = view;
      if (event.textRect.size.height > 56.0f && [event.event durationInMinutes] >= 20) {
        CGRect visibleEvent = CGRectIntersection(visibleRect, event.frame);
        if (!CGRectIsNull(visibleEvent) && visibleEvent.size.height >= 56.0f+13.0f+2*kCorner) {
          CGSize constrainedToSize;
          constrainedToSize.width = event.textRect.size.width;
          constrainedToSize.height = event.textRect.size.height-56.0f-2*kCorner;
          CGSize sizeNeeded = [event.title sizeWithFont:event.textFont constrainedToSize:constrainedToSize lineBreakMode:UILineBreakModeTailTruncation];
          if (visibleEvent.size.height > 56.0f+sizeNeeded.height+2*kCorner) {
            //NSLog(@"%@; %@ - %@; %f", NSStringFromCGRect(visibleRect), NSStringFromCGRect(event.frame), NSStringFromCGRect(visibleEvent), sizeNeeded.height);
            event.offset = visibleEvent.origin.y-event.frame.origin.y;
            [event setNeedsDisplay];
          }
        }
      }
    }
	}
}

-(void)reloadData {
	for (id view in self.allDayGridView.subviews) {
    if ([view isKindOfClass:[MADayEventView class]]) [view removeFromSuperview];
	}
	for (id view in self.gridView.subviews) {
    if ([view isKindOfClass:[MADayEventView class]]) [view removeFromSuperview];
	}
	[self.allDayGridView resetCachedData];
	NSArray *events = [self.dataSource dayView:self eventsForDate:_day];
	for (MAEvent *event in events) {
		event.displayDate = _day;
	}
#ifdef DAY_VIEW_DEBUG
	int i = 0;
#endif
	for (MAEvent *event in [events sortedArrayUsingFunction:MAEvent_sortByStartTime context:NULL]) {
		event.displayDate = _day;
		if (event.allDay) {
			[self.allDayGridView addEvent:event];
		} else {
#ifdef DAY_VIEW_DEBUG
			NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:event.start];
			event.title = [NSString stringWithFormat:@"%i %@", ++i, event.title];
			NSLog(@"%@ %i:%i d%i", event.title, [components hour], [components minute], [event durationInMinutes]);
#endif
			[self.gridView addEvent:event];
		}
	}
  [self.currentTimeLineView setNeedsDisplay];
  [self performSelector:@selector(updateEventOffsets) withObject:nil afterDelay:0.1];
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
	/*if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
		[self changeDay:self.rightArrow];
	} else  if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
		[self changeDay:self.leftArrow];
	}*/
}

- (NSDate *)nextDayFromDate:(NSDate *)date {
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:date];
	[components setDay:[components day] + 1];
	[components setHour:0];
	[components setMinute:0];
	[components setSecond:0];
	return [CURRENT_CALENDAR dateFromComponents:components];
}

- (NSDate *)previousDayFromDate:(NSDate *)date {
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:date];
	[components setDay:[components day] - 1];
	[components setHour:0];
	[components setMinute:0];
	[components setSecond:0];
	return [CURRENT_CALENDAR dateFromComponents:components];
}

-(NSString *)titleText {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:_day];
	NSArray *weekdaySymbols = [formatter shortWeekdaySymbols];
  NSString *s = [NSString stringWithFormat:@"%@ %@", [weekdaySymbols objectAtIndex:[components weekday] - 1], [formatter stringFromDate:_day]];
  [formatter release];
  return s;
}

@end

@implementation MADayEventView

@synthesize title=_title;
@synthesize image;
@synthesize dayView=_dayView;
@synthesize event=_event;
@synthesize textRect=_textRect;
@synthesize offset;

- (void)dealloc {
	self.title = nil;
  self.image = nil;
	self.dayView = nil;
	self.event = nil;
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:CGRectMake(frame.origin.x+2, frame.origin.y+2, frame.size.width-4, frame.size.height-4)];
  if (self != nil) {
		[self setupCustomInitialisation];
  }
  return self;
}

- (void)setupCustomInitialisation {
	twoFingerTapIsPossible = NO;
	multipleTouches = NO;
	delegate = self;
	
	CALayer *layer = [self layer];
	layer.masksToBounds = YES;
	layer.cornerRadius = kCornerRadius;
  layer.borderWidth = 1.0;
  layer.borderColor = [UIColor darkGrayColor].CGColor;
}

- (void)layoutSubviews {
	_textRect = CGRectMake(CGRectGetMinX(self.bounds) + kCorner,
						   CGRectGetMinY(self.bounds) + kCorner,
						   CGRectGetWidth(self.bounds) - 2*kCorner,
						   CGRectGetHeight(self.bounds) - 2*kCorner);
  //CGSize sizeNeeded = [self.title sizeWithFont:self.textFont forWidth:_textRect.size.width lineBreakMode:UILineBreakModeTailTruncation];
	/*CGSize sizeNeeded = [self.title sizeWithFont:self.textFont];
	if (_textRect.size.height > sizeNeeded.height) {
		_textRect.origin.y = (_textRect.size.height - sizeNeeded.height) / 2.f + kCorner; 
	}*/
}

-(void)drawRect:(CGRect)rect {
  CGFloat y = _textRect.origin.y+offset;
  [image drawInRect:CGRectMake(_textRect.origin.x+(_textRect.size.width-56.0)/2, y, 56.0, 56.0)];
  [self.textColor set];
  if ([_event durationInMinutes] >= 20) {
    [_title drawInRect:CGRectMake(_textRect.origin.x, y+56.0, _textRect.size.width, _textRect.size.height-56.0) withFont:self.textFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
  }
}

-(void)tapDetectingView:(TapDetectingView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
	if ([self.dayView.delegate respondsToSelector:@selector(dayView:eventTapped:)]) [self.dayView.delegate dayView:self.dayView eventTapped:self.event];
}

@end

@implementation MA_AllDayGridView

@synthesize dayView=_dayView;
@synthesize eventHeight=_eventHeight;
@synthesize textFont=_textFont;

- (void)dealloc {
	[_day release], _day = nil;
	self.dayView = nil;
	self.textFont = nil;
	[super dealloc];
}

- (void)resetCachedData {
	_eventCount = 0;
}

- (void)setDay:(NSDate *)day {
	[self resetCachedData];
	
	[_day release], _day = [day copy];
	
	[self setNeedsLayout];
	[self.dayView.gridView setNeedsLayout];
}

- (NSDate *)day {
	return _day;
}

- (void)layoutSubviews {	
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width,
							ALL_DAY_VIEW_EMPTY_SPACE + (ALL_DAY_VIEW_EMPTY_SPACE + self.eventHeight) * _eventCount);
	
	self.dayView.gridView.frame =  CGRectMake(self.dayView.gridView.frame.origin.x, self.frame.size.height,
											  self.dayView.gridView.frame.size.width, self.dayView.gridView.frame.size.height);
	
	self.dayView.scrollView.contentSize = CGSizeMake(self.dayView.scrollView.contentSize.width,
													 CGRectGetHeight(self.bounds) + CGRectGetHeight(self.dayView.gridView.bounds));
}

- (void)addEvent:(MAEvent *)event {
	MADayEventView *eventView = [[MADayEventView alloc] initWithFrame:CGRectMake(0, ALL_DAY_VIEW_EMPTY_SPACE + (ALL_DAY_VIEW_EMPTY_SPACE + self.eventHeight) * _eventCount, self.bounds.size.width, self.eventHeight)];
	eventView.dayView = self.dayView;
	eventView.event = event;
	eventView.backgroundColor = event.backgroundColor;
	eventView.title = event.title;
	eventView.textFont = (event.textFont == nil)? self.textFont : event.textFont;
	eventView.textColor = event.textColor;
	
	[self addSubview:eventView], [eventView release];
	
	++_eventCount;
	
	[self setNeedsLayout];
	[self.dayView.gridView setNeedsLayout];
}

@end

@implementation MADayGridView

@synthesize dayView=_dayView;

-(id)initWithFrame:(CGRect)frame startHour:(int)start endHour:(int)end {
  self = [super initWithFrame:frame];
  if (self != nil) {
    startHour = start;
    endHour = (end <= start)? NUMBER_OF_HOURS : end;
  }
  return self;
}

- (void)dealloc {
	self.dayView = nil;
	[super dealloc];
}

- (void)addEvent:(MAEvent *)event {
	MADayEventView *eventView = [[MADayEventView alloc] initWithFrame:CGRectZero];
	eventView.dayView = self.dayView;
	eventView.event = event;
	eventView.backgroundColor = event.backgroundColor;
	eventView.title = event.title;
  eventView.image = event.image;
	eventView.textFont = self.dayView.regularFont;
	eventView.textColor = event.textColor;
	[self addSubview:eventView], [eventView release];
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	CGFloat maxTextWidth = 0, totalTextHeight = 0;
	CGSize hourSize[NUMBER_OF_HOURS];
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL h = settings.timeIs24HourFormat;
	const NSString **HOURS = (h)? HOURS_24 : HOURS_AM_PM;
	const NSString **HOURS2 = (h)? HOURS2_24 : HOURS2_AM_PM;
  UIFont *small = [UIFont systemFontOfSize:SMALL_LABEL_FONT_SIZE];
	for (int i = startHour; i < endHour; ++i) {
		hourSize[i] = [HOURS[i] sizeWithFont:self.textFont];
    CGSize hSize = [HOURS2[i] sizeWithFont:small];
		totalTextHeight += hourSize[i].height;
		if (hourSize[i].width > maxTextWidth) maxTextWidth = hourSize[i].width;
		if (hSize.width > maxTextWidth) maxTextWidth = hSize.width;
	}
  maxTextWidth += 4.0f;
	CGFloat y;
	const CGFloat spaceBetweenHours = (self.bounds.size.height - totalTextHeight) / (endHour - startHour - 1);
	CGFloat rowY = 0;
	for (int i = startHour; i < endHour; ++i) {
		_textRect[i] = CGRectMake(CGRectGetMinX(self.bounds), rowY, maxTextWidth, hourSize[i].height);
		y = rowY + ((CGRectGetMaxY(_textRect[i]) - CGRectGetMinY(_textRect[i])) / 2.f);
		_lineY[i] = y;
		_dashedLineY[i] = CGRectGetMaxY(_textRect[i]) + (spaceBetweenHours / 2.f);
		rowY += hourSize[i].height + spaceBetweenHours;
	}
	_lineX = maxTextWidth + (maxTextWidth * 0.3);
	const CGFloat spacePerMinute = (_lineY[startHour+1] - _lineY[startHour]) / 60.f;
	for (id view in self.dayView.allDayGridView.subviews) {
		if ([view isKindOfClass:[MADayEventView class]]) {
			MADayEventView *ev = view;
			ev.frame = CGRectMake(_lineX,
								  ev.frame.origin.y,
								  (ev.frame.size.width - _lineX) * 0.99,
								  ev.frame.size.height);
		}
	}
	unsigned int startHourInMinutesFromMidnight = startHour*60;
  CGFloat maxY = 0.0f;
  for (MADayEventView *curEv in self.subviews) {
    if ([curEv isKindOfClass:[MADayEventView class]]) {
      curEv.frame = CGRectMake(_lineX,
                               spacePerMinute * [curEv.event minutesSinceStartHour:startHourInMinutesFromMidnight] + _lineY[startHour],
                               self.bounds.size.width - _lineX,
                               spacePerMinute * [curEv.event durationInMinutes]-1);
      //NSLog(@"startExtra: %@, _lineX: %f, _lineY[startHour]: %f, spacePerMinute: %f, duration: %d", curEv.event.startExtra, _lineX, _lineY[startHour], spacePerMinute, [curEv.event durationInMinutes]);
      CGFloat maxX = curEv.frame.origin.y + curEv.frame.size.height;
      if (maxX > maxY) maxY = maxX;
      maxX = 0.0f;
      BOOL repeat = NO;
      NSString *repeatId = nil;
      do {
        repeat = NO;
        for (MADayEventView *prevEv in self.subviews) {
          if ([prevEv isKindOfClass:[MADayEventView class]]) {
            if (curEv == prevEv) break;
            if (repeatId != nil && ![repeatId isEqualToString:curEv.event.eventId]) continue;
            if (CGRectIntersectsRect(curEv.frame, prevEv.frame)) {
              CGFloat f = prevEv.frame.origin.x+prevEv.frame.size.width;
              if (f > maxX) {
                maxX = f;
                curEv.frame = CGRectMake(maxX, curEv.frame.origin.y, curEv.frame.size.width, curEv.frame.size.height);
                repeat = YES;
                repeatId = curEv.event.eventId;
              }
            }
          }
        }
        if (repeatId != nil && !repeat) {
          repeat = YES;
          repeatId = nil;
        }
      } while (repeat);
    }
  }
  CGFloat currentTimeLineY = spacePerMinute*[MAEvent minutesSinceNow:startHourInMinutesFromMidnight];
  if (currentTimeLineY < 0) currentTimeLineY = 0.0f;
  else {
    currentTimeLineY += _lineY[startHour];
    if (currentTimeLineY >= maxY) currentTimeLineY = 0.0f;
  }
  self.dayView.currentTimeLineView.currentTimeLineY = currentTimeLineY;
  CGFloat widthFactor = 75/self.bounds.size.width;
  maxOverallWidth = self.bounds.size.width;
  for (MADayEventView *curEv in self.subviews) {
    if ([curEv isKindOfClass:[MADayEventView class]]) {
      curEv.frame = CGRectMake(_lineX + (curEv.frame.origin.x-_lineX) * widthFactor,
                               curEv.frame.origin.y,
                               /*curEv.frame.size.width */ 65.0f,
                               curEv.frame.size.height);
      if (curEv.frame.origin.x+curEv.frame.size.width > maxOverallWidth) {
        maxOverallWidth = curEv.frame.origin.x+curEv.frame.size.width;
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, maxOverallWidth, self.frame.size.height);
      }
    }
  }
  CGRect r = self.frame;
  _dayView.scrollView.contentSize = CGSizeMake(r.size.width, r.size.height);
/*			if (prevEv != nil && CGRectIntersectsRect(curEv.frame, prevEv.frame)) {
				prevEv.frame = CGRectMake(prevEv.frame.origin.x,
										  prevEv.frame.origin.y,
										  prevEv.frame.size.width / 2.f,
										  prevEv.frame.size.height);
					
				curEv.frame = CGRectMake(curEv.frame.origin.x + (curEv.frame.size.width / 2.f),
										 curEv.frame.origin.y,
										 curEv.frame.size.width / 2.f,
										 curEv.frame.size.height);*/
  self.dayView.currentTimeLineView.frame = r;
  if (_dayView.scrollToNow) {
    _dayView.scrollToNow = NO;
    CGFloat h = _dayView.frame.size.height/2;
    if (currentTimeLineY > h) _dayView.scrollView.contentOffset = CGPointMake(0, currentTimeLineY-h);
  }
}

- (void)drawRect:(CGRect)rect {
	const CGContextRef c = UIGraphicsGetCurrentContext();
  CGColorRef lightText = [[Colors lightText] CGColor];
	CGContextSetStrokeColorWithColor(c, lightText);
  CGContextSetFillColorWithColor(c, lightText);
	CGContextSetLineWidth(c, 0.5f);
	CGContextBeginPath(c);
	//[lightText setFill];
	for (int i = startHour; i < endHour; ++i) {
		CGContextMoveToPoint(c, _lineX, _lineY[i]);
		CGContextAddLineToPoint(c, maxOverallWidth, _lineY[i]);
	}
	CGContextClosePath(c);
	CGContextSaveGState(c);
	CGContextDrawPath(c, kCGPathFillStroke);
	CGContextRestoreGState(c);
	
	//CGContextSetStrokeColorWithColor(c, lightText);
	//CGContextSetLineWidth(c, 0.5f);
	CGFloat dash1[] = {2.0, 1.0};
	CGContextSetLineDash(c, 0.0, dash1, 2);
	
	CGContextBeginPath(c);
  if (endHour > 0) {
    for (int i = startHour; i < endHour-1; ++i) {
      CGContextMoveToPoint(c, _lineX, _dashedLineY[i]);
      CGContextAddLineToPoint(c, maxOverallWidth, _dashedLineY[i]);
    }
  }
	CGContextClosePath(c);
	CGContextSaveGState(c);
	CGContextDrawPath(c, kCGPathFillStroke);
	CGContextRestoreGState(c);
}

@end

@implementation MADayTimeLineView

@synthesize textColor=_textColor;
@synthesize textFont=_textFont;

-(id)initWithFrame:(CGRect)frame startHour:(int)start endHour:(int)end {
  self = [super initWithFrame:frame];
  if (self != nil) {
    startHour = start;
    endHour = (end <= start)? NUMBER_OF_HOURS : end;
  }
  return self;
}

- (void)dealloc {
	self.textColor = nil;
	self.textFont = nil;
	[super dealloc];
}

-(void)layoutSubviews {
	CGFloat maxTextWidth = 0;
  CGFloat totalTextHeight = 0;
	CGSize hourSize[NUMBER_OF_HOURS];
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL h = settings.timeIs24HourFormat;
	const NSString **HOURS = (h)? HOURS_24 : HOURS_AM_PM;
	const NSString **HOURS2 = (h)? HOURS2_24 : HOURS2_AM_PM;
  UIFont *small = [UIFont systemFontOfSize:SMALL_LABEL_FONT_SIZE];
	for (int i = startHour; i < endHour; ++i) {
		hourSize[i] = [HOURS[i] sizeWithFont:self.textFont];
    CGSize hSize = [HOURS2[i] sizeWithFont:small];
		totalTextHeight += hourSize[i].height;
		if (hourSize[i].width > maxTextWidth) maxTextWidth = hourSize[i].width;
		if (hSize.width > maxTextWidth) maxTextWidth = hSize.width;
	}
	const CGFloat spaceBetweenHours = (self.bounds.size.height - totalTextHeight) / (endHour - startHour - 1);
	CGFloat rowY = 0;
	for (int i = startHour; i < endHour; ++i) {
		_textRect[i] = CGRectMake(CGRectGetMinX(self.bounds), rowY, maxTextWidth, hourSize[i].height);
		_textRect2[i] = CGRectMake(_textRect[i].origin.x, rowY+(spaceBetweenHours+hourSize[i].height)/2.f, maxTextWidth, hourSize[i].height);
		rowY += hourSize[i].height + spaceBetweenHours;
	}
}

-(void)drawRect:(CGRect)rect {
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL h = settings.timeIs24HourFormat;
	const NSString **HOURS = (h)? HOURS_24 : HOURS_AM_PM;
	const NSString **HOURS2 = (h)? HOURS2_24 : HOURS2_AM_PM;
  UIFont *small = [UIFont systemFontOfSize:SMALL_LABEL_FONT_SIZE];
	[[Colors lightText] setFill];
	for (int i = startHour; i < endHour; ++i) {
		[HOURS[i] drawInRect:_textRect[i] withFont:self.textFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
		[HOURS2[i] drawInRect:_textRect2[i] withFont:small lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
	}
}

@end

@implementation CurrentTimeLineView

@synthesize currentTimeLineY;

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    currentTimeLineY = 0.0f;
  }
  return self;
}

-(void)drawRect:(CGRect)rect {
  if (currentTimeLineY > 0.0f) {
    const CGContextRef c = UIGraphicsGetCurrentContext();
    CGColorRef white = [[UIColor whiteColor] CGColor];
    CGContextSetStrokeColorWithColor(c, white);
    CGContextSetFillColorWithColor(c, white);
    CGContextSetLineWidth(c, 1.5f);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, 15.0f, currentTimeLineY);
		CGContextAddLineToPoint(c, self.frame.size.width, currentTimeLineY);
    CGContextAddArc(c, 15.0f, currentTimeLineY, 5.0f, 2*M_PI, 0, 0);
    //CGContextAddArcToPoint(c, 10.0f, currentTimeLineY, maxOverallWidth-10.0f, currentTimeLineY, 3.0f);
    CGContextClosePath(c);
    CGContextSaveGState(c);
    CGContextDrawPath(c, kCGPathFillStroke);
    CGContextRestoreGState(c);
  }
}

@end