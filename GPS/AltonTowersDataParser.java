import java.text.*;
import java.util.*;
import java.util.regex.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class AltonTowersDataParser extends ParkDataParser {
  public AltonTowersDataParser() {
    super("ukatst", "Europe/London");
  }

  public String firstCalendarPage() {
    return "http://www.altontowers.com/Umbraco/Api/Calendar/GetAllOpeningTimes";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    return null;
  }

  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
    formatter.setTimeZone(getTimeZone());
    Set<String> parkEntrances = getParkEntrances();
    JSONArray openings = (JSONArray)JSONValue.parse(calendarPage);
    int n = openings.size();
    for (int i = 0; i < n; ++i) {
      JSONObject info = (JSONObject)openings.get(i);
      Object type = info.get("Type");
      if (type != null && type.equals("ThemePark")) {
        JSONArray opening = (JSONArray)info.get("OpeningHours");
        int m = opening.size();
        for (int j = 0; j < m; ++j) {
          JSONObject openHours = (JSONObject)opening.get(j);
          String dateFrom = formatterDate.format(formatter.parse((String)openHours.get("From"), new ParsePosition(0)));
          String dateTo = formatterDate.format(formatter.parse((String)openHours.get("To"), new ParsePosition(0)));
          String openTime = (String)openHours.get("Open");
          if (openTime != null) {
            if (!openTime.equals("CLOSED")) {
              // "Open": "10-4"
              // "Open": "10am - 4.30pm"
              int k = openTime.indexOf('-');
              if (k > 0) {
                String timeFrom = openTime.substring(0, k).trim().replace('.', ':');
                if (!timeFrom.endsWith("m")) timeFrom += "am";
                Date d = (timeFrom.indexOf(':') >= 0)? formatterHour.parse(timeFrom, new ParsePosition(0)) : formatterHourOnly.parse(timeFrom, new ParsePosition(0));
                if (d != null) {
                  timeFrom = formatterHour2.format(d);
                  String timeTo = openTime.substring(k+1).trim().replace('.', ':');
                  if (!timeTo.endsWith("m")) timeTo += "pm";
                  d = (timeTo.indexOf(':') >= 0)? formatterHour.parse(timeTo, new ParsePosition(0)) : formatterHourOnly.parse(timeTo, new ParsePosition(0));
                  if (d != null) {
                    timeTo = formatterHour2.format(d);
                    calendarData.add(parkEntrances, new CalendarItem(dateFrom, dateTo, timeFrom, timeTo, null, null, null, null, false));
                  } else WaitingTimesCrawler.trace("Wrong time to format \'" + timeTo + "\' (" + parkId + ')');
                } else WaitingTimesCrawler.trace("Wrong time from format \'" + timeFrom + "\' (" + parkId + ')');
              } else WaitingTimesCrawler.trace("Wrong open time to format \'" + openTime + "\' (" + parkId + ')');
            }
          } else WaitingTimesCrawler.trace("Wrong open time from format \'" + openTime + "\' (" + parkId + ')');
        }
      }
    }
    downloadWaitingTimesDataContentType = "multipart/form-data; boundary=SCAREBOUNDARY23493284023573948057AT54764TPN";
    downloadWaitingTimesDataUserAgent = "Alton%20Towers/1.0.4 CFNetwork/672.1.14 Darwin/14.0.0";
    downloadWaitingTimesDataPOST = "\n--SCAREBOUNDARY23493284023573948057AT54764TPN--\n";
    String showTimes = waitingTimesData = downloadPageHasContent("http://scarefestsounds.altontowers.com/api/get-features?obj", "UTF-8");
    downloadWaitingTimesDataContentType = null;
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataPOST = null;
    int i = showTimes.indexOf("The Pirates of Mutiny Bay");
    if (i > 0) {
      String attractionId = "a115";  // fix!
      Set<String> aIds = new HashSet<String>(2);
      aIds.add(attractionId);
      i = showTimes.indexOf("<h1>Every day at ", i);
      if (i > 0) {
        Calendar rightNow = rightNow();
        String today = String.format("%02d.%02d.%04d", rightNow.get(Calendar.DAY_OF_MONTH), rightNow.get(Calendar.MONTH)+1, rightNow.get(Calendar.YEAR));
        i += 17;
        int j = showTimes.indexOf('<', i);
        if (j > 0) {
          SimpleDateFormat fHour = new SimpleDateFormat("h.mma");
          String times = replace(replace(showTimes.substring(i, j), "pm, ", "pm"), "pm and ", "pm");
          i = 0;
          while (true) {
            j = times.indexOf("pm", i);
            if (j < 0) break;
            j += 2;
            Date d = fHour.parse(times.substring(i, j), new ParsePosition(0));
            if (d == null) WaitingTimesCrawler.trace("Times: '" + times + "' cannot be parsed");
            else {
              String startTime = formatterHour2.format(d);
              int duration = getAttractionDuration(attractionId);
              if (duration > 0) {
                long time = d.getTime()+60000*duration;
                calendarData.add(aIds, new CalendarItem(today, today, formatterHour2.format(d), formatterHour2.format(new Date(time)), null, null, null, null, false));
              } else WaitingTimesCrawler.trace("duration not defined for attraction " + attractionId);
            }
            i = j;
          }
        }
      }
    }
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  public String getWaitingTimesDataURL() {
    downloadWaitingTimesDataContentType = "application/json";
    downloadWaitingTimesDataPOST = "";
    return "http://scarefestsounds.altontowers.com/api/queue-times";
  }

  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (name.equals("River Rapids")) return "a117";
    if (name.equals("Mine Train")) return "a118";
    if (name.equals("Postman Pat Parcel Post")) return "a120";
    if (name.equals("Charlie and Lola's Moonsquirters and Green Drops")) return "";
    if (name.equals("Mr  Bloom's Allotment")) return "";
    if (name.equals("Octonauts Rollercoaster Adventure")) return "";
    return null;
  }

  public Map<String, WaitingTimesItem> parseTimes(String waitingTimesData, Map<String, WaitingTimesItem> waitingTimes, boolean calendarDataUpdate) {
    if (waitingTimesData == null) return null;
    int i = waitingTimesData.indexOf("\":\"");
    int j = waitingTimesData.indexOf("\"}", i+1);
    if (i < 0 || j < 0) {
      WaitingTimesCrawler.trace("challenge in wait time request: '" + waitingTimesData + "' cannot be parsed");
      return null;
    }
    String challenge = waitingTimesData.substring(i+3, j);
    String response = ParkDataThread.hashCode("ufkPRqH3AmqwWMr66nyUzepe" + challenge);
    downloadWaitingTimesDataContentType = "multipart/form-data; boundary=SCAREBOUNDARY23493284023573948057AT54764TPN";
    downloadWaitingTimesDataUserAgent = "Alton%20Towers/1.0.4 CFNetwork/672.1.14 Darwin/14.0.0";
    downloadWaitingTimesDataPOST = "\n--SCAREBOUNDARY23493284023573948057AT54764TPN\nContent-Disposition: form-data; name=\"challenge\"\n\n" + challenge + "\n--SCAREBOUNDARY23493284023573948057AT54764TPN\nContent-Disposition: form-data; name=\"response\"\n\n" + response + "\n--SCAREBOUNDARY23493284023573948057AT54764TPN--\n";
    waitingTimesData = downloadPageHasContent("http://scarefestsounds.altontowers.com/api/queue-times", "UTF-8");
    downloadWaitingTimesDataContentType = null;
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataPOST = null;
    closedAttractionIds.clear();
    JSONArray array = (JSONArray)JSONValue.parse(waitingTimesData);
    int n = array.size();
    for (i = 0; i < n; ++i) {
      JSONObject info = (JSONObject)array.get(i);
      String status = (String)info.get("status");
      if (status != null) {
        String name = (String)info.get("ride");
        String attractionId = getAttractionId(name);
        if (attractionId == null) WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
        else if (attractionId.length() > 0) {
          if (status.equals("open")) {
            int waitTime = ((Number)info.get("time")).intValue();
            if (waitTime <= 180 && waitingTimes != null && attractionId.length() > 0) {
              WaitingTimesItem item = new WaitingTimesItem();
              item.waitTime = waitTime;
              waitingTimes.put(attractionId, item);
            }
          } else if (status.equals("closed")) {
            closedAttractionIds.add(attractionId);
          }
        }
      }
    }
    return waitingTimes;
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    closedAttractionIds.clear();
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    return parseTimes(waitingTimesData, waitingTimes, false);
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
