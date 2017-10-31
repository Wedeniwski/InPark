import java.text.*;
import java.util.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class SeaWorldDataParser extends ParkDataParser {
  public SeaWorldDataParser(String parkId) {
    super(parkId, (parkId.equals("usswofl"))? "America/New_York" : "America/Los_Angeles");
  }

  public String firstCalendarPage() {
    setSSLContext();
    Calendar rightNow = rightNow();
    downloadWaitingTimesDataUserAgent = "RestSharp 104.1.0.0";
    downloadWaitingTimesDataProperties.put("Authorization", "Basic c2Vhd29ybGQ6MTM5MzI4ODUwOA==");
    downloadWaitingTimesDataProperties.put("app-user-id", "4f20989c-dff5-40d9-9e30-9832c1b23249");
    downloadWaitingTimesDataProperties.put("app-id", "SW_5.3.1");
    downloadWaitingTimesDataAccept = "application/json";
    final String pId = (parkId.equals("usswofl"))? "SW_MCO" : "SW_SAN";
    return "https://seas.te2.biz/v1/rest/venue/" + pId + "/hours/" + formatterYearMonthDay.format(rightNow.getTime()) + "?days=100";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    return null;
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
    formatter.setTimeZone(getTimeZone());
    Set<String> parkEntrances = getParkEntrances();
    JSONArray openings = (JSONArray)JSONValue.parse(calendarPage);
    int n = openings.size();
    for (int i = 0; i < n; ++i) {
      JSONObject opening = (JSONObject)openings.get(i);
      if ((Boolean)opening.get("isOpen") == true) {
        String date = formatterDate.format(formatterYearMonthDay.parse((String)opening.get("date"), new ParsePosition(0)));
        String openTime = (String)opening.get("open");
        if (openTime != null) {
          openTime = formatterHour2.format(formatter.parse(openTime, new ParsePosition(0)));
          String closeTime = (String)opening.get("close");
          if (closeTime != null) {
            closeTime = formatterHour2.format(formatter.parse(closeTime, new ParsePosition(0)));
            calendarData.add(parkEntrances, new CalendarItem(date, date, openTime, closeTime, null, null, null, null, false));
          } else WaitingTimesCrawler.trace("Wrong close time format \'" + closeTime + "\' (" + parkId + ')');
        } else WaitingTimesCrawler.trace("Wrong open time format \'" + openTime + "\' (" + parkId + ')');
      }
    }
    Calendar rightNow = rightNow();
    downloadWaitingTimesDataUserAgent = "RestSharp 104.1.0.0";
    downloadWaitingTimesDataProperties.put("Authorization", "Basic c2Vhd29ybGQ6MTM5MzI4ODUwOA==");
    downloadWaitingTimesDataProperties.put("app-user-id", "4f20989c-dff5-40d9-9e30-9832c1b23249");
    downloadWaitingTimesDataProperties.put("app-id", "SW_5.3.1");
    downloadWaitingTimesDataAccept = "application/json";
    final String pId = (parkId.equals("usswofl"))? "SW_MCO" : "SW_SAN";
    String date = formatterDate.format(rightNow.getTime());
    String page = downloadPageHasContent("https://seas.te2.biz/v1/rest/venue/" + pId + "/shows/" + formatterYearMonthDay.format(rightNow.getTime()), "UTF-8");
    JSONArray shows = (JSONArray)JSONValue.parse(page);
    n = shows.size();
    for (int i = 0; i < n; ++i) {
      JSONObject show = (JSONObject)shows.get(i);
      String name = (String)show.get("title");
      String attractionId = getAttractionId(name);
      if (attractionId != null) {
        if (attractionId.length() > 0) {
          JSONObject schedule = (JSONObject)show.get("schedule");
          JSONArray entries = (JSONArray)schedule.get("entries");
          int m = entries.size();
          for (int j = 0; j < m; ++j) {
            JSONObject entry = (JSONObject)entries.get(j);
            String startTime = (String)entry.get("start");
            if (startTime != null) {
              startTime = formatterHour2.format(formatter.parse(startTime, new ParsePosition(0)));
              String endTime = (String)entry.get("end");
              if (endTime != null) {
                endTime = formatterHour2.format(formatter.parse(endTime, new ParsePosition(0)));
                Set<String> aId = new HashSet<String>(2);
                aId.add(attractionId);
                calendarData.add(aId, new CalendarItem(date, date, startTime, endTime, null, null, null, null, false));
              } else WaitingTimesCrawler.trace("Wrong end time format \'" + endTime + "\' (" + attractionId + " / " + parkId + ')');
            } else WaitingTimesCrawler.trace("Wrong start time format \'" + startTime + "\' (" + attractionId + " / " + parkId + ')');
          }
        }
      } else WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
    }
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  public String getWaitingTimesDataURL() {
    downloadWaitingTimesDataUserAgent = "RestSharp 104.1.0.0";
    downloadWaitingTimesDataProperties.put("Authorization", "Basic c2Vhd29ybGQ6MTM5MzI4ODUwOA==");
    downloadWaitingTimesDataProperties.put("app-user-id", "4f20989c-dff5-40d9-9e30-9832c1b23249");
    downloadWaitingTimesDataProperties.put("app-id", "SW_5.3.1");
    downloadWaitingTimesDataAccept = "application/json";
    final String pId = (parkId.equals("usswofl"))? "SW_MCO" : "SW_SAN";
    return "https://seas.te2.biz/v1/rest/venue/" + pId + "/poi/all/status";
  }

  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (parkId.equals("usswofl")) {
      if (name.startsWith("Pets Ahoy")) return "a103";
      if (name.startsWith("Antarctica: Empire of the Penguin")) return "a105";
      if (name.startsWith("Manta") && name.length() == 6) return "a107";
      if (name.startsWith("Journey to Atlantis")) return "a119";
      if (name.startsWith("Kraken") && name.length() == 7) return "a121";
      if (name.startsWith("Wild Arctic") && name.endsWith(" Ride")) return "a123";
      if (name.startsWith("Shamu Express")) return "a139";
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
    } else {
      if (name.startsWith("One Ocean")) return "a104";
      if (name.startsWith("Blue Horizons")) return "a120";
      if (name.equals("Sea Lions LIVE")) return "a116";
      if (name.equals("Pets Rule!")) return "a123";
      if (name.equals("Pets Rule Christmas")) return "a123";
      if (name.startsWith("Madagascar Live")) return "a113";
      if (name.startsWith("Killer Whales: Up Close")) return "";
      if (name.startsWith("Summer Vibes")) return "";
      if (name.startsWith("Dolphin Days")) return "";
      if (name.startsWith("Cirque de la Mer")) return "";
      if (name.startsWith("Shamu's Celebration: Light Up the Night")) return "";
      if (name.startsWith("Sea Lions Tonite")) return "";
      if (name.startsWith("Celebrate the Wonder Fireworks")) return "";
      //12/22/2014 04:33:28 No attraction ID defined for Shamu Christmas Miracles (usswsdca)
      //12/22/2014 04:33:28 No attraction ID defined for Dolphin Island Christmas (usswsdca)
      //12/22/2014 04:33:28 No attraction ID defined for Clyde & Seamore's Christmas Special (usswsdca)
    }
    return null;
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    closedAttractionIds.clear();
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    JSONArray waitingTimesArray = (JSONArray)JSONValue.parse(waitingTimesData);
    int n = waitingTimesArray.size();
    for (int i = 0; i < n; ++i) {
      JSONObject wTime = (JSONObject)waitingTimesArray.get(i);
      JSONObject status = (JSONObject)wTime.get("status");
      String name = (String)wTime.get("label");
      Long lTime = (Long)status.get("waitTime");
      if (lTime != null && name != null) {
        String attractionId = getAttractionId(name);
        if (attractionId != null) {
          if (attractionId.length() > 0) {
            if ((Boolean)status.get("isOpen") == true) {
              int waitTime = lTime.intValue();
              if (waitTime >= 0) {
                WaitingTimesItem item = new WaitingTimesItem();
                item.waitTime = waitTime;
                waitingTimes.put(attractionId, item);
              } else WaitingTimesCrawler.trace("Unknown wait time " + waitTime + " for " + attractionId + " (" + parkId + ')');
            } else {
              closedAttractionIds.add(attractionId);
            }
          }
        } else WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
      }
    }
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
