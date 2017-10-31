import java.text.*;
import java.util.*;

public class PhantasialandDataParser extends ParkDataParser {
  public PhantasialandDataParser() {
    super("dphl", "Europe/Paris");
  }

  public String firstCalendarPage() {
    return "http://www.phantasialand.de/de/park/seien-sie-unser-gast/oeffnungszeiten/";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    return null;
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    /*int is = calendarPage.indexOf("-oeffnungszeiten-sommer-");
    int iw = calendarPage.indexOf("-oeffnungszeiten-winter-");
    if (is < 0 || iw < 0) {
      WaitingTimesCrawler.trace("sommer or winter identifier not found (" + parkId + ')');
      return false;
    }
    boolean winter = false;
    if (iw < is) {
      int i = is;
      is = iw; iw = i;
      winter = true;
    }
    int i = calendarPage.indexOf("<div class=\"title\">Legende</div>", is);
    if (i < 0) {
      WaitingTimesCrawler.trace("legend missing (" + parkId + ')');
      return false;
    }
    int j = calendarPage.indexOf("</li></ul></div></div>", i);
    if (j < 0) {
      WaitingTimesCrawler.trace("end of legend missing (" + parkId + ')');
      return false;
    }
    while (true) {
      String s = "<span class=\"";
      i = calendarPage.indexOf(s, i);
      if (i >= j || i < 0) break;
      i += s.length();
      int k = calendarPage.indexOf('\"', i);
      if (k < 0) break;
      String c = s.substring(i, k);
      s = "</span>";
      i = calendarPage.indexOf(s, k);
      if (i >= j || i < 0) break;
      i += s.length();
      String beginTime = null;
      String endTime = null;
      if (s.charAt(i).isDigit() && s.charAt(i+1).isDigit() && s.charAt(i+3).isDigit() && s.charAt(i+4).isDigit() && s.charAt(i+10).isDigit() && s.charAt(i+11).isDigit() && s.charAt(i+13).isDigit() && s.charAt(i+14).isDigit()) {
        beginTime = s.substring(i, i+5)
        endTime = s.substring(i+10, i+15)
      } else if (s.charAt(i).isDigit() && s.charAt(i+2).isDigit() && s.charAt(i+3).isDigit() && s.charAt(i+9).isDigit() && s.charAt(i+10).isDigit() && s.charAt(i+12).isDigit() && s.charAt(i+13).isDigit()) {
        beginTime = "0" + s.substring(i, i+4)
        endTime = s.substring(i+9, i+14)
      }
    }*/
    
    //"</ul></div>" ... "											<div class=\"month \">"
    // <h3 style="text-align: center;">Öffnungszeiten Wintertraum 2015/2016<br>21. November 2015 - 17. Januar 2016</h3></div><a class="anchor" id="kalender-100-oeffnungszeiten-winter-5929"></a>	<div class="module calendar" data-module="calendar"><div class="legend"><div class="legend-inner">
    // <div class="title">Legende</div><ul><li><span class="bg-cyan"></span>11:00 bis 20:00 Uhr</li><li><span class="bg-purple"></span>11:00 bis 18:00 Uhr</li><li><span class="bg-grey"></span>Geschlossen</li></ul></div></div>
    // <time datetime="2015-11-01">1</time></li>
    // <li class="num-1 grey"> <span class="date-color bg-grey"></span>
    // <li class="num-1 cyan"> <span class="date-color bg-cyan"></span> <time datetime="2015-11-21">21</time></li>
    // <li class="num-1 cyan"> <span class="date-color bg-cyan"></span> <time datetime="2015-11-22">22</time></li>
    // <li class="num-1 grey"> <span class="date-color bg-grey"></span> <time datetime="2015-11-23">23</time></li>
    
    //System.out.println("DEBUG park entrances: " + parkEntrances);
    calendarData.add(parkEntrances, new CalendarItem("19.03.2016", "01.07.2016", "09:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("02.07.2016", "28.08.2016", "09:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("29.08.2016", "01.11.2016", "09:00", "18:00", null, null, null, null, false));
    //calendarData.add(parkEntrances, new CalendarItem("25.12.2015", "30.12.2015", "11:00", "20:00", null, null, null, null, false));
    //calendarData.add(parkEntrances, new CalendarItem("31.12.2015", "31.12.2015", "11:00", "18:00", null, null, null, null, false));
    //calendarData.add(parkEntrances, new CalendarItem("02.01.2016", "10.01.2016", "11:00", "20:00", null, null, null, null, false));
    //calendarData.add(parkEntrances, new CalendarItem("16.01.2016", "17.01.2016", "11:00", "20:00", null, null, null, null, false));
    return true;
  }

  public String getWaitingTimesDataURL() {
    return null;
  }

  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    return null;
  }

  public Set<String> closedAttractionIds() {
    return null;
  }
}
