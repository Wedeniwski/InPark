import java.text.*;
import java.util.*;

public class MovieParkDataParser extends ParkDataParser {
  public MovieParkDataParser() {
    super("dmp", "Europe/Paris");
  }

  public String firstCalendarPage() {
    Calendar rightNow = rightNow();
    String ym = formatterYearMonth.format(rightNow.getTime());
    int month = (ym.charAt(4)-'0')*10 + (ym.charAt(5)-'0');
    int year = (ym.charAt(0)-'0')*1000 + (ym.charAt(1)-'0')*100 + (ym.charAt(2)-'0')*10 + (ym.charAt(3)-'0');
    ym = String.format("%04d-%02d", year, month);
    return "http://movieparkgermany.de/de/infos/oeffnungszeiten?month=" + ym;
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    int i = contentOfPreviousPage.indexOf("<li class=\"date-next\">");
    if (i < 0) return null;
    String s = "<a href=\"http://movieparkgermany.de/de/infos/oeffnungszeiten?month=";
    int j = contentOfPreviousPage.indexOf(s);
    if (j < 0) return null;
    j += s.length();
    int k = contentOfPreviousPage.indexOf('\"', j);
    if (k < 0) return null;
    String ym = contentOfPreviousPage.substring(j, k);
    j = contentOfPreviousPage.indexOf("<td id=\"calendar-" + ym);
    if (j < 0) return null; // no calendar data available
    i = contentOfPreviousPage.indexOf("<a href=\"", i+10);
    if (i < 0) return null;
    i += 9;
    j = contentOfPreviousPage.indexOf('\"', i);
    if (j < 0) return null;
    String nextPage = contentOfPreviousPage.substring(i, j);
    return (nextPage.endsWith(ym))? null : nextPage;
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    /*String s = "action=\"/de/infos/oeffnungszeiten?month=";
    int j = calendarPage.indexOf(s);
    if (j < 0) { WaitingTimesCrawler.trace("Error find calendar shortlink (" + parkId + ')'); return false; }
    j += s.length();
    int k = calendarPage.indexOf('\"', j);
    if (k < 0) { WaitingTimesCrawler.trace("Error find calendar shortlink end (" + parkId + ')'); return false; }
    String ym = calendarPage.substring(j, k);
    int month = (ym.charAt(5)-'0')*10 + (ym.charAt(6)-'0');
    int year = (ym.charAt(0)-'0')*1000 + (ym.charAt(1)-'0')*100 + (ym.charAt(2)-'0')*10 + (ym.charAt(3)-'0');
    int i = calendarPage.indexOf("<div class=\"calendar-calendar\">");
    if (i < 0) { WaitingTimesCrawler.trace("Error find calendar beginning (" + parkId + ')'); return false; }
    for (int day = 1; day <= 31; ++day) {
      s = "dateTime\" content=\"" + ym + '-' + String.format("%02dT", day);
      j = calendarPage.indexOf(s, i);
      if (j >= 0) {
        s = "rdfs:label skos:prefLabel\">";
        i = calendarPage.indexOf(s, j+s.length());
        if (i >= 0) {
          i += s.length();
          if (Character.isDigit(calendarPage.charAt(i))) {
            j = calendarPage.indexOf(' ', i);
            if (j >= 0) {
              String date = String.format("%02d.%02d.%04d", day, month, year);
              String startTime = replace(replace(calendarPage.substring(i, j), "%3A", ":"), ".", ":");
              i = calendarPage.indexOf(' ', j+1);
              if (i >= 0) {
                ++i;
                j = calendarPage.indexOf("</a", i);
                if (j >= 0) {
                  k = calendarPage.indexOf(' ', i);
                  if (k >= 0 && k < j) j = k;
                  String endTime = calendarPage.substring(i, j);
                  if (endTime.endsWith(" Uhr")) endTime = calendarPage.substring(i, j-4);
                  endTime = replace(replace(endTime, "%3A", ":"), ".", ":");
                  calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, null, null, null, null, false));
                }
              }
            }
          }
        } else WaitingTimesCrawler.trace("missing delimiter after dateTime/content (" + parkId + ')');
      }
    }*/
    //
    //System.exit(1);
    
    //System.out.println("DEBUG park entrances: " + parkEntrances);
    calendarData.add(parkEntrances, new CalendarItem("01.05.2016", "10.07.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("11.07.2016", "21.08.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("22.08.2016", "04.09.2013", "10:00", "18:00", null, null, null, null, false));
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
