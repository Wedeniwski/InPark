import java.io.*;
import java.security.*;
import java.text.*;
import java.util.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public class EftelingDataParser extends ParkDataParser {
  public EftelingDataParser() {
    super("nlde", "Europe/Paris");
  }

  public boolean checkCalendarUpdatesAfterOpening() {
    return true;
  }
  
  public String firstCalendarPage() {
    //http://www.efteling.com/showtijden
    return "https://www.efteling.com/en/park/opening-hours";
    //return "http://www.efteling.com/de/park/oeffnungszeiten/";
  }

  public String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage) {
    return null;
  }

  private String getStartTime(String startEndTime) {
    String originStartEndTime = startEndTime;
    startEndTime = replace(startEndTime.toLowerCase(), " ", "");
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

  private String poi = null;
  protected boolean updateCalendarData(int pageNumber, String calendarPage) {
    setSSLContext();
    String url = "https://mobile-services.efteling.com/v3/feedsde/poi-feed/";
    downloadWaitingTimesDataUserAgent = "Dalvik/1.6.0 (Linux; U; Android 4.2.2; GT-P3100 Build/JDQ39)";
    downloadWaitingTimesDataProperties.put("X-Digest", getDigest(url));
    downloadWaitingTimesDataProperties.put("x-api-version", "3");
    downloadWaitingTimesDataAcceptLanguage = "de;q=1, en;q=0.9, fr;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5";
    downloadWaitingTimesDataAccept = "application/json; version=2";
    downloadWaitingTimesDataContentType = "application/json; charset=utf-8";
    //downloadWaitingTimesDataProperties.put("Accept-Encoding", "gzip");
    poi = downloadPageHasContent(url, "UTF-8");
    
    Set<String> parkEntrances = getParkEntrances();
    //System.out.println("DEBUG park entrances: " + parkEntrances);
    calendarData.add(parkEntrances, new CalendarItem("02.02.2016", "24.03.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("25.03.2016", "26.06.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("01.07.2016", "01.07.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("02.07.2016", "02.07.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("03.07.2016", "08.07.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("09.07.2016", "09.07.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("10.07.2016", "15.07.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("16.07.2016", "16.07.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("17.07.2016", "22.07.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("23.07.2016", "23.07.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("24.07.2016", "29.07.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("30.07.2016", "30.07.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("31.07.2016", "05.08.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("06.08.2016", "06.08.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("07.08.2016", "12.08.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("13.08.2016", "13.08.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("14.08.2016", "19.08.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("20.08.2016", "20.08.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("21.08.2016", "26.08.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("27.08.2016", "27.08.2016", "10:00", "00:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("28.08.2016", "31.08.2016", "10:00", "20:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("01.09.2016", "13.11.2016", "10:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("14.11.2016", "18.11.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("19.11.2016", "20.11.2016", "11:00", "19:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("21.11.2016", "25.11.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("26.11.2016", "27.11.2016", "11:00", "19:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("28.11.2016", "02.12.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("03.12.2016", "04.12.2016", "11:00", "19:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("05.12.2016", "09.12.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("10.12.2016", "11.12.2016", "11:00", "19:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("12.12.2016", "16.12.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("17.12.2016", "18.12.2016", "11:00", "19:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("19.12.2016", "23.12.2016", "11:00", "18:00", null, null, null, null, false));
    calendarData.add(parkEntrances, new CalendarItem("24.12.2016", "30.12.2016", "11:00", "20:00", null, null, null, null, true));
    calendarData.add(parkEntrances, new CalendarItem("31.12.2016", "31.12.2016", "11:00", "18:00", null, null, null, null, true));
    calendarData.add(parkEntrances, new CalendarItem("01.01.2017", "08.01.2017", "11:00", "20:00", null, null, null, null, true));

    /* ToDo:
     "OpeningHours": {
     "Date": "2013-11-20T00:00:00",
     "BusyIndication": null,
     "HourFrom": "2013-11-20T11:00:00",
     "HourTo": "2013-11-20T18:00:00"
     },
     */

    url = "https://mobile-services.efteling.com/v3/wis/";
    downloadWaitingTimesDataUserAgent = "Dalvik/1.6.0 (Linux; U; Android 4.2.2; GT-P3100 Build/JDQ39)";
    downloadWaitingTimesDataProperties.put("X-Digest", getDigest(url));
    downloadWaitingTimesDataProperties.put("x-api-version", "3");
    downloadWaitingTimesDataAcceptLanguage = "de;q=1, en;q=0.9, fr;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5";
    downloadWaitingTimesDataAccept = "application/json; version=2";
    downloadWaitingTimesDataContentType = "application/json; charset=utf-8";
    String waitingTimesData = null;
    try {
      waitingTimesData = decrypt(downloadPageHasContent(url, "UTF-8"), "1768257091023496");
      //System.out.println(waitingTimesData);
      //System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
    if (waitingTimesData != null) {
      Calendar rightNow = rightNow();
      String today = String.format("%02d.%02d.%04d", rightNow.get(Calendar.DAY_OF_MONTH), rightNow.get(Calendar.MONTH)+1, rightNow.get(Calendar.YEAR));
      JSONObject allPois = (JSONObject)JSONValue.parse(poi);
      JSONArray pois = (JSONArray)allPois.get("pois");
      JSONObject obj = (JSONObject)JSONValue.parse(waitingTimesData);
      SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
      formatter.setTimeZone(getTimeZone());
      JSONArray array = (JSONArray)obj.get("AttractionInfo");
      int m = pois.size();
      int n = array.size();
      for (int i = 0; i < n; ++i) {
        JSONObject info = (JSONObject)array.get(i);
        JSONArray showTimes = (JSONArray)info.get("ShowTimes");
        if (showTimes != null) {
          int numberOfShowTimes = showTimes.size();
          if (numberOfShowTimes > 0) {
            String id = (String)info.get("Id");
            id = id.replace("\\r", "").replace("\\n", "");
            boolean found = false;
            for (int j = 0; j < m; ++j) {
              JSONObject p = (JSONObject)pois.get(j);
              String pId = (String)p.get("id");
              if (pId.equals(id)) {
                String name = (String)p.get("name");
                String attractionId = getAttractionId(name);
                if (attractionId != null) {
                  if (attractionId.length() > 0) {
                    Set<String> aIds = new HashSet<String>(2);
                    aIds.add(attractionId);
                    for (int k = 0; k < numberOfShowTimes; ++k) {
                      JSONObject showTime = (JSONObject)showTimes.get(k);
                      String showDateTime = (String)showTime.get("ShowDateTime");
                      int duration = getAttractionDuration(attractionId);
                      if (duration > 0) {
                        Date eventStartTime = formatter.parse(showDateTime, new ParsePosition(0));
                        long time = eventStartTime.getTime()+60000*duration;
                        calendarData.add(aIds, new CalendarItem(today, today, formatterHour2.format(eventStartTime), formatterHour2.format(new Date(time)), null, null, null, null, false));
                      } else WaitingTimesCrawler.trace("duration not defined for attraction " + name);
                    }
                  }
                } else WaitingTimesCrawler.trace("attraction " + name + " unknown");
                found = true;
                break;
              }
            }
            if (!found) WaitingTimesCrawler.trace("attraction ID " + id + " unknown (" + parkId + ')');
          }
        }
      }
    } else WaitingTimesCrawler.trace("content missing for https://mobile-services.efteling.com/v3/wis/");
    //System.out.println(calendarData);
    //System.exit(1);
    return true;
  }

  protected String getAttractionId(String name) {
    String attractionId = super.getAttractionId(name);
    if (attractionId != null) return attractionId;
    if (name.equals("Fairytale Tree")) return "a27";
    if (name.equals("Sprookjesboom: Er was eens...")) return "a27";
    if (name.equals("Monorail Volk van Laaf")) return "a33";
    if (name.equals("Aquanura")) return "a62";
    if (name.equals("Baron 1898")) return "a66";
    //if (name.equals("Sprookjesboom, zingen rond de paddenstoel")) return "a27";
    if (name.equals("Sprookjesboom Zingen onder de Paddenstoel")) return ""; // a27
    if (name.equals("Jokie en Jet")) return "";
    if (name.equals("jokieenjet")) return "";
    if (name.equals("Prinzessin Anura")) return "";
    if (name.equals("Efteling Theater")) return "";
    if (name.equals("Pardoes de Tovernar")) return "";
    if (name.equals("eftelingmuziekanten")) return "";
    if (name.equals("kinderspoor")) return "";
    if (name.equals("bobsingleriders")) return "";
    if (name.equals("baron1898singlerider")) return "";
    if (name.equals("sprookjessprokkelaar")) return "";
    if (name.equals("pardoesdetovernar")) return "";
    return null;
  }

  public String getWaitingTimesDataURL() {
    String url = "https://mobile-services.efteling.com/v3/wis/";
    downloadWaitingTimesDataUserAgent = "Dalvik/1.6.0 (Linux; U; Android 4.2.2; GT-P3100 Build/JDQ39)";
    downloadWaitingTimesDataProperties.put("X-Digest", getDigest(url));
    downloadWaitingTimesDataProperties.put("x-api-version", "3");
    downloadWaitingTimesDataAcceptLanguage = "de;q=1, en;q=0.9, fr;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5";
    downloadWaitingTimesDataAccept = "application/json; version=2";
    downloadWaitingTimesDataContentType = "application/json; charset=utf-8";
    return url;
  }

  private Set<String> closedAttractionIds = new HashSet<String>(10);
  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    closedAttractionIds.clear();
    Map<String, WaitingTimesItem> waitingTimes = super.refreshWaitingTimesData();
    if (waitingTimes == null) return null;
    try {
      waitingTimesData = decrypt(waitingTimesData, "1768257091023496");
      //System.out.println(waitingTimesData);
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
    JSONObject allPois = (JSONObject)JSONValue.parse(poi);
    JSONArray pois = (JSONArray)allPois.get("pois");
    JSONObject obj = (JSONObject)JSONValue.parse(waitingTimesData);
    JSONArray array = (JSONArray)obj.get("AttractionInfo");
    int m = pois.size();
    int n = array.size();
    for (int i = 0; i < n; ++i) {
      JSONObject info = (JSONObject)array.get(i);
      String waitingTime = (String)info.get("WaitingTime");
      if (waitingTime != null) {
        String id = (String)info.get("Id");
        id = id.replace("\r", "").replace("\n", "");
        boolean found = false;
        for (int j = 0; j < m; ++j) {
          JSONObject p = (JSONObject)pois.get(j);
          String pId = (String)p.get("id");
          if (pId.equals(id)) {
            String name = (String)p.get("name");
            String attractionId = getAttractionId(name);
            if (attractionId == null) {
              if (!waitingTime.equals("0")) WaitingTimesCrawler.trace("attraction " + name + " (" + waitingTime + ") unknown");
            } else if (attractionId.length() > 0) {
              WaitingTimesItem item = new WaitingTimesItem();
              item.waitTime = Integer.parseInt(waitingTime);
              waitingTimes.put(attractionId, item);
              //System.out.println(attractionId + ": " + waitingTime);
            }
            found = true;
            break;
          }
        }
        if (!found) WaitingTimesCrawler.trace("attraction ID " + id + " unknown (" + parkId + ')');
      }
    }
    array = (JSONArray)obj.get("MaintenanceInfo");
    if (array != null) {
      n = array.size();
      for (int i = 0; i < n; ++i) {
        JSONObject info = (JSONObject)array.get(i);
        String id = (String)info.get("AttractionId");
        for (int j = 0; j < m; ++j) {
          JSONObject p = (JSONObject)pois.get(j);
          String pId = (String)p.get("id");
          if (pId.equals(id)) {
            String name = (String)p.get("name");
            String attractionId = getAttractionId(name);
            if (attractionId == null) WaitingTimesCrawler.trace("attraction " + name + " (closed) unknown");
            else if (attractionId.length() > 0) closedAttractionIds.add(attractionId);
          }
        }
      }
    }
    //System.out.println(waitingTimesData);
    //System.exit(1);
    return waitingTimes;
  }

  public Set<String> closedAttractionIds() {
    return closedAttractionIds;
  }

  private String getDigest(String paramString) {
    return makeHash(paramString.substring(3 + paramString.indexOf("://"), paramString.length()));
  }

  private byte[] getKeyBytes(String paramString) throws UnsupportedEncodingException
  {
    byte[] arrayOfByte1 = new byte[16];
    byte[] arrayOfByte2 = paramString.getBytes("UTF-8");
    System.arraycopy(arrayOfByte2, 0, arrayOfByte1, 0, Math.min(arrayOfByte2.length, arrayOfByte1.length));
    return arrayOfByte1;
  }
  
  public String decrypt(String paramString1, String paramString2) throws UnsupportedEncodingException, NoSuchAlgorithmException, NoSuchPaddingException, InvalidKeyException, InvalidAlgorithmParameterException, IllegalBlockSizeException, BadPaddingException {
    byte[] arrayOfByte1 = Base64.decode(paramString1, 0);
    byte[] arrayOfByte2 = getKeyBytes(paramString2);
    return new String(decrypt(arrayOfByte1, arrayOfByte2), "UTF-8");
  }
  
  public byte[] decrypt(byte[] paramArrayOfByte1, byte[] paramArrayOfByte2) throws NoSuchAlgorithmException, NoSuchPaddingException, InvalidKeyException, InvalidAlgorithmParameterException, IllegalBlockSizeException, BadPaddingException {
    Cipher localCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
    localCipher.init(2, new SecretKeySpec(paramArrayOfByte2, "AES"), new IvParameterSpec(new byte[16]));
    return localCipher.doFinal(paramArrayOfByte1);
  }

  private String privateKey = "blblblblbla";
  private String makeHash(String paramString) {
    try {
      Mac localMac = Mac.getInstance("HmacSHA256");
      localMac.init(new SecretKeySpec(privateKey.getBytes(), "HmacSHA256"));
      byte[] arrayOfByte = localMac.doFinal(paramString.getBytes());
      StringBuilder localStringBuilder = new StringBuilder(2 * arrayOfByte.length);
      for (int i = 0; ; ++i) {
        if (i >= arrayOfByte.length) return localStringBuilder.toString();
        String str = Integer.toHexString(0xFF & arrayOfByte[i]);
        if (str.length() == 1) localStringBuilder.append('0');
        localStringBuilder.append(str);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    return "";
  }
}
