import java.text.*;
import java.util.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class SeaWorldOrlandoDataParser extends ParkDataParser {
  public SeaWorldOrlandoDataParser() {
    super("usswofl", "America/New_York");
  }

  public String firstCalendarPage() {
    // http://seaworldparks.com/en/seaworld-orlando/Park-Info/Park-Hours
    Calendar rightNow = rightNow();
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataContentType = "application/json; charset=utf-8";
    downloadWaitingTimesDataPOST = "{\"date\":\"" + formatterMonthDayYear.format(rightNow.getTime()) + "\",\"cmsId\":\"{6BC9EB1F-ADBE-4596-8321-D2D3AE069E60}\",\"cmsSource\":\"web\",\"cmsSite\":\"SeaWorldOrlando\"}";
    return "http://seaworldparks.com/Support/ParkSites/Services/SchedulesService.svc/GetSchedule";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    if (numberOfDownloadedPages > 120 || downloadWaitingTimesDataPOST == null) {
      downloadWaitingTimesDataPOST = null;
      return null;
    }
    JSONObject post = (JSONObject)JSONValue.parse(downloadWaitingTimesDataPOST);
    String date = (String)post.get("date");
    Date d = formatterMonthDayYear.parse(date, new ParsePosition(0));
    if (d == null) {
      WaitingTimesCrawler.trace("date (" + date + ") wrong in post request");
      downloadWaitingTimesDataPOST = null;
      return null;
    }
    d.setTime(d.getTime()+60000*60*24);
    String nextDate = formatterMonthDayYear.format(d);
    downloadWaitingTimesDataContentType = "application/json; charset=utf-8";
    downloadWaitingTimesDataPOST = "{\"date\":\"" + nextDate + "\",\"cmsId\":\"{6BC9EB1F-ADBE-4596-8321-D2D3AE069E60}\",\"cmsSource\":\"web\",\"cmsSite\":\"SeaWorldOrlando\"}";
    return "http://seaworldparks.com/Support/ParkSites/Services/SchedulesService.svc/GetSchedule";
  }
  
  private String getStartTime(String startEndTime) {
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.toLowerCase(), " ", "");
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
  
  private List<String> getStartTimes(String times) {
    List<String> allStartTimes = new ArrayList<String>(30);
    StringTokenizer tokens = new StringTokenizer(times, ",");
    while (tokens.hasMoreTokens()) {
      String time = replace(tokens.nextToken(), " ", "");
      Date d = formatterHour.parse(time, new ParsePosition(0));
      if (d != null) allStartTimes.add(formatterHour2.format(d));
      else WaitingTimesCrawler.trace("time '" + time + "' cannot be parsed");
    }
    return allStartTimes;
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataContentType = null;
    if (downloadWaitingTimesDataPOST == null) { System.out.println("date not found in post request"); return true; }
    JSONObject post = (JSONObject)JSONValue.parse(downloadWaitingTimesDataPOST);
    String date = (String)post.get("date");
    Date d = formatterMonthDayYear.parse(date, new ParsePosition(0));
    if (d == null) { System.out.println("date (" + date + ") wrong in post request"); return true; }
    date = formatterDate.format(d);
    JSONObject page = (JSONObject)JSONValue.parse(calendarPage);
    String openTime = (String)page.get("OpenTime");
    String closeTime = (String)page.get("CloseTime");
    if (openTime == null || closeTime == null) return true;
    if ((Boolean)page.get("IsClosed") == true) return true;
    String startTime = getStartTime(openTime);
    String endTime = getStartTime(closeTime);
    calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, null, null, null, null, false));
    JSONArray shows = (JSONArray)page.get("Shows");
    int n = shows.size();
    for (int i = 0; i < n; ++i) {
      JSONObject show = (JSONObject)shows.get(i);
      String allShowTimes = (String)show.get("Timeline");
      String name = (String)show.get("Title");
      String attractionId = getAttractionId(name);
      if (attractionId != null) {
        if (attractionId.length() > 0) {
          Set<String> aId = new HashSet<String>(2);
          aId.add(attractionId);
          List<String> allStartTimes = getStartTimes(allShowTimes);
          for (String strtTime : allStartTimes) {
            long time = formatterHour2.parse(strtTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
            calendarData.add(aId, new CalendarItem(date, date, strtTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
          }
        }
      } else WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
    }
    /*if (pageNumber > 10) {
      System.out.println(calendarData);
      System.exit(1);
    }*/
    return true;
  }

  public String getWaitingTimesDataURL() {
    return "http://lab.defimobile.com/orlando/rides";
  }

  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (name.startsWith("Pets Ahoy")) return "a103";
    if (name.equals("Clyde and Seamore Take Pirate Island")) return "a104";
    if (name.equals("Clyde & Seamore's Countdown to Christmas")) return "a104";
    if (name.equals("Sea Lions Tonite")) return "a104";
    if (name.startsWith("A'Lure, The Call of the Ocean")) return "a127";
    if (name.startsWith("Blue Horizons")) return "a118";
    if (name.startsWith("One Ocean")) return "a122";
    if (name.startsWith("Shamu Rocks")) return "a122";
    if (name.equals("Skytower")) return "a102";
    if (name.equals("Journey To Atlantis")) return "a119";
    if (name.equals("Turtle Trek")) return "a117";
    if (name.equals("The Polar Express Experience")) return "a123";
    if (name.equals("Wild Arctic Ride")) return "a123";
    if (name.equals("Elmo's Christmas Wish")) return "";
    if (name.equals("Holiday Reflections: Fireworks and Fountain Finale")) return "";
    if (name.equals("O Wondrous Night")) return "";
    if (name.equals("Sea of Trees")) return "";
    if (name.endsWith(" Christmas Miracles")) return "";
    if (name.equals("Waterfront Snow Flurries")) return "";
    if (name.equals("Winter Wonderland on Ice")) return "";
    if (name.equals("Generation Nature LIVE")) return "";
    if (name.equals("Shamu's Celebration: Light Up The Night")) return "";
    return null;
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    closedAttractionIds.clear();
    downloadWaitingTimesDataUserAgent = "SeaWorld/2.7 CFNetwork/548.1.4 Darwin/11.0.0";
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    int i = 0;
    while (true) {
      i = waitingTimesData.indexOf("<title>", i);
      if (i < 0) break;
      i += 7;
      int j = waitingTimesData.indexOf("</title>", i);
      if (j < 0) { System.out.println("Missing end of title"); break; }
      String name = waitingTimesData.substring(i, j);
      i = j+8;
      String attractionId = getAttractionId(name);
      if (attractionId != null) {
        i = waitingTimesData.indexOf("<waitTime>", i);
        if (i < 0) break;
        i += 10;
        j = waitingTimesData.indexOf("</waitTime>", i);
        if (j < 0) { System.out.println("Missing end of wait time"); break; }
        String waitTime = waitingTimesData.substring(i, j);
        if (waitTime.equals("Closed")) {
          if (!attractionId.equals("a123")) closedAttractionIds.add(attractionId); // Special case
        } else if (waitTime.equals("No Wait")) {
          WaitingTimesItem item = new WaitingTimesItem();
          item.waitTime = 0;
          waitingTimes.put(attractionId, item);
        } else if (waitTime.endsWith(" min")) {
          WaitingTimesItem item = new WaitingTimesItem();
          item.waitTime = Integer.parseInt(waitTime.substring(0, waitTime.length()-4));
          waitingTimes.put(attractionId, item);
        } else WaitingTimesCrawler.trace("Wait time " + waitTime + " cannot be parsed for attraction ID " + attractionId);
        i = j+11;
      } else WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
    }
    downloadWaitingTimesDataUserAgent = "";
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
