import java.io.*;
import java.text.*;
import java.util.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class EuropaParkDataParser extends ParkDataParser {
  private int entranceOpeningToday = 0;
  private String parsedDayContent = null;

  public EuropaParkDataParser() {
    super("ep", "Europe/Paris");
  }

  public boolean checkCalendarUpdatesAfterOpening() {
    return true;
  }
  
  public String firstCalendarPage() {
    // http://apps.europapark.de/webservices/calendar.xml
    // http://apps.europapark.de/webservices/opening.php
    return "http://www.europapark.de/en/service-infos/worth-knowing/opening-hours";
    //http://www.europapark.de/en/service-infos/worth-knowing/opening-hours?from[value][date]=01.12.2015&to[value][date]=01.01.2016
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    return null;
  }

  private boolean updateEntranceOpeningToday() {
    downloadWaitingTimesDataProperties.put("X-Requested-With", "XMLHttpRequest");
    downloadWaitingTimesDataProperties.put("Accept-Encoding", "gzip, deflate");
    downloadWaitingTimesDataAcceptLanguage = "de-de";
    downloadWaitingTimesDataAccept = "*/*";
    downloadWaitingTimesDataUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13E238 (5600697456)";
    //downloadWaitingTimesDataUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Mobile/11D257 (384337760)";
    final String closingTime = downloadPageHasContent("http://apps.europapark.de/webservices/closingtime/?format=json&v=5&_dc="+System.currentTimeMillis(), "UTF-8");
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataAcceptLanguage = null;
    downloadWaitingTimesDataAccept = null;
    final String startSuccessText = "{\"success\":true,\"closingtime\":\"";
    if (closingTime != null && closingTime.startsWith(startSuccessText) && closingTime.endsWith("\"}")) {
      int i = startSuccessText.length();
      String t = closingTime.substring(startSuccessText.length(), closingTime.length()-2);
      if (t.length() == 5 && t.charAt(2) == ':') {
        int opening = 1000*(t.charAt(0)-'0')+100*(t.charAt(1)-'0')+10*(t.charAt(3)-'0')+(t.charAt(4)-'0');
        if (opening != entranceOpeningToday) {
          entranceOpeningToday = opening;
          return true;
        }
      }
    } else {
      entranceOpeningToday = 0;
    }
    return false;
  }

  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Calendar calendar = getCurrentCalendar();
    String currentDate = getCurrentDate();
    updateEntranceOpeningToday();
    Set<String> parkEntrances = getParkEntrances();
    if (entranceOpeningToday > 0) {
      calendar.set(Calendar.MINUTE, 0);
      calendar.add(Calendar.HOUR_OF_DAY, -24);
      String dateLower = formatterDate.format(calendar.getTime());
      calendar.set(Calendar.MINUTE, 0);
      calendar.add(Calendar.HOUR_OF_DAY, 48);
      String dateHigher = formatterDate.format(calendar.getTime());
      String endTimeToday = String.format("%02d:%02d", entranceOpeningToday/100, entranceOpeningToday%100);
      CalendarItem calendarItemToday  = new CalendarItem(currentDate, currentDate, "09:00", endTimeToday, null, null, null, null, false);
      CalendarItem calendarItem = new CalendarItem("06.11.2016", "06.11.2016", "09:00", "18:00", null, null, null, null, false);
      if (calendarItemToday.compareTo(calendarItem) <= 0) {
        if (!dateLower.equals("19.03.2016")) calendarData.add(parkEntrances, new CalendarItem("19.03.2016", dateLower, "09:00", "18:00", null, null, null, null, false));
        calendarData.add(parkEntrances, calendarItemToday);
        if (!dateHigher.equals("06.11.2016")) calendarData.add(parkEntrances, new CalendarItem(dateHigher, "06.11.2016", "09:00", "18:00", null, null, null, null, false));
        calendarData.add(parkEntrances, new CalendarItem("26.11.2016", "23.12.2016", "11:00", "19:00", null, null, null, null, true));
        calendarData.add(parkEntrances, new CalendarItem("26.12.2016", "30.12.2016", "11:00", "19:00", null, null, null, null, true));
        calendarData.add(parkEntrances, new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:30", null, null, null, null, true));
        calendarData.add(parkEntrances, new CalendarItem("01.01.2017", "08.01.2017", "11:00", "19:00", null, null, null, null, true));
      } else {
        calendarData.add(parkEntrances, new CalendarItem("19.03.2016", "06.11.2016", "09:00", "18:00", null, null, null, null, false));
        calendarItemToday = new CalendarItem(currentDate, currentDate, "11:00", endTimeToday, null, null, null, null, true);
        calendarItem = new CalendarItem("23.12.2016", "23.12.2016", "11:00", "19:00", null, null, null, null, true);
        if (calendarItemToday.compareTo(calendarItem) <= 0) {
          if (!dateLower.equals("26.11.2016")) calendarData.add(parkEntrances, new CalendarItem("26.11.2016", dateLower, "11:00", "19:00", null, null, null, null, true));
          calendarData.add(parkEntrances, calendarItemToday);
          if (!dateHigher.equals("23.12.2016")) calendarData.add(parkEntrances, new CalendarItem(dateHigher, "23.12.2016", "11:00", "19:00", null, null, null, null, true));
          calendarData.add(parkEntrances, new CalendarItem("26.12.2016", "30.12.2016", "11:00", "19:00", null, null, null, null, true));
          calendarData.add(parkEntrances, new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:30", null, null, null, null, true));
          calendarData.add(parkEntrances, new CalendarItem("01.01.2017", "08.01.2017", "11:00", "19:00", null, null, null, null, true));
        } else {
          calendarData.add(parkEntrances, new CalendarItem("26.11.2016", "23.12.2016", "11:00", "19:00", null, null, null, null, true));
          calendarItem = new CalendarItem("30.12.2016", "30.12.2016", "11:00", "19:00", null, null, null, null, true);
          if (calendarItemToday.compareTo(calendarItem) <= 0) {
            if (!dateLower.equals("26.12.2016")) calendarData.add(parkEntrances, new CalendarItem("26.12.2016", dateLower, "11:00", "19:00", null, null, null, null, true));
            calendarData.add(parkEntrances, calendarItemToday);
            if (!dateHigher.equals("30.12.2016")) calendarData.add(parkEntrances, new CalendarItem(dateHigher, "30.12.2016", "11:00", "19:00", null, null, null, null, true));
            calendarData.add(parkEntrances, new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:30", null, null, null, null, true));
            calendarData.add(parkEntrances, new CalendarItem("01.01.2017", "10.01.2017", "11:00", "19:00", null, null, null, null, true));
          } else {
            calendarData.add(parkEntrances, new CalendarItem("26.12.2016", "30.12.2016", "11:00", "19:00", null, null, null, null, true));
            calendarItem = new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:30", null, null, null, null, true);
            if (calendarItemToday.compareTo(calendarItem) <= 0) {
              calendarData.add(parkEntrances, calendarItemToday);
              calendarData.add(parkEntrances, new CalendarItem("01.01.2017", "08.01.2017", "11:00", "19:00", null, null, null, null, true));
            } else {
              calendarData.add(parkEntrances, new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:30", null, null, null, null, true));
              calendarItem = new CalendarItem("08.01.2017", "08.01.2017", "11:00", "19:00", null, null, null, null, true);
              if (calendarItemToday.compareTo(calendarItem) <= 0) {
                if (!dateLower.equals("01.01.2017")) calendarData.add(parkEntrances, new CalendarItem("01.01.2017", dateLower, "11:00", "19:00", null, null, null, null, true));
                calendarData.add(parkEntrances, calendarItemToday);
                if (!dateHigher.equals("08.01.2017")) calendarData.add(parkEntrances, new CalendarItem(dateHigher, "08.01.2017", "11:00", "19:00", null, null, null, null, true));
              } else {
                calendarData.add(parkEntrances, calendarItemToday);
              }
            }
          }
        }
      }
    } else {
      calendarData.add(parkEntrances, new CalendarItem("19.03.2016", "06.11.2016", "09:00", "18:00", null, null, null, null, false));
      calendarData.add(parkEntrances, new CalendarItem("26.11.2016", "23.12.2016", "11:00", "19:00", null, null, null, null, true));
      calendarData.add(parkEntrances, new CalendarItem("26.12.2016", "30.12.2016", "11:00", "19:00", null, null, null, null, true));
      calendarData.add(parkEntrances, new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:30", null, null, null, null, true));
      calendarData.add(parkEntrances, new CalendarItem("01.01.2017", "08.01.2017", "11:00", "19:00", null, null, null, null, true));
    }
    
    /*int i = calendarPage.indexOf("Sommer-Saison");
    if (i < 0) { System.out.println("Error find Sommer-Saison"); return false; }
    i = calendarPage.indexOf("ffnungszeiten", i);
    if (i < 0) { System.out.println("Error find ffnungszeiten Sommer"); return false; }
    i = calendarPage.indexOf("<p ", i);
    if (i < 0) { System.out.println("Error find <p 1"); return false; }
    i = calendarPage.indexOf("<p ", i+3);
    if (i < 0) { System.out.println("Error find <p 2"); return false; }
    int j = calendarPage.indexOf(" Uhr", i+3);
    if (j < 0) { System.out.println("Error find Uhr 1"); return false; }
    int k = calendarPage.lastIndexOf(':', j-5);
    String startTimeSummer = calendarPage.substring(k-2, k+3);
    String endTimeSummer = calendarPage.substring(j-5, j);
    formatterHour2.parse(endTimeSummer, new ParsePosition(0)); // validate
    formatterHour2.parse(startTimeSummer, new ParsePosition(0)); // validate
    i = calendarPage.indexOf("Winter-Saison"); // start from beginning because order Summer & Winter is changing
    if (i < 0) { System.out.println("Error find Winter-Saison"); return false; }
    i = calendarPage.indexOf("ffnungszeiten", i);
    if (i < 0) { System.out.println("Error find ffnungszeiten Winter"); return false; }
    i = calendarPage.indexOf("<p ", i);
    if (i < 0) { System.out.println("Error find <p 3"); return false; }
    i = calendarPage.indexOf("<p ", i+3);
    if (i < 0) { System.out.println("Error find <p 4"); return false; }
    j = calendarPage.indexOf(" Uhr", i+3);
    if (j < 0) { System.out.println("Error find Uhr 2"); return false; }
    k = calendarPage.lastIndexOf(':', j-5);
    String startTimeWinter = calendarPage.substring(k-2, k+3);
    String endTimeWinter = calendarPage.substring(j-5, j);
    String endTimeToday = String.format("%02d:%02d", entranceOpeningToday/100, entranceOpeningToday%100);
    String currentDate = getCurrentDate();
    formatterHour2.parse(endTimeWinter, new ParsePosition(0)); // validate
    formatterHour2.parse(startTimeWinter, new ParsePosition(0)); // validate
    String searchDate = "\"Oeffnungszeit_Europapark\",\"specialDaysArray\":[";
    i = calendarPage.indexOf(searchDate, i);
    if (i < 0) { System.out.println("Error find specialDaysArray"); return false; }
    Set<String> addedDays = new HashSet<String>(400);
    while (true) {
      i = calendarPage.indexOf("[,[", i);
      if (i < 0) break;
      i += 3;
      j = calendarPage.indexOf(',', i);
      if (j-i != 4) { System.out.println("Error find , 1"); return false; }
      int year = Integer.parseInt(calendarPage.substring(i, j));
      i = j+1;
      j = calendarPage.indexOf(',', i);
      if (j < 0) { System.out.println("Error find , 2"); return false; }
      int month = Integer.parseInt(calendarPage.substring(i, j));
      i = j+1;
      j = calendarPage.indexOf(']', i);
      if (j < 0) { System.out.println("Error find ]"); return false; }
      int day = Integer.parseInt(calendarPage.substring(i, j));
      String date = String.format("%02d.%02d.%04d", day, month, year);
      if (!addedDays.add(date)) continue;
      i = calendarPage.indexOf('[', j);
      if (i < 0) { System.out.println("Error find ["); return false; }
      i = calendarPage.indexOf(',', i);
      if (i < 0) { System.out.println("Error find , 3"); return false; }
      i = calendarPage.indexOf('\"', i);
      if (i < 0) { System.out.println("Error find \" 1"); return false; }
      ++i;
      j = calendarPage.indexOf('\"', i);
      if (j < 0) { System.out.println("Error find \" 2"); return false; }
      String summerWinter = calendarPage.substring(i, j);
      if (summerWinter.equals("Sommer")) calendarData.add(parkEntrances, new CalendarItem(date, date, startTimeSummer, (entranceOpeningToday > 0 && date.equals(currentDate))? endTimeToday : endTimeSummer, null, null, null, null, false));
      else if (summerWinter.equals("Winter")) calendarData.add(parkEntrances, new CalendarItem(date, date, startTimeWinter, (entranceOpeningToday > 0 && date.equals(currentDate))? endTimeToday : endTimeWinter, null, null, null, null, true));
    }*/
    downloadWaitingTimesDataProperties.put("X-Requested-With", "XMLHttpRequest");
    downloadWaitingTimesDataProperties.put("Accept-Encoding", "gzip, deflate");
    downloadWaitingTimesDataAcceptLanguage = "de-de";
    downloadWaitingTimesDataAccept = "*/*";
    downloadWaitingTimesDataUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13E238 (5600697456)";
    //"Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Mobile/11D257 (384337760)";
    final String dayContent = downloadPageHasContent("http://apps.europapark.de/webservices/showtimes/index.php?v=2&lang=de", "UTF-8");
    JSONArray rides = (JSONArray)JSONValue.parse(dayContent);
    int n = rides.size();
    for (int i = 0; i < n; ++i) {
      JSONObject attraction = (JSONObject)rides.get(i);
      String name = (String)attraction.get("name");
      String attractionId = getAttractionId(name);
      if (attractionId == null) attractionId = getAttractionId(String.valueOf(attraction.get("code")));
      if (attractionId == null) attractionId = getAttractionId((String)attraction.get("location"));
      if (attractionId == null) WaitingTimesCrawler.trace("No attraction ID defined for '" + name + "\' (" + parkId + ')');
      else if (attractionId.length() > 0) {
        Set<String> aId = new HashSet<String>(2);
        aId.add(attractionId);
        StringTokenizer allStartHours = new StringTokenizer((String)attraction.get("times"), ",");
        while (allStartHours.hasMoreTokens()) {
          String startTime = allStartHours.nextToken();
          long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
          calendarData.add(aId, new CalendarItem(currentDate, currentDate, startTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
        }
      }
    }
    parsedDayContent = dayContent;
    /*try {
      final String dayContent = downloadPageHasContent("http://apps.europapark.de/webservices/showtimes/shows_de/", "UTF-8");
      Document eventDoc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new ByteArrayInputStream(dayContent.getBytes("UTF-8")));
      NodeList showtimes = eventDoc.getChildNodes();
      if (showtimes.getLength() == 1) {
        showtimes = showtimes.item(0).getChildNodes(); // showtimes
        for (int i = 0; i < showtimes.getLength(); ++i) {
          if (showtimes.item(i).getNodeName().equals("show")) {
            NamedNodeMap attributes = showtimes.item(i).getAttributes();
            String name = attributes.getNamedItem("name").getNodeValue();
            String attractionId = getAttractionId(name);
            if (attractionId == null) attractionId = getAttractionId(attributes.getNamedItem("location").getNodeValue());
            if (attractionId == null) WaitingTimesCrawler.trace("No attraction ID defined for '" + name + "\' (" + parkId + ')');
            else if (attractionId.length() > 0) {
              Set<String> aId = new HashSet<String>(2);
              aId.add(attractionId);
              StringTokenizer allStartHours = new StringTokenizer(attributes.getNamedItem("times").getNodeValue(), ";");
              while (allStartHours.hasMoreTokens()) {
                String startTime = allStartHours.nextToken();
                long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
                calendarData.add(aId, new CalendarItem(currentDate, currentDate, startTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
              }
            }
          }
        }
      }
      parsedDayContent = dayContent;
    } catch (ParserConfigurationException e) {
      WaitingTimesCrawler.trace("The underlying parser does not support the requested features.");
    } catch (FactoryConfigurationError e) {
      WaitingTimesCrawler.trace("Error occurred obtaining Document Builder Factory.");
    } catch (Exception e) {
      e.printStackTrace();
    }*/
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataAcceptLanguage = null;
    downloadWaitingTimesDataAccept = null;
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  private String epCode() {
    //Europa-Park201304041720Webservice
    String time = localTimeAtPark();
    String date = getCurrentDate();
    String str1 = date.substring(6) + date.substring(3, 5) + date.substring(0, 2) + time.substring(0, 2) + time.substring(3);
    String str2 = "Europa-Park" + str1 + "SecondTry";
    return ParkDataThread.hashCode(str2).toUpperCase();

    /*while (true) {
      byte[] arrayOfByte;
      StringBuilder localStringBuilder;
      int j;
      try {
        MessageDigest localMessageDigest = MessageDigest.getInstance("MD5");
        localMessageDigest.reset();
        localMessageDigest.update(str2.getBytes());
        arrayOfByte = localMessageDigest.digest();
        int i = arrayOfByte.length;
        localStringBuilder = new StringBuilder(i << 1);
        j = 0;
        if (j >= i) {
          this.callback.success(localStringBuilder.toString());
          return;
        }
      } catch (NoSuchAlgorithmException localNoSuchAlgorithmException) {
        this.callback.error("BadGPS");
        return;
      }
      localStringBuilder.append(Character.forDigit((0xF0 & arrayOfByte[j]) >> 4, 16));
      localStringBuilder.append(Character.forDigit(0xF & arrayOfByte[j], 16));
      j++;
    }*/
  }

  public String getWaitingTimesDataURL() {
    return "http://apps.europapark.de/webservices/waittimes/index.php?code=" + epCode();
  }

  public String getCalendarTimesDataURL() {
    return "http://apps.europapark.de/webservices/showtimes/shows_de/";
  }

  protected String getAttractionId(String name) {
    if (name == null) return null;
    if (name.equals("100")) return "100";
    if (name.equals("200")) return "200";
    if (name.equals("201")) return "201";
    if (name.equals("202")) return "202";
    if (name.equals("250")) return "250";
    if (name.equals("350")) return "350";
    if (name.equals("351")) return "351";
    if (name.equals("400")) return "400";
    if (name.equals("403")) return "403";
    if (name.equals("404")) return "404";
    if (name.equals("500")) return "500";
    if (name.equals("550")) return "550";
    if (name.equals("650")) return "650";
    if (name.equals("700")) return "700";
    if (name.equals("701")) return "701";
    if (name.equals("800")) return "800";
    if (name.equals("850")) return "850";
    if (name.equals("851")) return "851";
    if (name.equals("853")) return "a21";
    if (name.equals("900")) return "a29";

    if (name.equals("Hello Euromaus")) return "40";
    if (name.equals("Goodbye Euromaus")) return "40";
    if (name.equals("Kinderskischule")) return "a15";
    if (name.equals("Miraggio")) return "120";
    if (name.equals("Rapsodia Italiana")) return "120";
    if (name.equals("Die Euromaus in Brasilien 'La copa del mundo'")) return "122";
    if (name.endsWith("e Geburtstagsfete")) return "122";
    if (name.equals("Karneval in Venedig")) return "123";
    if (name.startsWith("'La Seine en F")) return "230";
    if (name.startsWith("Marionetten-Show - Eine au")) return "231";
    if (name.startsWith("Marionetten-Show 'The Fifth Wheel'")) return "231";
    if (name.equals("Das Geheimnis von Schloss Balthasar")) return "232";
    if (name.equals("Das Zeitkarussel")) return "232";
    if (name.startsWith("Arthur 4D")) return "232";
    if (name.equals("Luna Magica")) return "a08";
    if (name.equals("Die Euromaus und die Rustis")) return "122";
    if (name.equals("Zirkus Revue")) return "a20";
    if (name.equals("Bamboe Baai")) return "a22";
    if (name.equals("Eisshow")) return "440";
    if (name.equals("Globe Theater")) return "470";
    if (name.equals("Kinder-Musical")) return "570";
    if (name.equals("Zozo's Clownschule im Kinderland")) return "174";
    if (name.equals("Die Reise des Clowns")) return "174";
    if (name.startsWith("Alles ist K")) return "174";
    if (name.endsWith("Flamenca")) return "771";
    if (name.startsWith("Flamenco evoluci")) return "771";
    if (name.equals("Vivir la vida")) return "771";
    //if (name.equals("Marionetten-Show - The Fifth Wheel")) return "525";
    if (name.equals("Viva Ventura")) return "770";
    if (name.equals("Die Rache der Mylady")) return "770";
    if (name.equals("Die Rache der Milady")) return "770";
    if (name.endsWith("ckkehr des schwarzen Ritters")) return "770";
    // "Rhode Island Waterfire - The Bell Rock Show"
    if (name.startsWith("Rhode Island Waterfire ") && name.indexOf(" The Bell Rock Show") > 0) return "";
    if (name.startsWith("Weihnachtsoase")) return "";
    if (name.equals("Riesenadventskalender")) return "a17";
    if (name.equals("Rustis meet the Beatles")) return "";
    if (name.equals("Lichterparade")) return "";
    if (name.equals("The Magic of Europe")) return ""; // Parade
    if (name.equals("Acrosplash")) return "";
    if (name.equals("'Live: The King'")) return "";
    if (name.startsWith("Piratenschatzsuche mit Kapitn Schwarzbart")) return "";
    if (name.equals("Traumzeit-Dome - Beautiful Europe")) return "";
    if (name.equals("Swing, Twist and Splash")) return "";
    if (name.startsWith("Imperio")) return "";
    if (name.equals("Das Zeitkarussell")) return "";
    if (name.equals("40 Jahre-Parade")) return "";
    if (name.equals("White Balance")) return "";
    if (name.equals("Tanz der Fontnen")) return "";
    if (name.equals("Sonne, Mond, New York")) return "";
    if (name.equals("Stille Nacht, die Kirchenmuse und das Weihnachtslied")) return "";
    return null;
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  private long lastWaitingTimesUpdate = 0;
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    closedAttractionIds.clear();
    downloadWaitingTimesDataUserAgent = "EPGuide/4.4.7 CFNetwork/760.5.1 Darwin/15.5.0";
    //User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13E238 (5600697456)
    //downloadWaitingTimesDataProperties.put("X-Requested-With", "XMLHttpRequest");
    //downloadWaitingTimesDataProperties.put("Accept-Encoding", "gzip, deflate");
    downloadWaitingTimesDataAcceptLanguage = "en-us";
    downloadWaitingTimesDataAccept = "*/*";
    
    
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    String start = "{\"success\":true,\"results\":[";
    if (waitingTimesData != null && waitingTimesData.startsWith(start)) {
      //System.out.println(waitingTimesData);
      //System.exit(1);
      int i = start.length();
      while (i < waitingTimesData.length() && waitingTimesData.charAt(i) == '{') {
        int j = waitingTimesData.indexOf('}', i+1);
        if (j < 0) break;
        int k1 = waitingTimesData.indexOf(':', i+1);
        if (k1 < 0 || k1 > j) {
          WaitingTimesCrawler.trace("wrong format code");
          break;
        }
        int k2 = waitingTimesData.indexOf(',', k1+1);
        if (k2 < 0 || k2 > j) {
          WaitingTimesCrawler.trace("wrong format code2");
          break;
        }
        String code = waitingTimesData.substring(k1+1, k2);
        k1 = waitingTimesData.indexOf(':', k2+1);
        if (k1 < 0 || k1 > j) {
          WaitingTimesCrawler.trace("wrong format time");
          break;
        }
        k2 = waitingTimesData.indexOf(',', k1+1);
        if (k2 < 0 || k2 > j) {
          WaitingTimesCrawler.trace("wrong format time2");
          break;
        }
        String time = waitingTimesData.substring(k1+1, k2);
        k1 = waitingTimesData.indexOf(':', k2+1);
        if (k1 < 0 || k1 > j) {
          WaitingTimesCrawler.trace("wrong format type");
          break;
        }
        k2 = waitingTimesData.indexOf('}', k1+1);
        if (k2 < 0 || k2 > j) {
          WaitingTimesCrawler.trace("wrong format type2");
          break;
        }
        String type = waitingTimesData.substring(k1+1, k2);
        //if (type.equals("1") || type.equals("2")) {
          String attractionId = getAttractionId(code);
          if (attractionId != null) {
            if (attractionId.length() > 0) {
              WaitingTimesItem item = new WaitingTimesItem();
              if (time.startsWith("\"")) time = time.substring(1);
              if (time.endsWith("\"")) time = time.substring(0, time.length()-1);
              if (time.endsWith("+")) time = time.substring(0, time.length()-1);
              if (time.equals("-")) closedAttractionIds.add(attractionId);
              else if (time.length() > 0) {
                try {
                  item.waitTime = Integer.parseInt(time);
                  waitingTimes.put(attractionId, item);
                } catch (NumberFormatException nfe) {
                  nfe.printStackTrace();
                }
              }
            }
          } else WaitingTimesCrawler.trace("No attraction ID defined for '" + code + "\' (" + parkId + ')');
        //}
        i = j+2;
      }
    }
    if (System.currentTimeMillis()-900000 > lastWaitingTimesUpdate) {
      lastWaitingTimesUpdate = System.currentTimeMillis();
      if (parsedDayContent != null && !parsedDayContent.equals(downloadPageHasContent("http://apps.europapark.de/webservices/showtimes/index.php?v=2&lang=de", "UTF-8"))) {
        WaitingTimesCrawler.trace("Calendar refresh needed.");
        requestRefreshCalendar();
      }
      if (updateEntranceOpeningToday()) requestRefreshCalendar();
    }
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
