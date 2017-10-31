//
//  CompileSettings.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

// PARK_ID_EDITION is equal to park id or park group id
// PARK_ID_EDITION is equal to nil if full version
#ifndef PARK_ID_EDITION
#error PARK_ID_EDITION not defined
#endif

// PATHES_EDITION is equal to nil if full version or like full version
// PATHES_EDITION is equal to PARK_ID_EDITION if Wait Time Edition for specified park id or park group id
#ifndef PATHES_EDITION
#error PATHES_EDITION not defined
#endif

//Debug for Development
#if TARGET_IPHONE_SIMULATOR

//#define FAKE_CALENDAR

//#define SUBMIT_WAITING_TIME_WITHOUT_LOCATION
//#define FAKE_CORE_LOCATION 1

//#define CREATE_PARK_DOCUMENT

#define DEBUG_MAP YES

#endif

#define DEBUG_MAP YES

#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Europa-Park_Europa-Park  02.06.2012.gpx"
//#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Phantasialand_Phantasialand  01.09.2011.gpx"
//#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Universal-Island-of-Advantures-28.02.2011.gpx"
//#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Europa-Park_Alexander  05.06.2011.gpx"
//#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Heide-Park-1-29.10.2010.gpx"
//#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Disneyland-Paris-28.12.2010.gpx"
//#define FAKE_LOCATION_PATH @"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS/parkdata/original/Magic-Kingdom-24.02.2011.gpx"
//#define FAKE_LOCATION_LAT 28.409955
//#define FAKE_LOCATION_LON -81.461488
//#define FAKE_LOCATION_UP_TO_LAT 48.2687379
//#define FAKE_LOCATION_UP_TO_LON 7.7221462
#define FAKE_CORE_LOCATION_UPDATE_INTERVAL 1.0
