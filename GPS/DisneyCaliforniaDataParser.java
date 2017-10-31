import java.io.*;
import java.text.*;
import java.util.*;
import javax.xml.parsers.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;
import org.w3c.dom.*;

public class DisneyCaliforniaDataParser extends ParkDataParser {
  private Map<String, String> names;

  public DisneyCaliforniaDataParser(String parkId) {
    super(parkId, "America/Los_Angeles");
    names = null;
    //downloadWaitingTimesDataCharsetName = "UTF16";
  }

  public String firstCalendarPage() {
    Calendar rightNow = rightNow();
    return "https://disneyland.disney.go.com/fragment/calendar-monthly.xml?&month=" + formatterYearMonth.format(rightNow.getTime());
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    if (contentOfPreviousPage.indexOf("<day id=\"") < 0) return null;
    Calendar rightNow = rightNow();
    String ym = formatterYearMonth.format(rightNow.getTime());
    int month = (ym.charAt(4)-'0')*10 + (ym.charAt(5)-'0');
    int year = (ym.charAt(0)-'0')*1000 + (ym.charAt(1)-'0')*100 + (ym.charAt(2)-'0')*10 + (ym.charAt(3)-'0');
    if (++month >= 13) {
      month = 1;
      ++year;
    }
    ym = String.format("%04d%02d", year, month);
    return (numberOfDownloadedPages >= 2 || contentOfPreviousPage.indexOf("<day id=\"" + ym) >= 0)? null : "https://disneyland.disney.go.com/fragment/calendar-monthly.xml?&month=" + ym;
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
      WaitingTimesCrawler.trace("getStartTime: '" + originStartEndTime + "' cannot be parsed");
      return null;
    }
    return formatterHour2.format(d);
  }

  private String getEndTime(String startEndTime) {
    if (startEndTime.startsWith("Not available today") || startEndTime.startsWith("All Day Event") || startEndTime.startsWith("Special Events")) return null;
    int i = posEndTime(startEndTime, true);
    if (i < 0) {
      WaitingTimesCrawler.trace("getEndTime: '" + startEndTime + "' cannot be parsed");
      return null;
    }
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.substring(i), " ", "");
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
  }

  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    Set<String> parkEntrances = getParkEntrances();
    calendarPage = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><days>" + replace(calendarPage, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "") + "</days>";
    try {
      DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
      Document calendarDoc = builder.parse(new ByteArrayInputStream(calendarPage.getBytes("UTF-8")));
      NodeList monthList = calendarDoc.getChildNodes();
      monthList = monthList.item(0).getChildNodes(); // days
      for (int i = 0; i < monthList.getLength(); ++i) {
        if (monthList.item(i).getNodeName().equals("monthly")) {
          //System.out.println("month=" + monthNode.getAttributes().getNamedItem("id").getNodeValue());
          NodeList month = monthList.item(i).getChildNodes();
          for (int i2 = 0; i2 < month.getLength(); ++i2) {
            if (month.item(i2).getNodeName().equals("days")) {
              NodeList days = month.item(i2).getChildNodes();
              for (int i3 = 0; i3 < days.getLength(); ++i3) {
                Node day = days.item(i3);
                if (day.getNodeName().equals("day")) {
                  String originDate = day.getAttributes().getNamedItem("id").getNodeValue();
                  String date = formatterDate.format(formatterDateSource.parse(originDate, new ParsePosition(0)));
                  NodeList locations = day.getChildNodes();
                  for (int i4 = 0; i4 < locations.getLength(); ++i4) {
                    if (locations.item(i4).getNodeName().equals("location")) {
                      String locationName = locations.item(i4).getAttributes().getNamedItem("value").getNodeValue();
                      if (parkId.equals("usdlca") && locationName.equals("dlp") || parkId.equals("usdcaca") && locationName.equals("dca")) {
                        NodeList hours = locations.item(i4).getChildNodes();
                        for (int i5 = 0; i5 < hours.getLength(); ++i5) {
                          if (hours.item(i5).getNodeName().equals("hours")) {
                            String startEndTime = hours.item(i5).getTextContent();
                            String startTime = getStartTime(startEndTime);
                            String endTime = getEndTime(startEndTime);
                            String startTimeExtra = null;
                            String endTimeExtra = null;
                            String startTimeExtra2 = null;
                            String endTimeExtra2 = null;
                            String dayContent = downloadPageHasContent("https://disneyland.disney.go.com/fragment/calendar-daily.xml?&day=" + originDate, "UTF-8", 1);
                            if (dayContent == null) {
                              WaitingTimesCrawler.trace("Missing day content for " + originDate);
                              return true;
                            }
                            try {
                              Document dayDoc = builder.parse(new ByteArrayInputStream(dayContent.getBytes("UTF-8")));
                              NodeList dayList = dayDoc.getChildNodes();
                              for (int j = 0; j < dayList.getLength(); ++j) {
                                if (dayList.item(j).getNodeName().equals("daily")) {
                                  NodeList dayLocations = dayList.item(j).getChildNodes();
                                  for (int j2 = 0; j2 < dayLocations.getLength(); ++j2) {
                                    if (dayLocations.item(j2).getNodeName().equals("location")) {
                                      String dayLocationName = dayLocations.item(j2).getAttributes().getNamedItem("value").getNodeValue();
                                      if (parkId.equals("usdlca") && dayLocationName.equals("dlp") || parkId.equals("usdcaca") && dayLocationName.equals("dca")) {
                                        NodeList extraHours = dayLocations.item(j2).getChildNodes();
                                        for (int j3 = 0; j3 < extraHours.getLength(); ++j3) {
                                          Node specialHours = extraHours.item(j3);
                                          if (specialHours.getNodeName().equals("magicHours")) {
                                            NodeList extraHour = specialHours.getChildNodes();
                                            for (int j4 = 0; j4 < extraHour.getLength(); ++j4) {
                                              if (extraHour.item(j4).getNodeName().equals("hours")) {
                                                startEndTime = extraHour.item(j4).getTextContent();
                                                startTimeExtra = getStartTime(startEndTime);
                                                endTimeExtra = getEndTime(startEndTime);
                                              }
                                            }
                                          } else if (specialHours.getNodeName().equals("resortEvents")) {
                                            NodeList extraHour = specialHours.getChildNodes();
                                            for (int j4 = 0; j4 < extraHour.getLength(); ++j4) {
                                              if (extraHour.item(j4).getNodeName().equals("resortEvent")) {
                                                NodeList event = extraHour.item(j4).getChildNodes();
                                                String attractionId = null;
                                                String eventTimes = null;
                                                for (int j5 = 0; j5 < event.getLength(); ++j5) {
                                                  Node eventNode = event.item(j5);
                                                  if (eventNode.getNodeName().equals("title")) {
                                                    String eventTitle = eventNode.getTextContent();
                                                    attractionId = getAttractionId(eventTitle);
                                                    if (attractionId != null && attractionId.length() == 0) attractionId = null;
                                                    //if (attractionId == null) System.out.println("No attraction ID for " + eventTitle);
                                                  } else if (eventNode.getNodeName().equals("hours")) {
                                                    if (attractionId != null) {
                                                      //System.out.println("Hours for " + attractionId + ": " + eventNode.getTextContent());
                                                      for (String aId : attractionId.split(",")) {
                                                        Set<String> aIds = new HashSet<String>(2);
                                                        aIds.add(aId);
                                                        StringTokenizer allOpeningHours = new StringTokenizer(eventNode.getTextContent(), ".m.");
                                                        List<CalendarItem> calendarItems = new ArrayList<CalendarItem>(10);
                                                        String eventEndTime = null;
                                                        while (eventEndTime != null || allOpeningHours.hasMoreTokens()) {
                                                          // 10:30 a.m.11:35 a.m.12:40 p.m.2:25 p.m.3:30 p.m.4:35 p.m.
                                                          // 12:15 p.m. to 12:40 p.m.1:30 p.m. to 1:55 p.m.3:15 p.m. to 3:40 p.m.4:30 p.m. to 4:55 p.m.5:30 p.m. to 5:55 p.m.
                                                          String eventStartTime = getStartTime((eventEndTime != null)? eventEndTime : allOpeningHours.nextToken() + ".m.");
                                                          eventEndTime = null;
                                                          if (eventStartTime != null) {
                                                            if (allOpeningHours.hasMoreTokens()) {
                                                              eventEndTime = allOpeningHours.nextToken() + ".m.";
                                                              if (getAttractionDuration(aId) <= 0 && posEndTime(eventEndTime, true) >= 0) {
                                                                calendarItems.add(new CalendarItem(date, date, eventStartTime, getEndTime(eventEndTime), null, null, null, null, false));
                                                              } else {
                                                                long time = formatterHour2.parse(eventStartTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(aId);
                                                                calendarItems.add(new CalendarItem(date, date, eventStartTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
                                                              }
                                                              eventEndTime = null;
                                                            } else {
                                                              long time = formatterHour2.parse(eventStartTime, new ParsePosition(0)).getTime()+60000*getAttractionDuration(aId);
                                                              calendarItems.add(new CalendarItem(date, date, eventStartTime, formatterHour2.format(new Date(time)), null, null, null, null, false));
                                                            }
                                                          }
                                                        }
                                                        calendarData.add(aIds, calendarItems);
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            } catch (Exception e) {
                              WaitingTimesCrawler.trace("Error in document at https://disneyland.disney.go.com/fragment/calendar-daily.xml?&day=" + originDate);
                              e.printStackTrace();
                            }
                            calendarData.add(parkEntrances, new CalendarItem(date, date, startTime, endTime, startTimeExtra, endTimeExtra, startTimeExtra2, endTimeExtra2, false));
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (ParserConfigurationException e) {
      WaitingTimesCrawler.trace("The underlying parser does not support the requested features.");
    } catch (FactoryConfigurationError e) {
      WaitingTimesCrawler.trace("Error occurred obtaining Document Builder Factory.");
    } catch (Exception e) {
      e.printStackTrace();
    }
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  public String getWaitingTimesDataURL() {
    downloadWaitingTimesDataUserAgent = "Mdx/3.4.2 (iPhone; iOS 9.3.1; Scale/2.00)";
    downloadWaitingTimesDataPOST = "grant_type=assertion&assertion_type=public&client_id=WDPRO-MOBILE.CLIENT-PROD";
    disableCertificateValidation();
    final String authorization = downloadPageHasContent("https://authorization.go.com/token", "UTF-8");
    String downloadWaitingTimesDataAuthorization = null;
    downloadWaitingTimesDataUserAgent = null;
    downloadWaitingTimesDataPOST = null;
    if (authorization != null) {
      String s = "\"access_token\":\"";
      int i = authorization.indexOf(s);
      if (i >= 0) {
        i += s.length();
        int j = authorization.indexOf('\"', i);
        if (j > i) {
          String accessToken = authorization.substring(i, j);
          s = "\"token_type\":\"";
          i = authorization.indexOf(s);
          if (i >= 0) {
            i += s.length();
            j = authorization.indexOf('\"', i);
            if (j > i) {
              String tokenType = authorization.substring(i, j);
              downloadWaitingTimesDataAuthorization = authorization.substring(i, j) + ' ' + accessToken;
            }
          }
        }
      }
      if (downloadWaitingTimesDataAuthorization != null) {
        downloadWaitingTimesDataProperties.put("Authorization", downloadWaitingTimesDataAuthorization);
        String pId = "";
        if (parkId.equals("usdlca")) pId = "330339";
        if (parkId.equals("usdcaca")) pId = "336894";
        return "https://api.wdpro.disney.go.com/facility-service/theme-parks/" + pId + ";entityType=theme-park/wait-times";
      }
    }
    return null;
    /*Calendar rightNow = rightNow();
    int time = rightNow.get(Calendar.HOUR_OF_DAY)*60+rightNow.get(Calendar.MINUTE);
    int pId = (parkId.equals("usdlca"))? 330339 : 336894;
    return "http://dparks.uiemedia.net/dmm_v2/jsondata/JsonUpdateData?version=18&p=" +  pId + "&t=" + time;*/
  }

  /*public String getMasterDataURL() {
    Calendar rightNow = rightNow();
    int time = rightNow.get(Calendar.HOUR_OF_DAY)*60+rightNow.get(Calendar.MINUTE);
    int pId = (parkId.equals("usdlca"))? 330339 : 336894;
    return "http://dparks.uiemedia.net/dmm_v2/jsondata/JsonMasterData?version=18&p=" +  pId + "&t=" + time;
  }*/
  
  protected String getAttractionId(String name) {
    name = removeSpecialCharacters(name);
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (name.startsWith("Fire Engine")) return "a103";
    if (name.startsWith("Horse-Drawn Streetcars")) return "a104,a171";
    if (name.startsWith("Horseless Carriage")) return "a102,a169";
    if (name.startsWith("Omnibus")) return "a105,a172";
    if (name.equals("Main Street Vehicles")) return "a102,a169,a103,a105,a172,a104,a171";
    if (name.equals("Disneyland Railroad - Main Street, U.S.A.")) return "a101";
    if (name.equals("Disneyland Railroad: New Orleans Square Station")) return "a114";
    if (name.equals("Disneyland Railroad - New Orleans Square")) return "a114";
    if (name.equals("Disneyland Railroad: Tomorrowland Station")) return "a153";
    if (name.equals("Disneyland Railroad - Tomorrowland")) return "a153";
    if (name.equals("Disneyland Railroad: Toontown Depot")) return "a142";
    if (name.equals("Disneyland Railroad - Mickey's Toontown")) return "a142";
    if (name.equals("Big Thunder Ranch - Animals")) return "a125";
    if (name.startsWith("Enchanted Tiki Room")) return "a109";
    if (name.startsWith("\\\"it's a small world\\\"")) return "a140";
    if (name.equals("\\\"Captain EO\\\"")) return "a156";
    if (name.equals("Captain EO")) return "a156";
    if (name.equals("Gadget's Go Coaster, presented by Sparkle")) return "a145";
    if (name.equals("Billy Hill & The Hillbillies")) return "a120";
    if (name.equals("Disney Junior &#8211; Live on Stage!")) return "a305";
    if (name.equals("Muppet*Vision 3D")) return "a306";
    if (name.equals("Disney's Aladdin &#8211; A Musical Spectacular")) return "a313";
    if (name.equals("Tuck and Roll's Drive 'Em Buggies")) return "a317";
    if (name.startsWith("Luigi's Flying Tires")) return "a322";
    if (name.equals("Toy Story Mania!")) return "a328";
    if (name.startsWith("Goofy's Sky School")) return "a331";
    return null;
  }
  
  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    if (waitingTimes == null) return null;
    //System.out.println(waitingTimesData);
    //System.exit(1);
    closedAttractionIds.clear();
    // ToDo: change to parse JSON
    // ToDo: remove "208" Problem in Universal Parser
    int i = 0;
    int j = 0;
    while (true) {
      i = waitingTimesData.indexOf("\"waitTime\":", i);
      j = waitingTimesData.indexOf("\"name\":\"", j);
      if (i < 0 || j < 0) break;
      i += 11; j += 8;
      int k = waitingTimesData.indexOf('\"', j+1);
      while (k > 0 && waitingTimesData.charAt(k-1) == '\\') k = waitingTimesData.indexOf('\"', k+1);
      if (k < 0) { System.out.println("attraction name cannot be identified!"); break; }
      String name = waitingTimesData.substring(j, k);
      j = waitingTimesData.indexOf("}}", i);
      String attractionId = getAttractionId(name);
      k = waitingTimesData.indexOf("\"status\":\"Closed\"", i);
      if (k > i && k < j) {
        if (attractionId != null) {
          if (attractionId.length() > 0) for (String aId : attractionId.split(",")) closedAttractionIds.add(aId);
        } else WaitingTimesCrawler.trace("attraction closed but no attraction ID defined for " + name + " (" + parkId + ')');
        i = k;
      } else {
        k = waitingTimesData.indexOf("\"fastPass\":{", i);
        if (k > i && k < j) {
          int k2 = waitingTimesData.indexOf("\"available\":true", k);
          if (k2 > i && k2 < j) {
            k = waitingTimesData.indexOf("\"startTime\":\"", k);
            if (k > i && k < j) {
              k += 13;
              String startTime = waitingTimesData.substring(k, k+2) + waitingTimesData.substring(k+3, k+5);
              k = waitingTimesData.indexOf("\"endTime\":\"", k);
              if (k > i && k < j) {
                if (attractionId == null) WaitingTimesCrawler.trace("fastPass available but no attraction ID defined for " + name + " (" + parkId + ')');
                else if (attractionId.length() > 0) {
                  String endTime = waitingTimesData.substring(k+11, k+13) + waitingTimesData.substring(k+14, k+16);
                  WaitingTimesItem item = new WaitingTimesItem();
                  item.fastLaneAvailable = 1;
                  item.fastLaneAvailableTimeFrom = startTime;
                  item.fastLaneAvailableTimeTo = endTime;
                  for (String aId : attractionId.split(",")) waitingTimes.put(aId, item);
                }
              } else {
                k = waitingTimesData.indexOf("\"startTime\":\"FASTPASS is Not Available\"", i);
                if (k > i && k < j) {
                  if (attractionId == null) WaitingTimesCrawler.trace("fastPass not available but no attraction ID defined for " + name + " (" + parkId + ')');
                  else if (attractionId.length() > 0) {
                    WaitingTimesItem item = new WaitingTimesItem();
                    item.fastLaneAvailable = 0;
                    for (String aId : attractionId.split(",")) waitingTimes.put(attractionId, item);
                  }
                } else {
                  WaitingTimesCrawler.trace("missing endTime for attraction " + name + " (" + attractionId + ')');
                  // "name":"California Screamin'","id":"353303;entityType=Attraction","links":{"attractions":{"href":"https://api.wdpro.disney.go.com/global-pool-override-A/facility-service/attractions/353303;entityType=Attraction"},"self":{"href":"https://api.wdpro.disney.go.com/global-pool-override-A/facility-service/attractions/353303/wait-times"}}},{"type":"Attraction","waitTime":{"status":"Operating","rollUpStatus":"Operating","singleRider":false,"rollUpWaitTimeMessage":"Open Throughout the Day","fastPass":{"available":false}}
                  //System.out.println(waitingTimesData);
                  //System.exit(1);
                }
              }
            } else WaitingTimesCrawler.trace("missing startTime for attraction " + name + " (" + attractionId + ')');
          }
        }
        k = waitingTimesData.indexOf("\"postedWaitMinutes\":", i);
        if (k > i && k < j) {
          k += 20;
          i = waitingTimesData.indexOf(',', k);
          if (i > k && i < j) {
            if (attractionId == null) WaitingTimesCrawler.trace("waitTime available but no attraction ID defined for " + name + " (" + parkId + ')');
            else if (attractionId.length() > 0) {
              for (String aId : attractionId.split(",")) {
                if (!isTrain(aId)) {
                  WaitingTimesItem item = waitingTimes.get(aId);
                  if (item == null) item = new WaitingTimesItem();
                  String t = waitingTimesData.substring(k, i);
                  if (t.endsWith("}")) t = t.substring(0, t.length()-1);
                  item.waitTime = Integer.parseInt(t);
                  waitingTimes.put(aId, item);
                }
              }
            }
          } else WaitingTimesCrawler.trace("missing delimiter after postedWaitMinutes for attraction " + name + " (" + attractionId + ')');
          i = k;
        }
      }
    }
    return waitingTimes;
  }
  
  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }
}
