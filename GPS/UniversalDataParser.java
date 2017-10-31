import java.io.*;
import java.security.*;
import java.text.*;
import java.util.*;
import java.util.regex.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class UniversalDataParser extends ParkDataParser {
  private String authToken = null;
  private long lastTokenRefresh = 0;

  public UniversalDataParser(String parkId) {
    super(parkId, "America/New_York");
    setSSLContext();
  }

  public boolean isCalendarPageValid(String calendarPage) {
    //return (calendarPage.indexOf("<span><font color=\"DarkBlue\">") >= 0); // also <span style="color:DarkBlue;">
    return (calendarPage.indexOf("DarkBlue") >= 0);
  }

  public String firstCalendarPage() {
    setSSLContext();
    lastTokenRefresh = System.currentTimeMillis();
    String d = getStandardFormattedDate(new Date());
    String signature = createSignature("AndroidMobileApp", "QW5kcm9pZE1vYmlsZUFwcFNlY3JldEtleTE4MjAxNA==", d);
    downloadWaitingTimesDataProperties.put("X-UNIWebService-ApiKey", "AndroidMobileApp");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-Device", "samsung");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-ServiceVersion", "1");
    downloadWaitingTimesDataContentType = "application/json; charset=UTF-8";
    downloadWaitingTimesDataProperties.put("X-UNIWebService-AppVersion", "1.4.2");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-Platform", "Android");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-PlatformVersion", "4.2.2");
    downloadWaitingTimesDataProperties.put("Date", d);
    downloadWaitingTimesDataProperties.put("Accept-Encoding", "gzip");
    downloadWaitingTimesDataPOST = "{\"apikey\":\"AndroidMobileApp\",\"signature\":\"" + signature + "\"}";
    downloadWaitingTimesDataUserAgent = "Dalvik/1.6.0 (Linux; U; Android 4.2.2; GT-P3100 Build/JDQ39)";
    downloadWaitingTimesDataAccept = "application/json";
    downloadWaitingTimesDataAcceptLanguage = "en-US";
    final String tokenContent = downloadPageHasContent("https://services.universalorlando.com/api", "UTF-8");
    //System.out.println(tokenContent);
    int i = -1;
    if (tokenContent != null) {
      i = tokenContent.indexOf("\"Token\":");
      if (i >= 0) {
        i = tokenContent.indexOf('\"', i+8);
        if (i > 0) {
          int j = tokenContent.indexOf('\"', i+1);
          authToken = (j > i)? tokenContent.substring(i+1, j) : null;
        }
      }
    }
    if (i < 0) {
      WaitingTimesCrawler.trace("no token responded from services.universalorlando.com");
      authToken = null;
    }
    //System.out.println(authToken);
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataAccept = null;
    downloadWaitingTimesDataAcceptLanguage = null;
    downloadWaitingTimesDataPOST = null;
    return (parkId.equals("usuifl"))? "https://www.universalorlando.com/Resort-Information/IOA-Park-Hours-Mobile.aspx" : "https://www.universalorlando.com/Resort-Information/USF-Park-Hours-Mobile.aspx";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    int l = contentOfPreviousPage.length();
    int j = contentOfPreviousPage.indexOf("__VIEWSTATE");
    if (j < 0) {
      WaitingTimesCrawler.trace("view state for next month not found");
      return null;
    }
    j = contentOfPreviousPage.indexOf("value=\"", j);
    if (j < 0) {
      WaitingTimesCrawler.trace("view state for next month not found");
      return null;
    }
    j += 7;
    int i = j;
    while (i < l && contentOfPreviousPage.charAt(i) != '\"') ++i;
    String viewState = contentOfPreviousPage.substring(j, i);
    String s = "\"Go to the previous month\"";
    j = contentOfPreviousPage.indexOf(s, j);
    if (j < 0) {
      WaitingTimesCrawler.trace("first entry for next month not found");
      return null;
    }
    j += s.length();
    s = (parkId.equals("usuifl"))? "__doPostBack('IslandOfAdventureCalendar$ECalendar','" : "__doPostBack('UniversalStudiosFloridaCalendar$ECalendar','";
    j = contentOfPreviousPage.indexOf(s, j);
    if (j < 0) {
      WaitingTimesCrawler.trace("entry for next month not found");
      return null;
    }
    j += s.length();
    i = j;
    while (i < l && contentOfPreviousPage.charAt(i) != '\'') ++i;
    s = (parkId.equals("usuifl"))? "__EVENTTARGET=IslandOfAdventureCalendar%24ECalendar&__EVENTARGUMENT=" : "__EVENTTARGET=UniversalStudiosFloridaCalendar%24ECalendar&__EVENTARGUMENT=";
    downloadWaitingTimesDataCompressed = false;
    downloadWaitingTimesDataUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.77.4 (KHTML, like Gecko) Version/7.0.5 Safari/537.77.4";
    downloadWaitingTimesDataAccept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
    downloadWaitingTimesDataAcceptLanguage = "en-us";
    downloadWaitingTimesDataContentType = "application/x-www-form-urlencoded";
    downloadWaitingTimesDataPOST = s + contentOfPreviousPage.substring(j, i) + "&__VIEWSTATE=" + encodeURLComponent(viewState);
    return (parkId.equals("usuifl"))? "https://www.universalorlando.com/Resort-Information/IOA-Park-Hours-Mobile.aspx" : "https://www.universalorlando.com/Resort-Information/USF-Park-Hours-Mobile.aspx";
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
      WaitingTimesCrawler.trace("getStartTime: '" + originStartEndTime + "' cannot be parsed (" + parkId + ')');
      return null;
    }
    return formatterHour2.format(d);
  }
  
  private List<String> getStartTimes(String times) {
    List<String> allStartTimes = new ArrayList<String>(30);
    Pattern pattern2 = Pattern.compile("(1[012]|[1-9]):[0-5][0-9](\\s)?(?i)(am|pm)(\\s)?-(\\s)?(1[012]|[1-9]):[0-5][0-9](\\s)?(?i)(am|pm)");
    Matcher matcher2 = pattern2.matcher(times);
    if (!matcher2.find()) {
      pattern2 = Pattern.compile("(1[012]|[1-9]):[0-5][0-9](\\s)?(?i)(am|pm)");
      matcher2 = pattern2.matcher(times);
      while (matcher2.find()) {
        Date d = formatterHour.parse(matcher2.group(), new ParsePosition(0));
        if (d != null) allStartTimes.add(formatterHour2.format(d));
        else WaitingTimesCrawler.trace("time '" + matcher2.group() + "' cannot be parsed");
      }
    }
    return allStartTimes;
  }

  private List<String> getStartEndTimes(String times) {
    List<String> allStartTimes = new ArrayList<String>(30);
    Pattern pattern2 = Pattern.compile("(1[012]|[1-9]):[0-5][0-9](\\s)?(?i)(am|pm)(\\s)?-(\\s)?(1[012]|[1-9]):[0-5][0-9](\\s)?(?i)(am|pm)");
    Matcher matcher2 = pattern2.matcher(times);
    while (matcher2.find()) {
      allStartTimes.add(matcher2.group());
    }
    return allStartTimes;
  }
  
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    final String[] months = new String[]{ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };
    downloadWaitingTimesDataPOST = null;
    boolean isCalendarEmpty = calendarData.isEmpty();
    Set<String> parkEntrances = getParkEntrances();
    int l = calendarPage.length();
    int j = 0;
    boolean values = false;
    boolean stop = false;
    while (!stop) {
      j = calendarPage.indexOf("\"Go to the previous month\"", j);
      if (j < 0) {
        if (!values) WaitingTimesCrawler.trace("first entry for month not found");
        break; //return values;
      }
      j = calendarPage.indexOf("<td align=\"center\"", j+26);
      if (j < 0) {
        WaitingTimesCrawler.trace("entry for month not found");
        return false;
      }
      j += 26;
      do {
        while (j < l && calendarPage.charAt(j) != '>') ++j;
      } while (++j < l && calendarPage.charAt(j) == '<');
      if (j >= l) {
        WaitingTimesCrawler.trace("month not identified");
        return false;
      }
      int month = 0;
      String cMonth = calendarPage.substring(j, j+9);
      while (month < months.length && !cMonth.startsWith(months[month])) ++month;
      if (month >= months.length) {
        WaitingTimesCrawler.trace("Unknown month: " + cMonth);
        return false;
      }
      j += months[month].length()+1;
      ++month;
      int year = Integer.parseInt(calendarPage.substring(j, j+4));
      //int k = calendarPage.indexOf("\"Go to the previous month\"", j);
      int k = calendarPage.indexOf("</body>", j);
      while (true) {
        // <td align="center" style="width:70%;">July 2012
        // 1<span style="color:DarkBlue;"><BR />08:00 AM - 09:00 PM<
        int i = calendarPage.indexOf("DarkBlue", j);
        if (i < 0 || k >= 0 && i >= k) {
          j = k;
          break;
        }
        if (i < 0) {
          values = true;
          stop = true;
          break;
          // return true;
        }
        j = calendarPage.indexOf('>', i);
        i = calendarPage.lastIndexOf("<span", i);
        if (j < 0 || i < 0) {
          WaitingTimesCrawler.trace("DarkBlue not correct identified");
          return false;
        }
        ++j;
        //System.out.println("i="+i+", j="+j+": "+calendarPage.substring(i, j));
        int day = 0;
        int place = 1;
        while (--i >= 0) {
          char c = calendarPage.charAt(i);
          if (c == '>') {
            if (day > 0) {
              while (j < l && calendarPage.charAt(j) != '>') ++j;
              if (++j < l) {
                String startTime = calendarPage.substring(j, j+8);
                String endTime = calendarPage.substring(j+11, j+19);
                startTime = formatterHour2.format(formatterHour3.parse(startTime, new ParsePosition(0)));
                endTime = formatterHour2.format(formatterHour3.parse(endTime, new ParsePosition(0)));
                String date = String.format("%02d.%02d.%04d", day, month, year);
                calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, null, null, null, null, false));
                values = true;
              }
            }
            break;
          }
          if (!Character.isDigit(c)) break;
          day += (c-'0')*place;
          place *= 10;
        }
      }
    }
    if (isCalendarEmpty && values) {
      final String showTimes = downloadPageHasContent("https://www.universalorlando.com/Resort-Information/Showtimes.aspx", "UTF-8");
      if (showTimes != null) {
        final String[] patterns = {"(1[012]|[1-9])/([1-3][0-9]|[1-9])(\\s)?-(\\s)?(1[0-2]|[1-9])/([1-3][0-9]|[1-9])", "(\\s)?(,|amp;)?(\\s)?(1[012]|[1-9])/([1-3][0-9]|[1-9])(\\s)?-?", "(1[012]|[1-9]):[0-5][0-9](\\s)?(?i)(am|pm)"};
          //((0[0-9]|1[0-2]):[0-5][0-9](a|p)m(,\\s)?)+"};
        String search = (parkId.equals("usuifl"))? "<div class=\"middle_navInfo\">Shows at Universal's Islands of Adventure" : "<div class=\"middle_navInfo\">Shows at Universal Studios Florida";
        int i = showTimes.indexOf(search);
        j = showTimes.indexOf("<div id=\"right\">", i+1);
        int k = showTimes.indexOf("<div class=\"middle_navInfo\">", i+1);
        if (k >= 0 && k < j) j = k;
        if (i >= 0 && j > i) {
          Calendar calendar = Calendar.getInstance();
          calendar.setTimeZone(getTimeZone());
          int year = calendar.get(Calendar.YEAR);
          int month = calendar.get(Calendar.MONTH);
          search = "<strong xmlns=\"http://www.w3.org/1999/xhtml\">";
          do {
            int i2 = showTimes.indexOf(search, i);
            if (i2 < 0 || i2 >= j) break; // WaitingTimesCrawler.trace("Show times name beginning not identified");
            i2 += search.length();
            int e = i2;
            int j2 = showTimes.indexOf('<', i2);
            String name = showTimes.substring(i2, j2);
            i2 = showTimes.indexOf("<ul>", i2);
            j2 = showTimes.indexOf("</ul>", j2);
            if (i2 >= 0 && i2 < j2) {
              String attractionId = getAttractionId(name);
              //System.out.println("attractionId:"+attractionId);
              if (attractionId == null) WaitingTimesCrawler.trace("No attraction ID defined for " + name);
              else if (attractionId.length() > 0) {
                String attractionURL = getAttractionURL(attractionId);
                String attractionShowTimes = null;
                if (attractionURL != null) {
                  if (attractionURL.startsWith("http://")) attractionURL = "https://" + attractionURL.substring(7);
                  attractionShowTimes = downloadPageHasContent(attractionURL, "UTF-8");
                  int i3 = attractionShowTimes.indexOf("Show Times:");
                  if (i3 > 0) {
                    int i4 = attractionShowTimes.indexOf("</ul>", i3);
                    if (i4 > 0) {
                      String s = showTimes.substring(i2+4, j2);
                      i2 = i3;
                      attractionShowTimes = attractionShowTimes.substring(0, i4) + s + attractionShowTimes.substring(i4);
                      j2 = attractionShowTimes.indexOf("</ul>", i4);
                    } else WaitingTimesCrawler.trace("</ul> not found in specific show times for attraction " + attractionId);
                  } else WaitingTimesCrawler.trace("Specific show times for attraction " + attractionId + " cannot be parsed");
                }
                Set<String> addedDates = new HashSet<String>(10);
                while (i2 < j2) {
                  i2 = (attractionShowTimes != null)? attractionShowTimes.indexOf("<li>", i2) : showTimes.indexOf("<li>", i2);
                  if (i2 < 0 || i2 > j2) break;
                  int i3 = (attractionShowTimes != null)? attractionShowTimes.indexOf("</li>", i2) : showTimes.indexOf("</li>", i2);
                  if (i3 < 0 || i3 > j2) break;
                  int i4 = (attractionShowTimes != null)? attractionShowTimes.indexOf(':', i2+4) : showTimes.indexOf(':', i2+4);
                  if (i4 < 0 || i4 > i3) break;
                  String dates = (attractionShowTimes != null)? attractionShowTimes.substring(i2+4, i4) : showTimes.substring(i2+4, i4);
                  String times = (attractionShowTimes != null)? attractionShowTimes.substring(i4+1, i3) : showTimes.substring(i4+1, i3);
                  //System.out.println("attractionId:"+attractionId+", Dates:" + dates + ", Times:" + times);
                  String allShowTimes = dates+':'+times;
                  boolean added = false;
                  for (int p = 0; p < patterns.length && (p > 0 || !addedDates.contains(allShowTimes)); ++p) {
                    Pattern pattern = Pattern.compile(patterns[p]);
                    Matcher matcher = pattern.matcher((p != 2)? dates : allShowTimes);
                    while (matcher.find()) {
                      Date from = null;
                      Date to = null;
                      String s = matcher.group();
                      if (p == 0) {
                        int i5 = s.indexOf('-');
                        from = formatterMonthDay.parse(s.substring(0, i5), new ParsePosition(0));
                        to = formatterMonthDay.parse(s.substring(i5+1), new ParsePosition(0));
                      } else if (p == 1) {
                        if (s.endsWith("-") || dates.indexOf("-"+s) >= 0) continue;
                        s = s.trim();
                        if (s.startsWith("amp;")) s = s.substring(5);
                        else if (s.startsWith(",")) s = s.substring(1);
                        from = to = formatterMonthDay.parse(s, new ParsePosition(0));
                      } else {
                        if (added) continue;
                        List<CalendarItem> items = calendarData.get(parkEntrances);
                        for (CalendarItem item : items) {
                          Set<String> aId = new HashSet<String>(2);
                          aId.add(attractionId);
                          List<String> allStartTimes = getStartTimes(allShowTimes);
                          for (String startTime : allStartTimes) {
                            long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
                            calendarData.add(aId, new CalendarItem(item.startDate, item.endDate, startTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
                          }
                        }
                        break;
                      }
                      if (attractionId.equals("a209")) continue; // ToDo: REMOVE
                      if (from != null || to != null) {
                        calendar.setTime(from);
                        int m = calendar.get(Calendar.MONTH);
                        if (m-month > 5) calendar.set(Calendar.YEAR, year-1);
                        else if (m-month < -5) calendar.set(Calendar.YEAR, year+1);
                        else calendar.set(Calendar.YEAR, year);
                        String fromDate = formatterDate.format(calendar.getTime());
                        String toDate = fromDate;
                        if (to != from) {
                          calendar.setTime(to);
                          m = calendar.get(Calendar.MONTH);
                          if (m-month > 5) calendar.set(Calendar.YEAR, year-1);
                          else if (m-month < -5) calendar.set(Calendar.YEAR, year+1);
                          else calendar.set(Calendar.YEAR, year);
                          toDate = formatterDate.format(calendar.getTime());
                        }
                        Set<String> aId = new HashSet<String>(2);
                        aId.add(attractionId);
                        List<String> allStartEndTimes = getStartEndTimes(times);
                        for (String startEndTime : allStartEndTimes) {
                          int idx = startEndTime.indexOf('-');
                          if (idx <= 0 || idx+1 >= startEndTime.length()) continue;
                          String startTime = getStartTime(startEndTime.substring(0, idx));
                          String endTime = getStartTime(startEndTime.substring(idx+1));
                          calendarData.add(aId, new CalendarItem(fromDate, toDate, startTime, endTime, null, null, null, null, false));
                        }
                        List<String> allStartTimes = getStartTimes(times);
                        for (String startTime : allStartTimes) {
                          long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
                          calendarData.add(aId, new CalendarItem(fromDate, toDate, startTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
                        }
                        added = true;
                      } else if (p != 2) WaitingTimesCrawler.trace("date '" + matcher.group() + "' cannot be parsed");
                    }
                  }
                  addedDates.add(allShowTimes);
                  i2 = i3+5;
                }
              }
            } else WaitingTimesCrawler.trace("End of show times not identified");
            i = e;
          } while (i < j);
        } else {
          WaitingTimesCrawler.trace("Park name for show times not found (" + i + ", " + j + ')');
          return false;
        }
      }
    }
    //System.out.println(calendarData);
    //System.exit(1);
    return values;
  }

  public void downloadError(String strURL, int errorResponseCode) {
    if (strURL.equals("https://services.universalorlando.com/api/pointsOfInterest")) {
      WaitingTimesCrawler.trace("refresh token");
      firstCalendarPage();
    }
  }

  public String getWaitingTimesDataURL() {
    if (System.currentTimeMillis()-lastTokenRefresh >= 3600000) firstCalendarPage();
    return "https://services.universalorlando.com/api/pointsOfInterest";
  }

  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (parkId.equals("usuifl")) {
      if (name.equals("10831")) return "a04"; // The Amazing Adventures of Spider-Man
      if (name.equals("10832")) return "a20"; // Caro-Seuss-el
      if (name.equals("10833")) return "a22"; // The Cat in the Hat
      if (name.equals("10835")) return "a03"; // Doctor Doom's Fearfall
      if (name.equals("10836")) return "a15"; // Dragon Challenge
      if (name.equals("10837")) return "a31"; // Dudley Do-Right's Ripsaw Falls
      if (name.equals("10839")) return "a12"; // Flight of the Hippogriff
      if (name.equals("10840")) return "a11"; // Harry Potter and the Forbidden Journey
      if (name.equals("10842")) return "a09"; // Jurassic Park River Adventure
      if (name.equals("10855")) return "a21"; // One Fish, Two Fish, Red Fish, Blue Fish
      if (name.equals("10856")) return "a06"; // Popeye & Bluto's Bilge-Rat Barges
      if (name.equals("10857")) return "a07"; // Pteranodon Flyers
      if (name.equals("10859")) return "a19"; // The High in the Sky Seuss Trolley Train Ride!
      if (name.equals("10861")) return "a02"; // Storm Force Accelatron
      if (name.equals("10862")) return "a01"; // The Incredible Hulk Coaster
      if (name.equals("11586")) return "a18"; // Poseidon's Fury®
      if (name.equals("12712")) return "a17"; // The Mystic Fountain
      if (name.equals("11583")) return "a16"; // The Eighth Voyage of Sindbad® Stunt Show
      if (name.equals("11584")) return "a13"; // Frog Choir
      if (name.equals("11585")) return "a14"; // Triwizard Spirit Rally
      if (name.equals("13225")) return "a28"; // Hogwarts Express - Hogsmeade Station
      if (name.equals("13107")) return "a05"; // Me Ship, The Olive
      if (name.equals("13102")) return "a08"; // Camp Jurassic
      if (name.equals("13105")) return "a23"; // If I Ran The Zoo
      if (name.equals("13106")) return "a10"; // Jurassic Park Discovery Center
      if (name.equals("11587")) return ""; // Oh! The Stories You'll Hear!
      if (name.startsWith("Poseidon") && name.endsWith(" Fury")) return "a18";
      if (name.startsWith("Oh! The Stories You")) return "";
    } else { // ususfl
      if (name.equals("10135")) return "a201"; // despicable me
      if (name.equals("10834")) return "a209"; // Disaster!
      if (name.equals("10838")) return "a218"; // E.T. Adventure
      if (name.equals("10841")) return "a203"; // Hollywood Rip Ride Rockit
      if (name.equals("10852")) return "a229"; // Kang & Kodos' Twirl 'n' Hurl
      if (name.equals("10853")) return "a211"; // MEN IN BLACK Alien Attack
      if (name.equals("10858")) return "a205"; // Revenge of the Mummy
      if (name.equals("10860")) return "a202"; // Shrek 4-D
      if (name.equals("10875")) return "a212"; // The Simpsons Ride
      if (name.equals("10877")) return "a228"; // Transformers: The Ride 3-D
      if (name.equals("10878")) return "a204"; // TWISTERRide It Out
      if (name.equals("10879")) return "a216"; // Woody Woodpecker's Nuthouse Coaster
      if (name.equals("11588")) return "a220"; // TERMINATOR 2: 3-D
      if (name.equals("12930")) return "a208"; // Beetlejuice's Graveyard Revue™
      if (name.equals("12318")) return "a214"; // A Day in the Park with Barney™
      if (name.equals("12289")) return "a206"; // The Blues Brothers® Show
      if (name.equals("12287")) return "a213"; // Animal Actors on Location!
      if (name.equals("12291")) return "a227"; // Fear Factor Live
      if (name.equals("12292")) return "a219"; // Universal Orlando's Horror Make-Up Show
      if (name.equals("13228")) return "a231"; // Hogwarts Express - King's Cross Station
      if (name.equals("13103")) return "a215"; // Curious George Goes to Town
      if (name.equals("13104")) return "a217"; // Fievel's Playland
      if (name.equals("13221")) return "a232"; // Harry Potter and the Escape from Gringotts
      if (name.equals("12290")) return ""; // Cinematic Spectacular
      //if (name.equals("WaterWorld")) return "";
      //if (name.equals("Special Effects Stage")) return "";
      if (name.equals("The Blues Brothers")) return "a206";
      if (name.equals("Blues Brothers")) return "a206";
      if (name.equals("Universal Animal Actors")) return "a213";
      if (name.startsWith("A Day in the Park with Barney")) return "a214";
      if (name.equals("Terminator 2")) return "a220";
      if (name.startsWith("Beetlejuice's Graveyard Revue")) return "a208";
      if (name.equals("Universal's Cinematic Spectacular")) return "";
      if (name.startsWith("Macy's Holiday Parade")) return "";
    }
    return null;
  }

  private String getAttractionURL(String attractionId) {
    if (attractionId.equals("a16")) return "http://www.universalorlando.com/Rides/Islands-of-Adventure/Eighth-Voyage-of-Sindbad.aspx";
    if (attractionId.equals("a206")) return "http://www.universalorlando.com/Shows/Universal-Studios-Florida/Blues-Brothers.aspx";
    if (attractionId.equals("a208")) return "http://www.universalorlando.com/Shows/Universal-Studios-Florida/Beetlejuice.aspx";
    if (attractionId.equals("a213")) return "http://www.universalorlando.com/Rides/Universal-Studios-Florida/Animal-Actors-On-Location.aspx";
    if (attractionId.equals("a214")) return "http://www.universalorlando.com/Shows/Universal-Studios-Florida/Day-In-Park-With-Barney.aspx";
    if (attractionId.equals("a219")) return "http://www.universalorlando.com/Shows/Universal-Studios-Florida/Horror-Make-Up-Show.aspx";
    return null;
  }

  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    downloadWaitingTimesDataAccept = "application/json";
    downloadWaitingTimesDataProperties.put("X-UNIWebService-ApiKey", "AndroidMobileApp");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-Device", "samsung GT-P3100");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-ServiceVersion", "1");
    //downloadWaitingTimesDataProperties.put("Accept-Encoding", "gzip");
    //downloadWaitingTimesDataContentType = "application/json; charset=UTF-8";
    downloadWaitingTimesDataProperties.put("X-UNIWebService-AppVersion", "1.0.2");
    if (authToken != null) downloadWaitingTimesDataProperties.put("X-UNIWebService-Token", authToken);
    downloadWaitingTimesDataProperties.put("X-UNIWebService-PlatformVersion", "4.2.2");
    downloadWaitingTimesDataProperties.put("X-UNIWebService-Platform", "Android");
    downloadWaitingTimesDataUserAgent = "Dalvik/1.6.0 (Linux; U; Android 4.2.2; GT-P3100 Build/JDQ39)";
    downloadWaitingTimesDataAcceptLanguage = "en-US";
    downloadWaitingTimesDataPOST = null;
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    downloadWaitingTimesDataAccept = null;
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataContentType = null;
    downloadWaitingTimesDataAcceptLanguage = null;
    if (waitingTimes == null || waitingTimesData == null) return null;
    JSONObject allPois = (JSONObject)JSONValue.parse(waitingTimesData);
    JSONArray rides = (JSONArray)allPois.get("Rides");
    int n = rides.size();
    for (int i = 0; i < n; ++i) {
      JSONObject attraction = (JSONObject)rides.get(i);
      int pId = ((Long)attraction.get("VenueId")).intValue();
      if (pId == 10000 && parkId.equals("usuifl") || pId == 10010 && parkId.equals("ususfl")) {
        String name = (String)attraction.get("MblDisplayName");
        String aId = ((Long)attraction.get("Id")).toString();
        int waitTime = ((Long)attraction.get("WaitTime")).intValue();
        String attractionId = getAttractionId(aId);
        if (attractionId == null) WaitingTimesCrawler.trace("No attraction ID defined for " + aId + " - " + name + " (wait time " + waitTime + " min)");
        else if (attractionId.length() > 0) {
          if (waitTime >= 0 && waitTime <= 180) {
            WaitingTimesItem item = new WaitingTimesItem();
            item.waitTime = waitTime;
            waitingTimes.put(attractionId, item);
          }
          //System.out.println(attractionId + ':' + waitingTimesData.substring(j, i));
        }
      }
    }
    //System.out.println(waitingTimesData);
    //System.exit(1);
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    Set<String> closedAttractionIds = new HashSet<String>(7);
    if (waitingTimesData != null) {
      String s = (parkId.equals("usuifl"))? "<id>islands-of-adventure</id>" : "<id>universal-studios-florida</id>";
      int i = waitingTimesData.indexOf(s);
      if (i < 0) return closedAttractionIds;
      i += s.length();
      s = "<Attractions.WaitTimes.Get>";
      i = waitingTimesData.indexOf(s, i);
      if (i < 0) return closedAttractionIds;
      i += s.length();
      int l = waitingTimesData.indexOf('<', i);
      if (l < 0) return closedAttractionIds;
      while (i >= 0 && i < l) {
        int j = waitingTimesData.indexOf(',', i);
        String name = waitingTimesData.substring(i, j);
        i = waitingTimesData.indexOf(',', ++j);
        int waitTime = Integer.parseInt(waitingTimesData.substring(j, i));
        if (waitTime == 200) {
          String attractionId = getAttractionId((name.startsWith("^"))? name.substring(1) : name);
          if (attractionId == null) System.out.println("No attraction ID defined for closed " + name + " (wait time " + waitTime + " min)");
          else if (attractionId.length() > 0) closedAttractionIds.add(attractionId);
        }
        i = waitingTimesData.indexOf('^', i+1);
      }
    }
    return closedAttractionIds;
  }

  private static String createSignature(String s, String s1, String s2) {
    try {
      String s4 = (new StringBuilder(String.valueOf(s))).append("\n").append(s2).append("\n").toString();
      byte abyte0[] = Base64.decode(s1, 0);
      Mac mac = Mac.getInstance("HmacSHA256");
      mac.init(new SecretKeySpec(abyte0, "HmacSHA256"));
      return new String(Base64.encode(mac.doFinal(s4.getBytes("UTF-8")), 2), "UTF-8");
    } catch (UnsupportedEncodingException e) {
      return null;
    } catch (IllegalStateException e) {
      return null;
    } catch (InvalidKeyException e) {
      return null;
    } catch (NoSuchAlgorithmException e) {
      return null;
    }
  }

  private static String getStandardFormattedDate(Date paramDate) {
    SimpleDateFormat localSimpleDateFormat = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss", Locale.US);
    localSimpleDateFormat.setTimeZone(TimeZone.getTimeZone("GMT"));
    return localSimpleDateFormat.format(paramDate) + " " + "GMT";
  }
}
