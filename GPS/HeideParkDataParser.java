import java.text.*;
import java.util.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class HeideParkDataParser extends ParkDataParser {
  public HeideParkDataParser() {
    super("dhep", "Europe/Paris");
  }

  public String firstCalendarPage() {
    downloadWaitingTimesDataUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1";
    //return "http://www.heide-park.de/heide-park/park/oeffnungszeiten/";
    return "http://www.heide-park.de/infos/oeffnungszeiten-anreise.html";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    downloadWaitingTimesDataUserAgent = "";
    return null;
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    //System.out.println("DEBUG park entrances: " + parkEntrances);
    /*
     <script>
     var openingHours = [{"date":"31.10.2015","entries":[{"title":"Heide Park","open":"10","close":"22","entryDate":"31.10.2015","entryText":"10-22","dateTs":1446246000},{"title":"Kletterpfad","open":0,"close":0,"entryDate":"31.10.2015","entryText":"geschlossen","dateTs":1446246000}],"today":1},{"date":"01.11.2015","entries":[{"title":"Heide Park","open":"10","close":"17","entryDate":"01.11.2015","entryText":"10-17","dateTs":1446332400},{"title":"Kletterpfad","open":0,"close":0,"entryDate":"01.11.2015","entryText":"geschlossen","dateTs":1446332400}],"tomorrow":1}]
     </script>
     */
    calendarData.add(parkEntrances, new CalendarItem("19.03.2016", "24.03.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("25.03.2016", "28.03.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("29.03.2016", "01.04.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("02.04.2016", "03.04.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("04.04.2016", "08.04.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("09.04.2016", "10.04.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("11.04.2016", "15.04.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("16.04.2016", "17.04.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("18.04.2016", "22.04.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("23.04.2016", "24.04.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("25.04.2016", "29.04.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("30.04.2016", "01.05.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("02.05.2016", "04.05.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("05.05.2016", "08.05.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("09.05.2016", "13.05.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("14.05.2016", "17.05.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("18.05.2016", "20.05.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("21.05.2016", "22.05.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("23.05.2016", "27.05.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("28.05.2016", "29.05.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("30.05.2016", "03.06.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("04.06.2016", "05.06.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("06.06.2016", "10.06.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("11.06.2016", "12.06.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("13.06.2016", "17.06.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("18.06.2016", "19.06.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("20.06.2016", "22.06.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("23.06.2016", "31.08.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("01.09.2016", "02.06.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("03.09.2016", "04.09.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("05.09.2016", "09.09.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("10.09.2016", "11.09.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("12.09.2016", "16.09.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("17.09.2016", "18.09.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("19.09.2015", "23.09.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("24.09.2016", "25.09.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("26.09.2016", "30.09.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("01.10.2016", "03.10.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("04.10.2016", "07.10.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("08.10.2016", "09.10.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("10.10.2016", "13.10.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("14.10.2016", "16.10.2016", "10:00", "22:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("17.10.2016", "20.10.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("21.10.2016", "23.10.2016", "10:00", "22:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("24.10.2016", "27.10.2016", "10:00", "17:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("28.10.2016", "30.10.2016", "10:00", "22:00", null, null, null, null, false));
    String shows = downloadPageHasContent("http://www.heide-park.de/heide-park/?type=1000&desktop=1&callback=Ext.data.JsonP.callback2&_dc=" + System.currentTimeMillis(), "UTF-8");
    String s = "Ext.data.JsonP.callback2(";
    if (shows.startsWith(s) && shows.endsWith(");")) {
      Calendar rightNow = rightNow();
      String today = String.format("%02d.%02d.%04d", rightNow.get(Calendar.DAY_OF_MONTH), rightNow.get(Calendar.MONTH)+1, rightNow.get(Calendar.YEAR));
      shows = shows.substring(s.length(), shows.length()-2);
      JSONObject obj = (JSONObject)JSONValue.parse(shows);
      // ToDo: hours
      JSONArray array = (JSONArray)obj.get("shows");
      int n = array.size();
      for (int i = 0; i < n; ++i) {
        JSONObject info = (JSONObject)array.get(i);
        String id = (String)info.get("show_title");
        String attractionId = getAttractionId(id);
        if (attractionId == null) {
          WaitingTimesCrawler.trace("attraction " + id + " (" + parkId + ") unknown");
        } else if (attractionId.length() > 0) {
          JSONArray showTimes = (JSONArray)info.get("show_times");
          int m = showTimes.size();
          for (int j = 0; j < m; ++j) {
            // ToDo: double check correct date == today!
            String showDateTime = (String)showTimes.get(j);
            int duration = getAttractionDuration(attractionId);
            if (duration > 0) {
              if (showDateTime.length() > 0) {
                Date eventStartTime = formatterHour2.parse(showDateTime, new ParsePosition(0));
                if (eventStartTime != null) {
                  long time = eventStartTime.getTime()+60000*duration;
                  Set<String> aIds = new HashSet<String>(2);
                  aIds.add(attractionId);
                  calendarData.add(aIds, new CalendarItem(today, today, formatterHour2.format(eventStartTime), formatterHour2.format(new Date(time)), null, null, null, null, false));
                } else WaitingTimesCrawler.trace("show times \'" + showDateTime + "\' could not be parsed for attraction " + id);
              }
            } else WaitingTimesCrawler.trace("duration not defined for attraction " + id);
          }
        }
      }
    } else WaitingTimesCrawler.trace("response structure unknown (" + parkId + ')');
    return true;
  }

  protected String getAttractionId(String name) {
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (name.equals("colossos")) return "a01";
    if (name.equals("mountain_rafting")) return "a02";
    if (name.equals("desert_race")) return "a03";
    if (name.equals("limit")) return "a04";
    if (name.equals("big_loop")) return "a05";
    if (name.equals("bobbahn")) return "a08";
    if (name.equals("wildwasserbahn")) return "a11";
    if (name.equals("Piraten Arena")) return "a51";
    if (name.equals("krake")) return "a63";
    if (name.equals("krake_lebt")) return "a64";
    if (name.equals("Madagascar LIVE!")) return "a65";
    if (name.equals("flug_der_daemonen")) return "a66";
    if (name.equals("Piratenshow - Das Gold von Port Royal")) return "";
    if (name.equals("Glowpainting")) return "";
    if (name.equals("KRAKE lebt! Kids")) return "";
    if (name.equals("Foto mit Wumbo")) return "";
    return null;
  }
  
  public String getWaitingTimesDataURL() {
    return "http://www.heide-park.de/heide-park/?type=1001&_dc=" + System.currentTimeMillis() + "&page=1&start=0&limit=25&callback=Ext.data.JsonP.callback3";
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    closedAttractionIds.clear();
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    if (waitingTimes == null) return null;
    String s = "Ext.data.JsonP.callback3(";
    if (waitingTimesData.startsWith(s) && waitingTimesData.endsWith(");")) {
      waitingTimesData = waitingTimesData.substring(s.length(), waitingTimesData.length()-2);
      JSONObject obj = (JSONObject)JSONValue.parse(waitingTimesData);
      s = (String)obj.get("success");
      if (s.equals("true")) {
        JSONArray array = (JSONArray)obj.get("rides");
        int n = array.size();
        for (int i = 0; i < n; ++i) {
          JSONObject info = (JSONObject)array.get(i);
          String id = (String)info.get("alias");
          String attractionId = getAttractionId(id);
          if (attractionId == null) {
            WaitingTimesCrawler.trace("attraction " + id + " (" + parkId + ") unknown");
          } else if (attractionId.length() > 0) {
            String waitingTime = (String)info.get("short");
            if (waitingTime.equals("zu") || waitingTime.equals("Pause")) {
              closedAttractionIds.add(attractionId);
            } else if (!waitingTime.equals("offen") && !waitingTime.startsWith("Ab ") && !waitingTime.startsWith("Spaeter")) {
              if (waitingTime.startsWith("-") || waitingTime.startsWith("+")) waitingTime = waitingTime.substring(1);
              waitingTime = waitingTime.trim();
              WaitingTimesItem item = new WaitingTimesItem();
              item.waitTime = Integer.parseInt(waitingTime);
              waitingTimes.put(attractionId, item);
            }
          }
        }
      }
    } else WaitingTimesCrawler.trace("response structure unknown (" + parkId + ')');
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
