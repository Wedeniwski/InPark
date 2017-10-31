import java.io.*;
import java.text.*;
import java.util.*;

public class WDWDataParser extends ParkDataParser {
  private Map<String, String> names;

  public WDWDataParser(String parkId) {
    super(parkId, "America/New_York");
    names = null;
    //downloadWaitingTimesDataCharsetName = "UTF16";
  }

  public String firstCalendarPage() {
    //return null;
    Calendar rightNow = rightNow();
    return "https://disneyworld.disney.go.com/calendars/" + formatterYearMonthDay.format(rightNow.getTime()) + '/';
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    if (contentOfPreviousPage != null && numberOfDownloadedPages < 60) {
      String search = "<a class=\"nextDateNav touchable brightText\" href=\"";
      int i = contentOfPreviousPage.indexOf(search);
      if (i >= 0) {
        i += search.length();
        int j = contentOfPreviousPage.indexOf('\"', i);
        String t = contentOfPreviousPage.substring(i, j);
        return (t.startsWith("http"))? t : "https://disneyworld.disney.go.com" + t;
      } else WaitingTimesCrawler.trace("calendar could not be successfully parsed");
    }
    return null;
  }

  private static int posEndTime(String startEndTime, boolean posAfterSeparator) {
    int i = startEndTime.indexOf(" - ");
    if (i < 0) {
      i = startEndTime.indexOf(" to ");
      if (i < 0) {
        i = startEndTime.indexOf(" &ndash; ");
        if (i < 0) return (posAfterSeparator)? i : startEndTime.length();
        if (posAfterSeparator) i += 5;
      }
      if (posAfterSeparator) ++i;
    }
    return (posAfterSeparator)? i+3 : i;
  }
  
  private String getStartTime(String startEndTime) {
    if (startEndTime.startsWith("Not available today") || startEndTime.startsWith("All Day Event") || startEndTime.startsWith("Special Events")) return null;
    int i = posEndTime(startEndTime, false);
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.substring(0, i), " ", "");
    if (startEndTime.indexOf("a.m.") >= 0) startEndTime = replace(startEndTime, "a.m.", "am");
    else if (startEndTime.indexOf("am") < 0) startEndTime = replace(startEndTime, "a", "am");
    if (startEndTime.indexOf("p.m.") >= 0) startEndTime = replace(startEndTime, "p.m.", "pm");
    else if (startEndTime.indexOf("pm") < 0) startEndTime = replace(startEndTime, "p", "pm");
    Date d = formatterHour.parse(startEndTime, new ParsePosition(0));
    if (d == null) {
      WaitingTimesCrawler.trace("getStartTime: '" + originStartEndTime + "' cannot be parsed");
      return null;
    }
    return formatterHour2.format(d);
  }
  
  private String getEndTime(String startEndTime) {
    if (startEndTime.startsWith("Not available today") || startEndTime.startsWith("All Day Event") || startEndTime.startsWith("Special Events")) return null;
    int i = posEndTime(startEndTime, true);
    if (i < 0) {
      WaitingTimesCrawler.trace("getEndTime: '" + startEndTime + "' cannot be parsed");
      return null;
    }
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.substring(i), " ", "");
    if (startEndTime.indexOf("a.m.") >= 0) startEndTime = replace(startEndTime, "a.m.", "am");
    else if (startEndTime.indexOf("am") < 0) startEndTime = replace(startEndTime, "a", "am");
    if (startEndTime.indexOf("p.m.") >= 0) startEndTime = replace(startEndTime, "p.m.", "pm");
    else if (startEndTime.indexOf("pm") < 0) startEndTime = replace(startEndTime, "p", "pm");
    Date d = formatterHour.parse(startEndTime, new ParsePosition(0));
    if (d == null) {
      WaitingTimesCrawler.trace("getEndTime: '" + originStartEndTime + "' cannot be parsed2");
      return null;
    }
    return formatterHour2.format(d);
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    String parkPath = null;
    if (parkId.equals("usdmkfl")) parkPath = "/calendars/magic-kingdom/";
    else if (parkId.equals("usdefl")) parkPath = "/calendars/epcot/";
    else if (parkId.equals("usdakfl")) parkPath = "/calendars/animal-kingdom/";
    else if (parkId.equals("usdhsfl")) parkPath = "/calendars/hollywood-studios/";
    int i = calendarPage.indexOf("selectedDate&quot;:&quot;");
    if (i < 0) return true;
    String originDate = calendarPage.substring(i+25, i+35);
    String date = formatterDate.format(formatterYearMonthDay.parse(originDate, new ParsePosition(0)));
    // Bug at Disney 2013-12-31 anstatt 2012-12-31
    //String originDate = calendarPage.substring(i, j);
    //String date = formatterDate.format(formatterYearMonthDay.parse(originDate, new ParsePosition(0)));
    String parkName = " class=\"parkName\"";
    if (parkId.equals("usdmkfl")) parkName += ">Magic Kingdom";
    else if (parkId.equals("usdefl")) parkName += ">Epcot - Future World";
    else if (parkId.equals("usdakfl")) parkName += ">Disney's Animal Kingdom";
    else if (parkId.equals("usdhsfl")) parkName += ">Disney's Hollywood Studios";
    int ix = calendarPage.indexOf(parkName, i);
    int j = calendarPage.indexOf("</a>", ix+10);
    String startEndTime = null;
    ix = calendarPage.indexOf(" class=\"hours range\"", ix);
    if (ix > j || ix < 0) {
      if (date.equals("31.03.2013") && parkId.equals("usdmkfl")) { // Bug at Disney 2013-03-31 hat nur Extra Magic Hours und keine Park Hours
        startEndTime = "8:00am &ndash; 1:00am";
        ix = calendarPage.indexOf(parkName, i);
      } else {
        WaitingTimesCrawler.trace("no park hours for " + date);
        return true;
      }
    } else {
      i = calendarPage.indexOf("<p>", ix);
      if (i < 0) {
        WaitingTimesCrawler.trace("<p> not found to identify time");
        return true;
      }
      ix = calendarPage.indexOf("</p>", i);
      if (ix < 0) {
        WaitingTimesCrawler.trace("</p> not found to identify time");
        return true;
      }
      startEndTime = calendarPage.substring(i+3, ix);
    }
    String startTime = getStartTime(startEndTime);
    String endTime = getEndTime(startEndTime);
    if (startTime == null || endTime == null) {
      WaitingTimesCrawler.trace("no start or end time for " + date);
      return true;
    }
    String startTimeExtra = null;
    String endTimeExtra = null;
    String startTimeExtra2 = null;
    String endTimeExtra2 = null;
    ix = calendarPage.indexOf(" class=\"magicHours\"", ix);
    if (ix >= 0 && ix < j) {
      int jx = calendarPage.indexOf("</div>", ix);
      if (jx < 0) {
        WaitingTimesCrawler.trace("</div> not found to identify extra time");
        return true;
      }
      int k = calendarPage.indexOf(" class=\"noHours\">", ix);
      if (k < 0 || k > jx) {
        i = calendarPage.indexOf("<p>", ix);
        if (i < 0 || i > jx) {
          WaitingTimesCrawler.trace("<p> not found to identify extra time");
          return true;
        }
        ix = calendarPage.indexOf("</p>", i);
        if (ix < 0 || ix > jx) {
          WaitingTimesCrawler.trace("</p> not found to identify extra time");
          return true;
        }
        startEndTime = calendarPage.substring(i+3, ix);
        startTimeExtra = getStartTime(startEndTime);
        endTimeExtra = getEndTime(startEndTime);
        for (int more = 0; more < 3; ++more) {
          ix = calendarPage.indexOf("<p>", ix);
          if (ix < 0 || ix > jx) break;
          i = calendarPage.indexOf("</p>", ix);
          if (i < 0 || i > jx) {
            WaitingTimesCrawler.trace("</p> not found to identify extra time2");
            break;
          }
          startEndTime = calendarPage.substring(ix+3, i);
          startTimeExtra2 = getStartTime(startEndTime);
          endTimeExtra2 = getEndTime(startEndTime);
          if (startTimeExtra2.equals(startTimeExtra) && endTimeExtra2.equals(endTimeExtra)) {
            startTimeExtra2 = null;
            endTimeExtra2 = null;
          }
          ix = i;
        }
      }
    }
    calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, startTimeExtra, endTimeExtra, startTimeExtra2, endTimeExtra2, false));
    final String dayContent = downloadPageHasContent("https://disneyworld.disney.go.com" + parkPath + originDate + "/#timeofday=allday", "UTF-8");
    final String eventTime = "<div class=\"specialEventLabel\">";
    final String eventTitle = "<p class=\"heroBlockTitle\">";
    if (dayContent == null) return true;
    Map<String, TreeSet<CalendarItem>> allIds = new HashMap<String, TreeSet<CalendarItem>>(20);
    int id = dayContent.indexOf("itineraryParksEventContainer");
    if (id >= 0) {
      int ie = dayContent.indexOf("</form>", id);
      while (id <= ie) {
        id = dayContent.indexOf(eventTime, id);
        if (id < 0 || id >= ie) break;
        id += eventTime.length();
        int id2 = dayContent.indexOf("</div>", id);
        if (id2 < 0 || id2 >= ie) {
          WaitingTimesCrawler.trace("</div> not found to identify event timeframe");
          break;
        }
        startEndTime = dayContent.substring(id, id2);
        if (!startEndTime.equals("Special Events")) {
          startTime = getStartTime(startEndTime);
          endTime = (posEndTime(startEndTime, true) < 0)? null : getEndTime(startEndTime); // Bug on WDW page?
          id = dayContent.indexOf(eventTitle, id2);
          if (id < 0 || id >= ie) {
            WaitingTimesCrawler.trace("event title for time " + startTime + " not found at " + originDate);
            break;
          }
          id += eventTitle.length();
          id2 = dayContent.indexOf("</p>", id);
          if (id2 < 0 || id2 >= ie) {
            WaitingTimesCrawler.trace("</div> not found to identify event timeframe");
            break;
          }
          String attractionId = getAttractionId(dayContent.substring(id, id2));
          if (attractionId != null) {
            if (startTime == null) WaitingTimesCrawler.trace("undefined start time in '" + startEndTime + "' for attraction " + attractionId + " on " + date);
            else if (attractionId.length() > 0) {
              for (String aId : attractionId.split(",")) {
                TreeSet<CalendarItem> allTimes = allIds.get(aId);
                if (allTimes == null) {
                  allTimes = new TreeSet<CalendarItem>();
                  allIds.put(aId, allTimes);
                }
                if (!startTime.equals("00:00") || posEndTime(startEndTime, true) < 0) { // Bug on WDW page!
                  if (endTime == null) {
                    long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(aId);
                    endTime = formatterHour2.format(new Date(time));
                  }
                  // using set because same times are listed multiple times
                  CalendarItem item = new CalendarItem(date, date, startTime, endTime, null, null, null, null, false);
                  allTimes.add(item);
                  //System.out.println("attractionId:"+aId+", date:"+date+", startTime="+startTime+", endTime="+endTime+" - " + allTimes.size());
                }
              }
            }
          }
        }
        id = id2;
      }
      for (String attractionId : allIds.keySet()) {
        Set<String> aIds = new HashSet<String>(2);
        aIds.add(attractionId);
        calendarData.add(aIds, allIds.get(attractionId));
      }
    }
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  public String getWaitingTimesDataURL() {
    downloadWaitingTimesDataUserAgent = "Mdx/3.4.2 (iPhone; iOS 9.3.1; Scale/2.00)";
    downloadWaitingTimesDataPOST = "grant_type=assertion&assertion_type=public&client_id=WDPRO-MOBILE.CLIENT-PROD";
    disableCertificateValidation();
    final String authorization = downloadPageHasContent("https://authorization.go.com/token", "UTF-8");
    String downloadWaitingTimesDataAuthorization = null;
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataPOST = null;
    if (authorization != null) {
      String s = "\"access_token\":\"";
      int i = authorization.indexOf(s);
      if (i >= 0) {
        i += s.length();
        int j = authorization.indexOf('\"', i);
        if (j > i) {
          String accessToken = authorization.substring(i, j);
          s = "\"token_type\":\"";
          i = authorization.indexOf(s);
          if (i >= 0) {
            i += s.length();
            j = authorization.indexOf('\"', i);
            if (j > i) {
              String tokenType = authorization.substring(i, j);
              downloadWaitingTimesDataAuthorization = authorization.substring(i, j) + ' ' + accessToken;
            }
          }
        }
      }
      if (downloadWaitingTimesDataAuthorization != null) {
        downloadWaitingTimesDataProperties.put("Authorization", downloadWaitingTimesDataAuthorization);
        String pId = "";
        if (parkId.equals("usdmkfl")) pId = "80007944";
        if (parkId.equals("usdefl")) pId = "80007838";
        if (parkId.equals("usdakfl")) pId = "80007823";
        if (parkId.equals("usdhsfl")) pId = "80007998";
        return "https://api.wdpro.disney.go.com/facility-service/theme-parks/" + pId + ";entityType=theme-park/wait-times";
      }
    }
    return null;
  }

  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (parkId.equals("usdmkfl")) {
      if (name.equals("Walt Disney World Railroad - Frontierland")) return "a13";
      if (name.equals("Walt Disney World Railroad - Fantasyland")) return "a47";
      if (name.equals("Walt Disney World Railroad - Main Street, U.S.A")) return "a01";
      if (name.equals("\\\"it's a small world\\\"")) return "a22";
      if (name.equals("Tomorrowland Speedway")) return "a32";
      if (name.equals("Dream Along With Mickey")) return "a42";
      if (name.equals("Main Street Vehicles")) return "a05,a51";
      if (name.equals("Main Street Trolley Show")) return "a05";
      if (name.equals("Under the Sea ~ Journey of The Little Mermaid")) return "a48";
      if (name.equals("Wishes nighttime spectacular")) return "a50";
      if (name.equals("Meet Merida at Fairytale Garden")) return "ch01";
      if (name.equals("Meet Tiana in Liberty Square")) return "ch02";
      // Captain Jack Sparrow's Pirate Tutorial -> ch05?
      if (name.equals("Meet the Disney Princesses at Town Square Theater")) return "ch06";
      if (name.equals("Meet the Disney Fairies at Tinker Bell's Magical Nook")) return "ch07";
      if (name.equals("Meet Buzz Lightyear in Tomorrowland")) return "ch08";
      if (name.equals("Meet Ariel at Her Grotto")) return "ch09";
      if (name.equals("Seven Dwarfs Mine Train")) return "a53";
    } else if (parkId.equals("usdefl")) {
      if (name.equals("Captain EO")) return "a211";
      if (name.equals("Innoventions East")) return "a202";
      if (name.equals("Innoventions West")) return "a203";
      if (name.equals("Ellen's Energy Adventure")) return "a205";
      if (name.equals("Test Track Presented by Chevrolet")) return "a207";
      if (name.startsWith("ImageWorks - The ")) return "a212";
      if (name.equals("MO'ROCKIN")) return "a248";
      if (name.equals("Meet Mickey Mouse & Friends at the Epcot Character Spot")) return "ch202";
      if (name.equals("Meet Chip 'n' Dale near Epcot Character Spot")) return "ch203";
      if (name.equals("Meet Duffy the Disney Bear near Showcase Plaza")) return "ch204";
      if (name.equals("Meet Donald Duck in Mexico")) return "ch205";
      if (name.equals("Meet Mulan in China")) return "ch206";
      if (name.equals("Meet Snow White in Germany")) return "ch207";
      if (name.equals("Meet Aladdin & Jasmine in Morocco")) return "ch208";
      // Meet Aurora in France
      if (name.equals("Meet Belle in France")) return "ch209";
      if (name.equals("Meet Alice in Wonderland at the Tea Caddy")) return "ch210";
      if (name.equals("Meet Mary Poppins in the United Kingdom")) return "ch210";
    } else if (parkId.equals("usdakfl")) {
      if (name.startsWith("Expedition Everest - Legend of the Forbidden Mountain")) return "a415";
      if (name.equals("Kilimanjaro Safaris Expedition")) return "a405";
      if (name.equals("Meet Mickey Mouse & Friends in Camp Minnie-Mickey")) return "ch401";
      if (name.equals("Meet Rafiki at Rafiki's Planet Watch")) return "ch403";
      if (name.startsWith("Finding Nemo")) return "a417";
      //if (name.equals("Meet Russell and Dug at Discovery Island")) return "ch405";
      //if (name.equals("Meet Winnie the Pooh & Friends at Discovery Island")) return "ch405";
      if (name.equals("Meet Goofy & Pluto in DinoLand U.S.A.")) return "ch406";
      if (name.equals("Wildlife Express Train")) return "a407,a408";
      if (name.equals("Wilderness Explorers")) return "a423,a424,a426,a427,a428";
      // "ch402" // characters mercantile; warten -> YES
      // "ch404" // africa; warten -> YES
      // Meet Pocahontas near Bradley Falls
      // Meet Forest Friends in Camp Minnie-Mickey
    } else if (parkId.equals("usdhsfl")) {
      if (name.startsWith("The American Idol") && name.indexOf("Experience") > 0) return "a603";
      if (name.startsWith("Indiana Jones") && name.endsWith("Epic Stunt Spectacular!")) return "a605";
      if (name.startsWith("Lights, Motors, Action!") && name.indexOf("Extreme Stunt Show") > 0) return "a608";
      if (name.startsWith("Muppet") && name.endsWith("Vision 3D")) return "a606";
      if (name.equals("Toy Story Mania!")) return "a610";
      if (name.equals("Disney Junior - Live on Stage!")) return "a615";
      if (name.equals("Beauty and the Beast-Live on Stage")) return "a616";
      if (name.startsWith("Star Tours") && name.endsWith(" - The Adventures Continue")) return "a623";
      if (name.equals("American Film Institute Showcase")) return "a626";
      if (name.startsWith("Pixar Pals Countdown to Fun")) return "a628";
      if (name.equals("Meet Disney Pals at the Sorcerer Hat")) return "ch601";
      if (name.equals("Meet the Stars of Cars near Streets of America")) return "ch602";
      if (name.equals("Meet Mickey Mouse at The Magic of Disney Animation")) return "ch603";
      if (name.equals("Meet the Stars of Disney Junior at Animation Courtyard")) return "ch604";
    }
    return null;
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    if (waitingTimes == null) return null;
    //System.out.println(waitingTimesData);
    //System.exit(1);
    closedAttractionIds.clear();
    int i = 0;
    int j = 0;
    while (true) {
      i = waitingTimesData.indexOf("\"waitTime\":", i);
      j = waitingTimesData.indexOf("\"name\":\"", j);
      if (i < 0 || j < 0) break;
      i += 11; j += 8;
      int k = waitingTimesData.indexOf('\"', j+1);
      while (k > 0 && waitingTimesData.charAt(k-1) == '\\') k = waitingTimesData.indexOf('\"', k+1);
      if (k < 0) { System.out.println("attraction name cannot be identified!"); break; }
      String name = waitingTimesData.substring(j, k);
      j = waitingTimesData.indexOf("}}", i);
      String attractionId = getAttractionId(name);
      k = waitingTimesData.indexOf("\"status\":\"Closed\"", i);
      if (k > i && k < j) {
        if (attractionId != null) {
          if (attractionId.length() > 0) for (String aId : attractionId.split(",")) closedAttractionIds.add(aId);
        } else WaitingTimesCrawler.trace("attraction closed but no attraction ID defined for " + name + " (" + parkId + ')');
        i = k;
      } else {
        k = waitingTimesData.indexOf("\"fastPass\":{", i);
        if (k > i && k < j) {
          int k2 = waitingTimesData.indexOf("\"available\":true", k);
          if (k2 > i && k2 < j) {
            k = waitingTimesData.indexOf("\"startTime\":\"", k);
            if (k > i && k < j) {
              k += 13;
              String startTime = waitingTimesData.substring(k, k+2) + waitingTimesData.substring(k+3, k+5);
              k = waitingTimesData.indexOf("\"endTime\":\"", k);
              if (k > i && k < j) {
                if (attractionId == null) WaitingTimesCrawler.trace("fastPass available but no attraction ID defined for " + name + " (" + parkId + ')');
                else if (attractionId.length() > 0) {
                  String endTime = waitingTimesData.substring(k+11, k+13) + waitingTimesData.substring(k+14, k+16);
                  WaitingTimesItem item = new WaitingTimesItem();
                  item.fastLaneAvailable = 1;
                  item.fastLaneAvailableTimeFrom = startTime;
                  item.fastLaneAvailableTimeTo = endTime;
                  for (String aId : attractionId.split(",")) waitingTimes.put(aId, item);
                }
              } else {
                k = waitingTimesData.indexOf("\"startTime\":\"FASTPASS is Not Available\"", i);
                if (k > i && k < j) {
                  if (attractionId == null) WaitingTimesCrawler.trace("fastPass not available but no attraction ID defined for " + name + " (" + parkId + ')');
                  else if (attractionId.length() > 0) {
                    WaitingTimesItem item = new WaitingTimesItem();
                    item.fastLaneAvailable = 0;
                    for (String aId : attractionId.split(",")) waitingTimes.put(aId, item);
                  }
                } else {
                  k = waitingTimesData.indexOf("\"startTime\":\"N/A\"", i);
                  if (k < i || k >= j) WaitingTimesCrawler.trace("missing endTime for attraction " + name + " (" + attractionId + ')');
                  //System.out.println(waitingTimesData);
                  //System.exit(1);
                }
              }
            } // fast pass does not exist
          }
        }
        k = waitingTimesData.indexOf("\"postedWaitMinutes\":", i);
        if (k > i && k < j) {
          k += 20;
          i = waitingTimesData.indexOf(',', k);
          if (i > k && i < j) {
            if (attractionId == null) WaitingTimesCrawler.trace("waitTime available but no attraction ID defined for " + name + " (" + parkId + ')');
            else if (attractionId.length() > 0) {
              for (String aId : attractionId.split(",")) {
                if (!isTrain(aId)) {
                  WaitingTimesItem item = waitingTimes.get(aId);
                  if (item == null) item = new WaitingTimesItem();
                  String t = waitingTimesData.substring(k, i);
                  if (t.endsWith("}")) t = t.substring(0, t.length()-1);
                  item.waitTime = Integer.parseInt(t);
                  waitingTimes.put(aId, item);
                }
              }
            }
          } else WaitingTimesCrawler.trace("missing delimiter after postedWaitMinutes for attraction " + name + " (" + attractionId + ')');
          i = k;
        }
      }
    }
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
