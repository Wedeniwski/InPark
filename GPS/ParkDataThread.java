import java.io.*;
import java.math.BigInteger;
import java.net.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.*;
import java.util.*;

public class ParkDataThread extends Thread {
  private ParkDataParser parkDataParsers[] = null;
  private Map<String, String> cachedPages = new HashMap<String, String>(200);
  private String archiveURL = null;

  public ParkDataThread(ParkDataParser[] parsers) {
    parkDataParsers = parsers;
    for (int i = 0; i < parkDataParsers.length; ++i) {
      parkDataParsers[i].cachedPages = this;
    }
  }

  public String getCachedPage(String strURL) {
    return cachedPages.get(strURL);
  }

  public void putCachedPage(String strURL, String content) {
    cachedPages.put(strURL, content);
  }

  public void clearCachedPages() {
    cachedPages.clear();
  }

  public void setArchiveURL(String archiveURL) {
    this.archiveURL = archiveURL;
  }

  public void run() {
    while (true) {
      long startTime = System.currentTimeMillis();
      for (int i = 0; i < parkDataParsers.length; ++i) {
        try {
          String parkId = parkDataParsers[i].getParkId();
          if (parkDataParsers[i].calendarRefreshNeeded()) {
            if (parkDataParsers[i].refreshCalendar()) {
              String from = parkDataParsers[i].getParkHoursFrom();
              String to = parkDataParsers[i].getParkHoursTo();
              if (from == null && to == null) {
                if (parkDataParsers[i].lastCalendarChange) trace("update calendar of park " + parkId + " for " + parkDataParsers[i].localDateAtPark() + " (closed)");
                else trace("calendar of park " + parkId + " for " + parkDataParsers[i].localDateAtPark() + " closed");
              } else trace("update calendar of park " + parkId + " for " + parkDataParsers[i].localDateAtPark() + " (open from " + from + " to " + to + ')');
            } else {
              trace("ERROR: calendar of park " + parkId + " for " + parkDataParsers[i].localDateAtPark() + " could not be parsed!");
            }
            updateWaitingTimesData(parkId);
            if (i == 0) archiveWaitingTimesData();
          }
          String t1 = parkDataParsers[i].getParkHoursFrom();
          String t2 = parkDataParsers[i].getParkHoursTo();
          if (t1 != null && t2 != null) {
            String s = parkDataParsers[i].localTimeAtPark();
            //System.out.println("s="+s+", t1="+t1+", t2="+t2+", "+parkHoursFrom[i]+", "+parkHoursTo[i]);
            if (t1.compareTo(t2) < 0 && (s.compareTo(t1) < 0 || s.compareTo(t2) > 0) || t1.compareTo(t2) >= 0 && s.compareTo(t1) < 0 && s.compareTo(t2) > 0) {
              trace("park " + parkId + " local time " + s + " open from " + t1 + " to " + t2 + " (" + parkDataParsers[i].getCurrentDate() + ')');
            } else {
              int n = submitWaitingTimes(parkId, parkDataParsers[i]);
              if (n > 0) trace(Integer.toString(n) + " waiting times submitted for park " + parkId + " (local time " + s + ')');
            }
          }
        } catch (Exception e) {
          trace("ERROR: crawling park " + parkDataParsers[i].getParkId());
          e.printStackTrace();
        }
      }
      clearCachedPages();
      Random rand = new Random();
      int randomWait = rand.nextInt(321)+180; // random seconds between 180 and 500
      startTime += randomWait*1000 - System.currentTimeMillis();
      if (startTime >= 1000) {
        try {
          Thread.sleep(startTime);
        } catch (InterruptedException ie) {
        }
      }
    }
  }

  public static String hashCode(String text) {
    try {
      MessageDigest digest = MessageDigest.getInstance("MD5");
      digest.update(text.getBytes());
      byte[] md5sum = digest.digest();
      BigInteger bigInt = new BigInteger(1, md5sum);
      String hCode = bigInt.toString(16);
      while (hCode.length() < 32) hCode = "0" + hCode;
      return hCode;
    } catch (NoSuchAlgorithmException e) {
      e.printStackTrace();
		}
    return null;
  }

  private static void connection(String strURL, int responseTimeOutSecs) {
    ByteArrayOutputStream content = new ByteArrayOutputStream(100000);
    try {
      URL url = new URL(strURL);
      HttpURLConnection connection = (HttpURLConnection)url.openConnection();
      connection.setDoInput(true);
      connection.setRequestMethod("GET");
      connection.setConnectTimeout(responseTimeOutSecs * 1000);
      connection.setReadTimeout(responseTimeOutSecs * 1000);
      int code = connection.getResponseCode();
      if (code != HttpURLConnection.HTTP_OK) {
        throw new IOException("wrong response code: " + code);
      }
      InputStream in = connection.getInputStream();
      FileUtilities.writeData(in, content, false, true);
      connection.disconnect();
    } catch (Exception ioe) {
      ioe.printStackTrace();
    }
  }

  private void archiveWaitingTimesData() {
    if (archiveURL != null) {
      trace("archive database waiting times");
      connection(archiveURL, 120);
    }
  }

  private static void updateWaitingTimesData(String parkId) {
    connection("http://www.inpark.info/data/waiting.php?pid=" + parkId, 60);
  }
  
  private final static String sourceDataPath = "http://www.inpark.info/data/";
  private Map<String, Long> lastParkDataRefresh = new HashMap<String, Long>(20);
  private int submitWaitingTimes(String parkId, ParkDataParser parkDataParser) {
    Map<String, WaitingTimesItem> waitingTimes = parkDataParser.refreshWaitingTimesData();
    if (waitingTimes == null || waitingTimes.size() == 0) {
      long currentTime = System.currentTimeMillis();
      Long timestamp = lastParkDataRefresh.get(parkId);
      if (timestamp == null || currentTime-3600000 >= timestamp.longValue()) { // only every hour
        lastParkDataRefresh.put(parkId, new Long(currentTime));
        trace("no wait time updates available for park " + parkId + " - ensure database clean up and up-to-date \"waiting.txt\"");
        updateWaitingTimesData(parkId);
      }
    }
    Map attractionIds = parkDataParser.getAttractionIds();
    Set<String> closedAttractionIds = parkDataParser.closedAttractionIds();
    if (closedAttractionIds == null || waitingTimes == null) return -1;
    int submittedWaitingTimes = 0;
    SimpleDateFormat timestampFormat = new SimpleDateFormat("yyyy-MM-dd+HH:mm:ss");
    String appVersion = "1.2020569";
    String identifier = hashCode("inpark" + parkId + "internal" + System.currentTimeMillis());
    //System.out.println(parkId);
    Set<String> allAttractionIds = new HashSet<String>(waitingTimes.keySet());
    allAttractionIds.addAll(closedAttractionIds);
    while (true) {
      String remove = null;
      Iterator<String> i = allAttractionIds.iterator();
      while (i.hasNext()) {
        String attractionId = i.next();
        if (!closedAttractionIds.contains(attractionId)) {
          WaitingTimesItem item = waitingTimes.get(attractionId);
          if (item == null || item.waitTime < 0) {
            remove = attractionId;
            break;
          }
        }
      }
      if (remove != null) allAttractionIds.remove(remove);
      else break;
    }
    Iterator<String> i = allAttractionIds.iterator();
    while (i.hasNext()) {
      String attractionId = i.next();
      boolean closed = false;
      WaitingTimesItem waitingTime = null;
      if (closedAttractionIds.contains(attractionId)) closed = true;
      else waitingTime = waitingTimes.get(attractionId);
      Map attraction = (Map)attractionIds.get(attractionId);
      if (attraction != null) {
        Boolean waiting = (Boolean)attraction.get("Warten");
        if (waiting == null || !waiting.booleanValue()) {
          if (waitingTime != null) trace("Waiting time (" + waitingTime.waitTime + ") submitted for " + attractionId + " which is not enabled for waiting time inside the plist");
          else if (!closed) trace("Waiting time submitted for " + attractionId + " which is not enabled for waiting time inside the plist");
        }
        String fastLaneId = parkDataParser.getFastLaneId();
        if (fastLaneId != null && waitingTime != null && waitingTime.fastLaneInfoAvailable) {
          Boolean fastLane = (Boolean)attraction.get(fastLaneId);
          if (fastLane == null || !fastLane.booleanValue()) trace("Fast lane informatione submitted for " + attractionId + " which is not enabled inside the plist");
        }
      }
      StringBuilder path = new StringBuilder(500);
      StringBuilder hash = new StringBuilder(200);
      hash.append(attractionId);
      path.append(sourceDataPath);
      path.append("waiting.php?pid=");
      path.append(parkId);
      path.append("&aid=");
      path.append(attractionId);
      path.append("&eid=");
      path.append(attractionId);
      path.append("&xid=");
      path.append(attractionId);
      path.append("&e=");
      timestampFormat.setTimeZone(parkDataParser.getTimeZone());
      String timestamp = timestampFormat.format(parkDataParser.getCurrentCalendar().getTime());
      path.append(timestamp);
      hash.append(timestamp.replace('+', ' '));
      hash.append(attractionId);
      hash.append(identifier);
      hash.append(attractionId);
      hash.append(appVersion);
      hash.append(parkId);
      int waitTime = (waitingTime != null)? waitingTime.waitTime : 0;
      hash.append(String.format("%.5f", ((closed)? 1 : 0) + 3.0*waitTime - 3.1415927));
      hash.append("0.00000");
      path.append("&c=");
      path.append((closed)? '1' : '0');
      path.append("&d=");
      path.append(waitTime);
      path.append("&v=");
      path.append(appVersion);
      path.append("&ela=0.0&elo=0.0&eac=0.0&uid=");
      path.append(identifier);
      if (waitingTime != null && waitingTime.fastLaneInfoAvailable) {
        path.append("&f=");
        path.append(waitingTime.fastLaneAvailable);
        hash.append(waitingTime.fastLaneAvailable);
        if (waitingTime.fastLaneAvailableTimeFrom != null) {
          path.append("&ff=");
          path.append(waitingTime.fastLaneAvailableTimeFrom);
          hash.append(waitingTime.fastLaneAvailableTimeFrom);
          if (waitingTime.fastLaneAvailableTimeTo != null) {
            path.append("&ft=");
            path.append(waitingTime.fastLaneAvailableTimeTo);
            hash.append(waitingTime.fastLaneAvailableTimeTo);
          }
        }
      }
      /*if (waitingTime != null && waitingTime.startTimes != null) {
       path.append("&t=");
       path.append(waitingTime.startTimes);
       hash.append(hashCode(waitingTime.startTimes));
       }*/
      if (i.hasNext()) { // another call will follow, then call as batch mode
        path.append("&b=1");
      }
      path.append("&h=");
      path.append(hashCode(hash.toString()));
      //System.out.println("to be hashed: " + hash.toString());
      //System.out.println(path.toString());
      
      try {
        URL url = new URL(path.toString());
        HttpURLConnection connection = (HttpURLConnection)url.openConnection();
        connection.setRequestMethod("PUT");
        final int responseTimeOutSecs = 60;
        connection.setConnectTimeout(responseTimeOutSecs * 1000);
        connection.setReadTimeout(responseTimeOutSecs * 1000);
        int code = connection.getResponseCode();
        if (code != HttpURLConnection.HTTP_OK) {
          throw new IOException("wrong response code: " + code);
        }
        connection.disconnect();
        connection = null;
        ++submittedWaitingTimes;
      } catch (MalformedURLException e) {
        trace("ERROR: invalid URL " + path);
      } catch (Exception ioe) {
        ioe.printStackTrace();
      }
    }
    return submittedWaitingTimes;
  }

  static void trace(String text) {
    WaitingTimesCrawler.trace(text, true, true);
  }
}
