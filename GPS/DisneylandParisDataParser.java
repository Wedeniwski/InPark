import java.io.*;
import java.text.*;
import java.util.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class DisneylandParisDataParser extends ParkDataParser {
  public DisneylandParisDataParser(String parkId) {
    super(parkId, "Europe/Paris");
  }

  public boolean checkCalendarUpdatesAfterOpening() {
    return true;
  }
  
  public String firstCalendarPage() {
    return "http://disney.cms.pureagency.com/cmsdisney/horaires/hpdeaf.json";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    return null;
  }

  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    /*JSONArray allDays = (JSONArray)JSONValue.parse(calendarPage);
    int n = allDays.size();
    for (int i = 0; i < n; ++i) {
      JSONObject day = (JSONObject)allDays.get(i);
      String date = formatterDate.format(formatterDateSource2.parse((String)day.get("JOUR"), new ParsePosition(0)));
      JSONArray houres = (JSONArray)day.get("HORAIRE");
      String startTime = null;
      String endTime = null;
      String startTimeExtra = null;
      String endTimeExtra = null;
      int m = houres.size();
      for (int j = 0; j < m; ++j) {
        JSONObject info = (JSONObject)houres.get(j);
        String debtime = (String)info.get("DEBTIME");
        String fintime = (String)info.get("FINTIME");
        if (debtime.equals(fintime)) continue;
        String segment = (String)info.get("SEGMENT");
        String park = (String)info.get("PARC");
        if (parkId.equals("fdlp") && park.equals("P1") || parkId.equals("fdsp") && park.equals("P2")) {
          if (segment.equals("DAY")) {
            startTime = debtime;
            endTime = fintime;
          } else if (segment.equals("EMH")) {
            startTimeExtra = debtime;
            endTimeExtra = fintime;
          } else WaitingTimesCrawler.trace("unknown segment " + segment);
        }
      }
      if (startTime != null && endTime != null) {
        calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, startTimeExtra, endTimeExtra, null, null, false));
      }
    }*/
    String searchOpening = null;
    String searchOpeningExtra = null;
    if (parkId.equals("fdlp")) {
      searchOpening = "{\"PARC\":\"P1\",\"SEGMENT\":\"DAY\",\"DEBTIME\":\"";
      searchOpeningExtra = "{\"PARC\":\"P1\",\"SEGMENT\":\"EMH\",\"DEBTIME\":\"";
    } else {
      searchOpening = "{\"PARC\":\"P2\",\"SEGMENT\":\"DAY\",\"DEBTIME\":\"";
      searchOpeningExtra = "{\"PARC\":\"P2\",\"SEGMENT\":\"EMH\",\"DEBTIME\":\"";
    }
    int i = 0;
    while (true) {
      i = calendarPage.indexOf("{\"JOUR\":\"", i);
      if (i < 0) break;
      String date = formatterDate.format(formatterDateSource2.parse(calendarPage.substring(i+9, i+17), new ParsePosition(0)));
      int ix = calendarPage.indexOf(searchOpeningExtra, i+17);
      i = calendarPage.indexOf(searchOpening, i+17);
      if (i < 0) {
        WaitingTimesCrawler.trace("Calendar data for date " + date + " is uncomplete!");
        return !calendarData.isEmpty();
      }
      i += searchOpening.length();
      int j = calendarPage.indexOf("\",\"FINTIME\":\"", i);
      if (j < 0) { System.out.println("FINTIME not found for date " + date); return false; }
      if (i+5 != j) continue; // assuming closed, ignore entry
      String startTimeExtra = null;
      String endTimeExtra = null;
      if (ix >= 0) {
        ix += searchOpeningExtra.length();
        int jx = calendarPage.indexOf("\",\"FINTIME\":\"", ix);
        if (jx >= 0 && ix+5 == jx) {
          startTimeExtra = calendarPage.substring(ix, jx);
          endTimeExtra = calendarPage.substring(jx+13, jx+18);
          if (startTimeExtra.equals(endTimeExtra)) startTimeExtra = endTimeExtra = null;
        }
      }
      String startTime = calendarPage.substring(i, j);
      String endTime = calendarPage.substring(j+13, j+18);
      if (!startTime.equals(endTime)) {
        calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, startTimeExtra, endTimeExtra, null, null, false));
      }
      i = j+18;
    }
    downloadWaitingTimesDataCompressed = true;
    downloadWaitingTimesDataPOST = "key=Ajjjsh;Uj&json=%7B%22tp%22:991,%22h2%22:0,%22si%22:0,%22h1%22:0,%22lg%22:0%7D";
    downloadWaitingTimesDataUserAgent = "Disneyland 1.2 (iPad; iPhone OS 5.1.1; en_US)";
    final String showTimesData = downloadPageHasContent("http://disney.cms.pureagency.com/cms/ProxyContent", "UTF-8");
    if (showTimesData != null) {
      String endHours = getParkHoursTo();
      // ["20130104-P1MS09-0","P1MS09","Fontaines Chateau","Central Plaza",201301041845,"",1,1]
      i = showTimesData.indexOf(":[[\"");
      while (i > 0 && i < showTimesData.length() && showTimesData.charAt(i) != ']') {
        int k = showTimesData.indexOf(']', i+4);
        i = showTimesData.indexOf("\",\"", i+4);
        if (i > 0) {
          i += 3;
          int j = showTimesData.indexOf("\",\"", i);
          if (j > 0) {
            String name = showTimesData.substring(i, j);
            i = showTimesData.indexOf("\",\"", j+3);
            if (i > 0) {
              i = showTimesData.indexOf("\",", i+3);
              if (i > 0) {
                j = i += 2;
                while (j < k && Character.isDigit(showTimesData.charAt(j))) ++j;
                if (j < k && j-i == 12) {
                  String attractionId = getAttractionId(name);
                  if (attractionId != null) {
                    if (attractionId.length() > 0) {
                      String date = "" + showTimesData.charAt(i+6) + showTimesData.charAt(i+7) + '.' + showTimesData.charAt(i+4) + showTimesData.charAt(i+5) + '.' + showTimesData.charAt(i) + showTimesData.charAt(i+1) + showTimesData.charAt(i+2) + showTimesData.charAt(i+3);
                      String startTime = "" + showTimesData.charAt(i+8) + showTimesData.charAt(i+9) + ':' + showTimesData.charAt(i+10) + showTimesData.charAt(i+11);
                      Set<String> aId = new HashSet<String>(2);
                      aId.add(attractionId);
                      if (startTime.equals(endHours)) {
                        long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()-60000*getAttractionDuration(attractionId);
                        calendarData.add(aId, new CalendarItem(date, date, formatterHour2.format(new Date(time)), startTime, null, null, null, null, false));
                      } else {
                        long time = formatterHour2.parse(startTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(attractionId);
                        calendarData.add(aId, new CalendarItem(date, date, startTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
                      }
                    }
                  } else WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
                }
              }
            }
          }
        }
        i = k+1;
      }
      //System.out.println(showTimesData);
      //System.out.println(calendarData);
      //System.exit(1);
    }
    downloadWaitingTimesDataCompressed = false;
    downloadWaitingTimesDataPOST = null;
    downloadWaitingTimesDataUserAgent = "";
    return true;
  }

  public String getWaitingTimesDataURL() {
    return "http://disney.cms.pureagency.com/cms/ProxyTempsAttente";
  }

  protected String getAttractionId(String name) {
    if (parkId.equals("fdlp")) {
      if (name.equals("P1MA01")) return "a10"; // Thunder Mesa Riverboat Landing
      if (name.equals("P1MA04")) return "a04"; // Main Street Vehicles
      if (name.equals("P1MA06")) return "ch11"; // Meet Mickey Mouse
      if (name.equals("P1NA00")) return "a31"; // Alice's Curious Labyrinth
      if (name.equals("P1NA01")) return "a24"; // Blanche-Neige et les Sept Nains
      if (name.equals("P1NA02")) return "a26"; // Le Carrousel de Lancelot
      if (name.equals("P1NA03")) return "a33"; // Casey Jr. - le Petit Train du Cirque
      if (name.equals("P1NA05")) return "a30"; // Dumbo the Flying Elephant
      if (name.equals("P1NA07")) return "a35"; // "it's a small world"
      if (name.equals("P1NA08")) return "a32"; // Mad Hatter's Tea Cups
      if (name.equals("P1NA09")) return "a34"; // Le Pays des Contes de Fees
      if (name.equals("P1NA10")) return "a27"; // Peter Pan's Flight
      if (name.equals("P1NA13")) return "a25"; // Les Voyages de Pinocchio
      if (name.equals("P1NA17")) return "ch06"; // Disney Princesses: A Royal Invitation
      if (name.equals("P1DA03")) return "a47"; // Autopia
      if (name.equals("P1DA04")) return "a37"; // Buzz Lightyear Laser Blast
      if (name.equals("P1DA06")) return "a45"; // Les Mysteres du Nautilus
      if (name.equals("P1DA07")) return "a38"; // Orbitron
      if (name.equals("P1DA08")) return "a46"; // Space Mountain
      if (name.equals("P1DA09")) return "a42"; // Star Tours
      if (name.equals("P1DA12")) return "a44"; // Captain EO
      if (name.equals("P1AA01")) return "a17"; // La Cabane des Robinson
      if (name.equals("P1AA02")) return "a20"; // Indiana Jones and the Temple of Peril
      if (name.equals("P1AA04")) return "a22"; // Pirates of the Caribbean
      if (name.equals("P1RA00")) return "a12"; // Big thunder mountain
      if (name.equals("P1RA03")) return "a09"; // Phantom Manor
      if (name.equals("P1RA04")) return "a08"; // River Rogue Keelboats
      if (name.equals("P1RA06")) return "a08"; // River Rogue Keelboats
      if (name.equals("P1GS04")) return "a56"; // Disney Dreams
      if (name.equals("P1GS05")) return "ch01"; // Disney Magic on Parade!
      if (name.equals("P1GS06")) return ""; // Christmas Cavalcade
      if (name.equals("P1MS07")) return "ch03"; // Le Train Disney du 20e Anniversaire
      if (name.equals("P1MS09")) return "a36"; // Fontaines Chateau
      if (name.equals("P1MS05")) return ""; // ?
      if (name.equals("P1GS08")) return ""; // ?
      if (name.equals("P1GS09")) return ""; // ?
      if (name.equals("P1DS03")) return ""; // ?
      if (name.equals("P1DS04")) return ""; // ?
      if (name.equals("P1DA13")) return ""; // ?
      if (name.startsWith("P2")) return "";
    } else if (parkId.equals("fdsp")) {
      if (name.equals("P2XA03")) return "a105"; // Crush's Coaster
      if (name.equals("P2XA06")) return "a117"; // RC Racer
      if (name.equals("P2ZA01")) return "a109"; // Rock'n'Roller Coaster
      if (name.equals("P2XA00")) return "a114"; // Studio Tram Tour
      if (name.equals("P2XA01")) return "a112"; // Art of Disney Animation
      if (name.equals("P2ZA00")) return "a107"; // Armageddon : les Effets Speciaux
      if (name.equals("P2XA08")) return "a116"; // Slinky Dog Zigzag Spin
      if (name.equals("P2XA02")) return "a104"; // Cars Quatre Roues Rallye
      if (name.equals("P2XA07")) return "a115"; // Toy Soldiers Parachute Drop
      if (name.equals("P2ZA02")) return "a113"; // The Twilight Zone Tower of Terror
      if (name.equals("P2XA05")) return "a106"; // Les Tapis Volants - Flying Carpets
      if (name.equals("P2YS00")) return "a110"; // Moteurs Action ! Stunt Show Spectacular
      if (name.equals("P2YS01")) return "a102"; // CinéMagique
      if (name.equals("P2YS02")) return "a108"; // Playhouse Disney Live on Stage!
      if (name.equals("P2YS03")) return "a111"; // Stitch Live!
      if (name.equals("P2YS05")) return "a103"; // Animagique
      if (name.equals("P2PS00")) return ""; // Disney's Stars'n' Cars
      if (name.equals("P2XA09")) return ""; // ?
      if (name.equals("P2YS06")) return ""; // Disney Junior
      if (name.startsWith("P1")) return "";
    }
    name = removeSpecialCharacters(name);
    return super.getAttractionId(name);
  }

  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    downloadWaitingTimesDataCompressed = true;
    downloadWaitingTimesDataPOST = "key=Ajjjsh;Uj";
    downloadWaitingTimesDataUserAgent = "Disneyland 1.2 (iPad; iPhone OS 5.1.1; en_US)";
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    downloadWaitingTimesDataCompressed = false;
    downloadWaitingTimesDataPOST = null;
    downloadWaitingTimesDataUserAgent = "";
    if (waitingTimes == null || waitingTimesData == null) return null;
    int i = waitingTimesData.indexOf(":[\"");
    //System.out.println(waitingTimesData);
    while (i > 0 && i < waitingTimesData.length() && waitingTimesData.charAt(i) != ']') {
      while (i < waitingTimesData.length() && waitingTimesData.charAt(i) != '\"') ++i;
      ++i;
      int j = waitingTimesData.indexOf("\",\"", i);
      if (j > 0) {
        String name = waitingTimesData.substring(i, j);
        i = waitingTimesData.indexOf("\",\"", j+3);
        if (i > 0) {
          i = waitingTimesData.indexOf("\",", i+3);
          if (i > 0 && i+2 < waitingTimesData.length()) {
            i += 2;
            if (waitingTimesData.charAt(i) == '1' && waitingTimesData.charAt(i+1) == ',') {
              i += 2;
              j = waitingTimesData.indexOf(",\"", i);
              if (j < 0) j = waitingTimesData.indexOf(']', i);
              if (j > 0) {
                String attractionId = getAttractionId(name);
                if (attractionId != null) {
                  if (attractionId.length() > 0) {
                    WaitingTimesItem item = new WaitingTimesItem();
                    item.waitTime = Integer.parseInt(waitingTimesData.substring(i, j));
                    waitingTimes.put(attractionId, item);
                  }
                } else WaitingTimesCrawler.trace("No attraction ID defined for " + name + " (" + parkId + ')');
              }
            }
          }          
        }
      }
    }
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    Set<String> closedAttractionIds = new HashSet<String>(7);
    int i = waitingTimesData.indexOf(":[\"");
    while (i > 0 && i < waitingTimesData.length() && waitingTimesData.charAt(i) != ']') {
      while (i < waitingTimesData.length() && waitingTimesData.charAt(i) != '\"') ++i;
      ++i;
      int j = waitingTimesData.indexOf("\",\"", i);
      if (j > 0) {
        String name = waitingTimesData.substring(i, j);
        i = waitingTimesData.indexOf("\",\"", j+3);
        if (i > 0) {
          i = waitingTimesData.indexOf("\",", i+3);
          if (i > 0 && i+2 < waitingTimesData.length()) {
            i += 2;
            if ((waitingTimesData.charAt(i) == '0' || waitingTimesData.charAt(i) == '2') && waitingTimesData.charAt(i+1) == ',') {
              i += 2;
              j = waitingTimesData.indexOf(",\"", i);
              if (j < 0) j = waitingTimesData.indexOf(']', i);
              if (j > 0) {
                String attractionId = getAttractionId(name);
                if (attractionId == null) System.out.println("No attraction ID defined for " + name + " (" + parkId + ')');
                else if (attractionId.length() > 0) closedAttractionIds.add(attractionId);
              }
            }
          }          
        }
      }
    }
    return closedAttractionIds;
  }
}