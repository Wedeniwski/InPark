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

#import "MAEvent.h"

#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit)

static const unsigned int DAY_IN_MINUTES                 = 1440;
static const unsigned int MIN_EVENT_DURATION_IN_MINUTES  = 15; // 30:

NSInteger MAEvent_sortByStartTime(id ev1, id ev2, void *keyForSorting) {
	MAEvent *event1 = (MAEvent *)ev1;
	MAEvent *event2 = (MAEvent *)ev2;
  int d1 = [event1 durationInMinutes];
  int d2 = [event2 durationInMinutes];
  if (d1 < d2) return NSOrderedDescending;
  if (d1 > d2) return NSOrderedAscending;
	int v1 = [event1 minutesSinceMidnight];
	int v2 = [event2 minutesSinceMidnight];
	if (v1 < v2) return NSOrderedAscending;
	if (v1 > v2) return NSOrderedDescending;
	return [event1.title compare:event2.title];
}

@implementation MAEvent

@synthesize title=_title;
@synthesize image;
@synthesize eventId=_eventId;
@synthesize start=_start;
@synthesize end=_end;
@synthesize startExtra=_startExtra;
@synthesize endExtra=_endExtra;
@synthesize displayDate=_displayDate;
@synthesize allDay=_allDay;
@synthesize backgroundColor=_backgroundColor;
@synthesize textColor=_textColor;
@synthesize textFont=_textFont;
@synthesize userInfo=_userInfo;


-(id)init {
  self = [super init];
  if (self != nil) {
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  }
  return self;
}

-(void)dealloc {
  [calendar release];
	self.title = nil;
  self.image = nil;
	self.start = nil;
	self.end = nil;
	self.startExtra = nil;
	self.endExtra = nil;
	self.displayDate = nil;
	self.backgroundColor = nil;
	self.textColor = nil;
  self.textFont = nil;
	self.userInfo = nil;
	[super dealloc];
}

-(unsigned int)durationInMinutes {
	const double s = [_start timeIntervalSince1970];
  const double e = [_end timeIntervalSince1970];
  double duration = e-s;
  if (duration < 0.0) duration += 24.0*3600.0;
  if (_startExtra != nil) {
    const double s2 = [_startExtra timeIntervalSince1970];
    if (s < s2) duration += 24.0*3600.0;
    duration += s-s2;
  }
  if (_endExtra != nil) {
    const double e2 = [_endExtra timeIntervalSince1970];
    if (e2 < e) duration += 24.0*3600.0;
    duration += e2-e;
  }
	return (int)(duration/60.0);
}

-(unsigned int)minutesSinceMidnight {
	NSDateComponents *startComponents = [calendar components:DATE_COMPONENTS fromDate:(_startExtra != nil)? _startExtra : _start];
	unsigned int fromMidnight = [startComponents hour]*60 + [startComponents minute];
	return MIN(fromMidnight, DAY_IN_MINUTES-MIN_EVENT_DURATION_IN_MINUTES);
}

-(unsigned int)minutesSinceStartHour:(unsigned int)startHourInMinutesFromMidnight {
  NSDateComponents *startComponents = [calendar components:DATE_COMPONENTS fromDate:(_startExtra != nil)? _startExtra : _start];
  unsigned int fromMidnight = [startComponents hour]*60 + [startComponents minute];
  return fromMidnight - startHourInMinutesFromMidnight;
}

+(int)minutesSinceNow:(int)startHourInMinutesFromMidnight {
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *startComponents = [calendar components:DATE_COMPONENTS fromDate:[NSDate date]];
  int fromMidnight = [startComponents hour]*60 + [startComponents minute];
  [calendar release];
  return fromMidnight-startHourInMinutesFromMidnight;
}

@end