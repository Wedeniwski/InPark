import java.text.*;
import java.util.*;
import java.util.regex.*;

public class UniversalHollywoodDataParser extends ParkDataParser {
  public UniversalHollywoodDataParser() {
    super("usushca", "America/Los_Angeles");
  }

  public String firstCalendarPage() {
    return "http://m.universalstudioshollywood.com/hours";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
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
    if (startEndTime.startsWith("not available today") || startEndTime.startsWith("all day event") || startEndTime.startsWith("special events")) return null;
    if (startEndTime.startsWith("open!")) return null; // ToDo!
    if (startEndTime.startsWith("last show ")) startEndTime = startEndTime.substring(10);
    if (startEndTime.startsWith("last show: ")) startEndTime = startEndTime.substring(11);
    startEndTime = startEndTime.toLowerCase();
    int i = posEndTime(startEndTime, false);
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.substring(0, i), " ", "");
    if (!startEndTime.endsWith("pm") && !startEndTime.endsWith("am")) startEndTime = startEndTime + "pm";
    if (startEndTime.indexOf("a.m.") >= 0) startEndTime = replace(startEndTime, "a.m.", "am");
    else if (startEndTime.indexOf("am") < 0) startEndTime = replace(startEndTime, "a", "am");
    if (startEndTime.indexOf("p.m.") >= 0) startEndTime = replace(startEndTime, "p.m.", "pm");
    else if (startEndTime.indexOf("pm") < 0) startEndTime = replace(startEndTime, "p", "pm");
    Date d = (startEndTime.indexOf(':') > 0)? formatterHour.parse(startEndTime, new ParsePosition(0))
    : formatterHourOnly.parse(startEndTime, new ParsePosition(0));
    if (d == null) {
      WaitingTimesCrawler.trace("getStartTime: '" + originStartEndTime + "' cannot be parsed (" + parkId + ')');
      return null;
    }
    return formatterHour2.format(d);
  }
  
  /*private String getEndTime(String startEndTime) {
    if (startEndTime.startsWith("not available today") || startEndTime.startsWith("all day event") || startEndTime.startsWith("special events")) return null;
    int i = posEndTime(startEndTime, true);
    if (i < 0) {
      WaitingTimesCrawler.trace("getEndTime: '" + startEndTime + "' cannot be parsed");
      return null;
    }
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.substring(i), " ", "");
    if (!startEndTime.endsWith("pm") && !startEndTime.endsWith("am")) startEndTime = startEndTime + "pm";
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
  }*/
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    final String[] months = new String[]{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
    int pMonth = 0;
    String date = getCurrentDate();
    int year = Integer.parseInt(date.substring(date.length()-4));
    int i = 0;
    Set<String> parkEntrances = getParkEntrances();
    while (true) {
      i = calendarPage.indexOf("<td class=\"day\">", i);
      if (i < 0) break;
      i += 16;
      int j = calendarPage.indexOf("</td>", i);
      if (j < 0) {
        WaitingTimesCrawler.trace("date not identified");
        break;
      }
      if (i == j) continue;
      i += 5;
      int month = 0;
      date = calendarPage.substring(i, j);
      while (month < months.length && !date.startsWith(months[month])) ++month;
      if (month >= months.length) {
        WaitingTimesCrawler.trace("Unknown month: " + date);
        return false;
      }
      i += months[month].length()+1;
      ++month;
      if (pMonth < month) pMonth = month;
      else if (pMonth > month) { pMonth = month; ++year; }
      int day = 0;
      while (i < j && Character.isDigit(calendarPage.charAt(i))) {
        day = day*10 + (calendarPage.charAt(i)-'0');
        ++i;
      }
      if (day == 0) {
        WaitingTimesCrawler.trace("Unknown date: " + date);
        return false;
      }
      date = String.format("%02d.%02d.%04d", day, month, year);
      i = calendarPage.indexOf("<td class=\"hours\">", j+5);
      if (i < 0) {
        WaitingTimesCrawler.trace("hours pos not found");
        break;
      }
      i += 18;
      j = calendarPage.indexOf("</td>", i);
      if (j < 0) {
        WaitingTimesCrawler.trace("hours not identified");
        break;
      }
      String startEndTime = calendarPage.substring(i, j);
      int idx = startEndTime.indexOf(" - ");
      if (idx <= 0 || idx+1 >= startEndTime.length()) continue;
      String startTime = getStartTime(startEndTime.substring(0, idx));
      String endTime = getStartTime(startEndTime.substring(idx+3));
      if (startTime != null && endTime != null) calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, null, null, null, null, false));
      i = j;
    }
    parseTimes(downloadPageHasContent("http://m.universalstudioshollywood.com/showsandcharacters", "UTF-8"), null, true);
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  public String getWaitingTimesDataURL() {
    return "http://m.universalstudioshollywood.com/waittimes";
  }

  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (name.equals("Transformers")) return "a112";
    if (name.startsWith("Studio Tour")) return "a107"; // Studio Tour (last tram: 7:45)
    if (name.equals("Simpsons")) return "a108";
    if (name.equals("Revenge of the Mummy")) return "a111";
    if (name.equals("Jurassic Park")) return "a110";
    if (name.equals("WaterWorld")) return "a101";
    if (name.equals("Animal Actors")) return "a105";
    if (name.equals("Universal Animal Actors")) return "a105";
    if (name.equals("Blues Brothers")) return "a103";
    if (name.equals("Curious George")) return "a116";
    if (name.equals("Despicable Me")) return "a118";
    if (name.equals("Marilyn Monroe")) return "";
    if (name.equals("Dancing Characters")) return "";
    if (name.equals("Meet the Grinch and Max")) return "";
    if (name.equals("Beetlejuice")) return "";
    if (name.equals("Frankenstein")) return "";
    if (name.equals("Dracula")) return "";
    if (name.equals("Can Can Dancers")) return "";
    if (name.equals("Santa Dolls")) return "";
    if (name.equals("Diamond Doll Dancers")) return "";
    if (name.equals("Dora")) return "";
    if (name.equals("City Beat")) return "";
    if (name.equals("The Simpsons")) return "ch105";
    if (name.equals("Donkey")) return "";
    if (name.equals("Shrek")) return "ch101";
    if (name.equals("Spongebob")) return "ch102";
    if (name.equals("Mummy Guards")) return "";
    if (name.equals("Scooby &#038; Shaggy")) return "";
    if (name.equals("Despicable Me Minions")) return "";
    if (name.equals("The Grinch Photo Spot")) return "";
    if (name.equals("All Access Band")) return "";
    if (name.equals("Sebastian &#8211; Piano Player")) return "";
    if (name.equals("Martha May and the Who Dolls")) return "";
    if (name.equals("Wholiday Singers")) return "";
    if (name.equals("Krusty the Clown")) return "";
    if (name.equals("Sideshow Bob")) return "";
    return null;
  }

  public Map<String, WaitingTimesItem> parseTimes(String waitingTimesData, Map<String, WaitingTimesItem> waitingTimes, boolean calendarDataUpdate) {
    if (waitingTimesData == null) return null;
    String currentDate = getCurrentDate();
    int i = 0;
    while (true) {
      i = waitingTimesData.indexOf("<td class=\"ride\">", i);
      if (i < 0) break;
      i += 17;
      int j = waitingTimesData.indexOf("</td>", i);
      if (j < 0) {
        WaitingTimesCrawler.trace("wait time end identifier not found");
        return null;
      }
      String name = waitingTimesData.substring(i, j).trim();
      int k = name.indexOf("</a>");
      if (k >= 0) {
        i = name.lastIndexOf('>', k);
        if (i >= 0) name = name.substring(i+1, k);
      }
      if (name.startsWith("<strong>")) {
        i = name.indexOf("</strong>");
        if (i >= 0) name = name.substring(8, i);
      }
      if (name.endsWith("min show)")) {
        i = name.indexOf(" (");
        if (i >= 0) name = name.substring(0, i);
      }
      i = waitingTimesData.indexOf("<td class=\"time\">", j);
      if (i < 0) {
        WaitingTimesCrawler.trace("wait time start not found");
        return null;
      }
      i += 17;
      j = waitingTimesData.indexOf("</td>", i);
      if (j < 0) {
        WaitingTimesCrawler.trace("wait time end not found");
        return null;
      }
      String wait = waitingTimesData.substring(i, j).trim().toLowerCase();
      String attractionId = getAttractionId(name);
      StringTokenizer st = new StringTokenizer(wait, (calendarDataUpdate)? " " : "");
      while (st.hasMoreTokens()) {
        wait = st.nextToken();
        if (wait.startsWith("<span>")) wait = wait.substring(6);
        if (wait.endsWith("</span>")) wait = wait.substring(0, wait.length()-7);
        if (wait.length() == 0) continue;
        if (attractionId == null) WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
        else if (attractionId.length() > 0) {
          if (wait.endsWith(" min")) {
            int waitTime = Integer.parseInt(wait.substring(0, wait.length()-4));
            if (waitTime <= 180 && waitingTimes != null && attractionId.length() > 0) {
              WaitingTimesItem item = new WaitingTimesItem();
              item.waitTime = waitTime;
              waitingTimes.put(attractionId, item);
            }
          } else if (wait.endsWith(" hours")) {
            int waitTime = 60*Integer.parseInt(wait.substring(0, wait.length()-6));
            if (waitTime <= 180 && waitingTimes != null && attractionId.length() > 0) {
              WaitingTimesItem item = new WaitingTimesItem();
              item.waitTime = waitTime;
              waitingTimes.put(attractionId, item);
            }
          } else if (wait.equals("closed") || wait.equals("temporarily closed")) {
            closedAttractionIds.add(attractionId);
          } else if (wait.endsWith("am") || wait.endsWith("pm")) {
            if (!wait.equals("am") && !wait.equals("pm")) {
              String startTime = getStartTime(wait);
              if (startTime != null && attractionId.length() > 0) {
                if (calendarDataUpdate && attractionId.equals("a112")) attractionId = "ch103"; // Transformers
                long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
                String endTime = formatterHour2.format(new Date(time));
                if (calendarDataUpdate && endTime != null) {
                  Set<String> aId = new HashSet<String>(2);
                  aId.add(attractionId);
                  calendarData.add(aId, new CalendarItem(currentDate, currentDate, startTime, endTime, null, null, null, null, false));
                }
              }
            }
          }// else System.out.println("unknown wait: "+wait);
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
      /*} else if (!wait.startsWith("opens ") && !wait.startsWith("meet the animals ") && !wait.startsWith("please visit us on ")) {
        if (wait.startsWith("next scare hour: ")) {
          wait = wait.substring(17);
          String startTime = getStartTime(wait);
          String endTime = getEndTime(wait);
          if (startTime != null && endTime != null) {
            Set<String> aId = new HashSet<String>(2);
            aId.add(attractionId);
            calendarData.add(aId, new CalendarItem(currentDate, currentDate, startTime, endTime, null, null, null, null, false));
          }
        } else if (!wait.equals("--")) {
          StringTokenizer st = new StringTokenizer(wait, ",");
          while (st.hasMoreTokens()) {
            wait = st.nextToken();
            if (wait.equals("12:45 am")) wait = "12:45 pm"; // bug in source!
            if (wait.startsWith("last show ")) wait = wait.substring(10);
            if (wait.startsWith("next show ")) wait = wait.substring(10);
            String startTime = getStartTime(wait);
            if (startTime != null) {
              long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
              String endTime = formatterHour2.format(new Date(time));
              if (showTimes != null) showTimes.append(wait);
              if (calendarDataUpdate && endTime != null) {
                Set<String> aId = new HashSet<String>(2);
                aId.add(attractionId);
                calendarData.add(aId, new CalendarItem(currentDate, currentDate, startTime, endTime, null, null, null, null, false));
              }
            }
          }
        }*/
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
