import java.io.*;
import java.net.*;
import java.security.*;
import java.security.cert.*;
import java.text.*;
import java.util.*;
import java.util.zip.*;
import javax.net.ssl.*;

public abstract class ParkDataParser {
  protected String parkId;
  private String timeZoneID;
  protected Map attractionIds;
  protected String fastLaneId;
  private String lastDateOfCalendarParse;
  private String lastTimeOfCalendarParse;
  private String timeOfSecondTryOfCalendarParse;
  private String timeOfThirdTryOfCalendarParse;
  public boolean lastCalendarChange;
  protected CalendarData calendarData;
  protected String waitingTimesData;
  protected int downloadPageResponseCode = 0;
  protected String downloadWaitingTimesDataCharsetName = "UTF-8";
  protected String downloadWaitingTimesDataPOST = null;
  protected String downloadWaitingTimesDataUserAgent = null;
  protected String downloadWaitingTimesDataContentType = null;
  protected Map<String, String> downloadWaitingTimesDataProperties = new HashMap<String, String>(10);
  protected String downloadWaitingTimesDataAccept = null;
  protected String downloadWaitingTimesDataAcceptLanguage = null;
  protected boolean downloadWaitingTimesDataCompressed = false;
  protected SimpleDateFormat formatterHour = new SimpleDateFormat("h:mma");
  protected SimpleDateFormat formatterHourOnly = new SimpleDateFormat("hha");
  protected SimpleDateFormat formatterHour2 = new SimpleDateFormat("HH:mm");
  protected SimpleDateFormat formatterHour3 = new SimpleDateFormat("h:mm a");
  protected SimpleDateFormat formatterHour4 = new SimpleDateFormat("HHmm");
  protected SimpleDateFormat formatterDate = new SimpleDateFormat("dd.MM.yyyy");
  protected SimpleDateFormat formatterDateSource = new SimpleDateFormat("yyyyMMdd");
  protected SimpleDateFormat formatterDateSource2 = new SimpleDateFormat("dd/MM/yy");
  protected SimpleDateFormat formatterMonthDay = new SimpleDateFormat("MM/dd");
  protected SimpleDateFormat formatterMonthDayYear = new SimpleDateFormat("MM/dd/yyyy");
  protected SimpleDateFormat formatterYearMonth = new SimpleDateFormat("yyyyMM");
  protected SimpleDateFormat formatterYearMonthDay = new SimpleDateFormat("yyyy-MM-dd");
  ParkDataThread cachedPages = null;

  public ParkDataParser(String parkId, String timeZoneID) {
    this.parkId = parkId;
    this.timeZoneID = timeZoneID;
    calendarData = null;
    lastDateOfCalendarParse = null;
    lastTimeOfCalendarParse = null;
    timeOfSecondTryOfCalendarParse = null;
    timeOfThirdTryOfCalendarParse = null;
    lastCalendarChange = false;
    TimeZone timeZone = TimeZone.getTimeZone(timeZoneID);
    formatterHour.setTimeZone(timeZone);
    formatterHourOnly.setTimeZone(timeZone);
    formatterHour2.setTimeZone(timeZone);
    formatterHour3.setTimeZone(timeZone);
    formatterHour4.setTimeZone(timeZone);
    formatterDate.setTimeZone(timeZone);
    formatterDateSource.setTimeZone(timeZone);
    formatterDateSource2.setTimeZone(timeZone);
    formatterMonthDay.setTimeZone(timeZone);
    formatterMonthDayYear.setTimeZone(timeZone);
    formatterYearMonth.setTimeZone(timeZone);
    formatterYearMonthDay.setTimeZone(timeZone);
    try {
      Map plist = PList.readPListFile("../data/" + parkId + '/' + parkId + ".plist");
      if (plist == null) System.out.println("Missing plist for " + parkId);
      else {
        attractionIds = (Map)plist.get("IDs");
        if (attractionIds == null) System.out.println("Missing IDs entry inside plist");
        fastLaneId = (String)plist.get("Fast_lane");
      }
    } catch (IOException ioe) {
      ioe.printStackTrace();
    }
  }

  public String getParkId() {
    return parkId;
  }

  public String parserIdentifier() {
    return getClass().getName();
  }

  public TimeZone getTimeZone() {
    return TimeZone.getTimeZone(timeZoneID);
  }

  public Map getAttractionIds() {
    return attractionIds;
  }

  String removeSpecialCharacters(String name) {
    int n = name.length();
    if (n > 1) {
      StringBuilder sb = new StringBuilder(n);
      for (int i = 0; i < n; ++i) {
        char ch = name.charAt(i);
        if (Character.getType(ch) == Character.SPACE_SEPARATOR) {
          if (i+1 < n) sb.append(' ');
        } else {
          sb.append(ch);
        }
      }
      name = sb.toString();
    }
    return name;
  }

  protected String getAttractionId(String name) {
    if (attractionIds != null) {
      Iterator<String> keys = attractionIds.keySet().iterator();
      while (keys.hasNext()) {
        String attractionId = keys.next();
        if (attractionId == null) break;
        Map attraction = (Map)attractionIds.get(attractionId);
        Object obj = attraction.get("Name");
        if (obj instanceof Map) obj = ((Map)obj).get("en");
        String attractionName = (String)obj;
        if (attractionName != null && attractionName.equals(name)) return attractionId;
      }
    }
    return null;
  }

  protected int getAttractionDuration(String attractionId) {
    if (attractionIds != null) {
      Map attraction = (Map)attractionIds.get(attractionId);
      if (attraction != null) {
        Integer n = (Integer)attraction.get("Attraktionsdauer");
        return n.intValue();
      }
    }
    return 0;
  }

  protected boolean isTrain(String attractionId) {
    if (attractionIds != null) {
      Map attraction = (Map)attractionIds.get(attractionId);
      Object obj = attraction.get("nächste Station");
      return (obj != null);
    }
    return false;
  }
  
  public String getFastLaneId() {
    return fastLaneId;
  }

  public Set<String> getParkEntrances() {
    Set<String> parkEntrances = new HashSet<String>(3);
    Iterator i = attractionIds.keySet().iterator();
    while (i.hasNext()) {
      String attractionId = (String)i.next();
      Map attraction = (Map)attractionIds.get(attractionId);
      String s = (String)attraction.get("Type");
      if (s.equals("ENTRANCE")) parkEntrances.add(attractionId);
      else if (s.equals("EXIT")) parkEntrances.add(attractionId);
    }
    return parkEntrances;
  }

  private boolean timeDifferenceBetweenLocalAndServer = true;
  private long lastTimeServerChecked = 0;
  public Calendar rightNow() {
    Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone(timeZoneID));
    long now = System.currentTimeMillis();
    if (timeDifferenceBetweenLocalAndServer || now-lastTimeServerChecked >= 3600000) {
      SntpClient client = new SntpClient();
      if (client.requestTime("time.nist.gov", 3000, false) || client.requestTime("wolfnisttime.com", 3000, false) || client.requestTime("time-c.nist.gov", 3000, true)) {
        now = client.getNtpTime();
        long local = System.currentTimeMillis();
        lastTimeServerChecked = local;
        timeDifferenceBetweenLocalAndServer = (local-now > 30000);
        if (timeDifferenceBetweenLocalAndServer) WaitingTimesCrawler.trace("THERE EXIST A MAJOR TIME DIFFERENCE BETWEEN INTERNET TIME SERVERS AND LOCAL TIME!");
      }
    }
    calendar.setTimeInMillis(now);
    return calendar;
  }

  public String localTimeAtPark() {
    Calendar rightNow = rightNow();
    return String.format("%02d:%02d", rightNow.get(Calendar.HOUR_OF_DAY), rightNow.get(Calendar.MINUTE));
  }
  
  public String localDateAtPark() {
    Calendar rightNow = rightNow();
    return String.format("%04d-%02d-%02d", rightNow.get(Calendar.YEAR), rightNow.get(Calendar.MONTH)+1, rightNow.get(Calendar.DAY_OF_MONTH));
  }
  
  public boolean calendarRefreshNeeded() {
    if (calendarData == null || lastDateOfCalendarParse == null) return true;
    if (!lastDateOfCalendarParse.equals(getCurrentDate())) {
      timeOfSecondTryOfCalendarParse = null;
      timeOfThirdTryOfCalendarParse = null;
      String from = getParkHoursFrom();
      if (from == null) return true;
      try {
        return (Math.abs(formatterHour2.parse(from).getTime() - formatterHour2.parse(localTimeAtPark()).getTime()) < 3600000L);
      } catch (ParseException e) {
        e.printStackTrace();
        return true;
      }
    } else if (lastTimeOfCalendarParse != null) {
      String from = getParkHoursFrom();
      if (from == null) return false;
      try {
        long df = formatterHour2.parse(from).getTime();
        long dl = formatterHour2.parse(localTimeAtPark()).getTime();
        if (timeOfSecondTryOfCalendarParse == null && (!lastCalendarChange || checkCalendarUpdatesAfterOpening()) && df <= dl) {
          timeOfSecondTryOfCalendarParse = localTimeAtPark();
          return true;
        }
        if (timeOfSecondTryOfCalendarParse != null && timeOfThirdTryOfCalendarParse == null && (!lastCalendarChange || checkCalendarUpdatesAfterOpening())) {
          String from2 = getParkHoursFromWithoutExtra();
          if (from2 != null && !from2.equals(from)) {
            long df2 = formatterHour2.parse(from2).getTime();
            if (df2 <= dl) {
              timeOfThirdTryOfCalendarParse = localTimeAtPark();
              return true;
            }
          }
        }
        return (Math.abs(df - formatterHour2.parse(lastTimeOfCalendarParse).getTime()) > 3600000L && Math.abs(df-dl) < 3600000L);
      } catch (ParseException e) {
        e.printStackTrace();
        return false;
      }
    }
    return false;
  }

  public void requestRefreshCalendar() {
    lastDateOfCalendarParse = null;
    lastTimeOfCalendarParse = null;
  }

  public boolean isCalendarPageValid(String calendarPage) {
    return true;
  }

  public boolean checkCalendarUpdatesAfterOpening() {
    return false;
  }

  public abstract String firstCalendarPage();
  public abstract String nextCalendarPage(int numberOfDownloadedPages, String contentOfPreviousPage);
  protected abstract boolean updateCalendarData(int pageNumber, String calendarPage);

  public boolean refreshCalendar() {
    lastDateOfCalendarParse = null;
    lastTimeOfCalendarParse = null;
    CalendarData oldCalendarData = calendarData;
    calendarData = new CalendarData(parkId);
    int numberOfDownloadedPages = 0;
    String onlineContent = downloadPageHasContent("http://www.inpark.info/data/" + parkId + "/calendar.txt", "UTF-8");
    int pageNumber = 0;
    String previousUrl = null;
    String url = firstCalendarPage();
    if (url == null) calendarData = null;
    while (url != null) {
      //System.out.println("url of calendar page=" + url);
      String pageContent = null;
      for (int i = 0; i < 10; ++i) {
        pageContent = downloadPage(url, "UTF-8");
        if (pageContent != null) {
          if (!isCalendarPageValid(pageContent)) {
            if (calendarData.isEmpty()) {
              if (oldCalendarData == null) {
                WaitingTimesCrawler.trace("Using online calendar because of error parsing calendar data for " + parkId);
                calendarData.parseData(onlineContent);
                if (calendarData.isEmpty()) calendarData = null;
                else return true;
              } else calendarData = oldCalendarData;
              return false;
            }
            url = null;
            break;
          }
          ++pageNumber;
          boolean updateDone = false;
          for (int j = 0; j < 3; ++j) {
            try {
              if (updateCalendarData(pageNumber, pageContent)) {
                updateDone = true;
                break;
              }
            } catch (NullPointerException npe) {
              npe.printStackTrace();
              WaitingTimesCrawler.trace("Retry to update calendar data for " + parkId);
            }
          }
          if (updateDone) break;
          if (oldCalendarData == null) {
            WaitingTimesCrawler.trace("Using online calendar because of error parsing calendar data for " + parkId);
            calendarData.parseData(onlineContent);
            if (calendarData.isEmpty()) calendarData = null;
            else return true;
          } else calendarData = oldCalendarData;
          return false;
        }
        if (i == 9) {
          if (oldCalendarData == null) {
            WaitingTimesCrawler.trace("Using online calendar because of error parsing calendar data for " + parkId);
            calendarData.parseData(onlineContent);
            if (calendarData.isEmpty()) calendarData = null;
            else return true;
          } else calendarData = oldCalendarData;
          return false;
        }
        try {
          Thread.sleep((i+1)*500);
        } catch (InterruptedException ie) {
        }
      }
      if (url == null) break;
      if (++numberOfDownloadedPages >= 150) {
        WaitingTimesCrawler.trace("More than " + numberOfDownloadedPages + " calender pages are requested for " + parkId);
        if (previousUrl != null && previousUrl.equals(url)) WaitingTimesCrawler.trace("Multiple downloads of same calendar URL " + url + " are requested for " + parkId);
        if (oldCalendarData == null) {
          WaitingTimesCrawler.trace("Using online calendar because of error parsing calendar data for " + parkId);
          calendarData.parseData(onlineContent);
          if (calendarData.isEmpty()) calendarData = null;
          else return true;
        } else calendarData = oldCalendarData;
        return false;
      }
      previousUrl = url;
      url = nextCalendarPage(numberOfDownloadedPages, pageContent);
    }
    if (calendarData == null) {
      WaitingTimesCrawler.trace("Error parsing calendar data for " + parkId);
      if (oldCalendarData == null && onlineContent != null) {
        WaitingTimesCrawler.trace("Using online calendar because of error parsing calendar data for " + parkId);
        calendarData = new CalendarData(parkId);
        calendarData.parseData(onlineContent);
        if (calendarData.isEmpty()) calendarData = null;
        else return true;
      } else calendarData = oldCalendarData;
      return false;
    }
    String result = calendarData.toString();
    //System.out.println(result);
    if (result == null) {
      WaitingTimesCrawler.trace("Error formatting calendar data for " + parkId);
      if (oldCalendarData == null) {
        WaitingTimesCrawler.trace("Using online calendar because of error parsing calendar data for " + parkId);
        calendarData.parseData(onlineContent);
        if (calendarData.isEmpty()) calendarData = null;
        else return true;
      } else calendarData = oldCalendarData;
      return false;
    }
    if (onlineContent == null || !onlineContent.equals(result)) {
      int error = 0;
      FTP ftp = new FTP();
      do {
        try {
          ftp.connect(FTPCredentials.connect);
          ftp.login(FTPCredentials.user, FTPCredentials.password);
          ftp.cd(FTPCredentials.path);
          ftp.setMode(FTP.MODE_BINARY);
          ftp.cd("data");
          ftp.cd(parkId);
          ByteArrayInputStream calendarUncompressed = new ByteArrayInputStream(result.toString().getBytes());
          ByteArrayOutputStream calendarCompressed = new ByteArrayOutputStream(100000);
          CreateImageIndex.bzip2CompressData(calendarUncompressed, calendarCompressed);
          calendarCompressed.close();
          calendarUncompressed.reset();
          WaitingTimesCrawler.trace("Upload calendar for " + parkId);
          ftp.put(calendarUncompressed, "calendar2.txt", FTP.MODE_BINARY);
          try {
            ftp.deleteFile("calendar.txt");
          } catch (IOException e) {}
          ftp.rename("calendar2.txt", "calendar.txt");
          ftp.put(new ByteArrayInputStream(calendarCompressed.toByteArray()), "calendar2.txt.bz2", FTP.MODE_BINARY);
          try {
            ftp.deleteFile("calendar.txt.bz2");
          } catch (IOException e) {}
          ftp.rename("calendar2.txt.bz2", "calendar.txt.bz2");
          WaitingTimesCrawler.trace("Calendar activated");
          error = 0;
        } catch (IOException ioe) {
          WaitingTimesCrawler.trace("Error uploading calendar for " + parkId + ". Retry uploading this package.");
          ioe.printStackTrace();
          try {
            Thread.sleep(500);
          } catch (InterruptedException ie) {
          }
          ftp.disconnect();
          ++error;
        }
      } while (error > 0);
      lastCalendarChange = true;
    } else {
      WaitingTimesCrawler.trace("No calendar data changes for " + parkId);
      lastCalendarChange = false;
    }
    lastDateOfCalendarParse = getCurrentDate();
    lastTimeOfCalendarParse = localTimeAtPark();
    return true;
  }

  public Calendar getCurrentCalendar() {
    return Calendar.getInstance(TimeZone.getTimeZone(timeZoneID));
  }

  public String getCurrentDate() {
    Calendar rightNow = getCurrentCalendar();
    return String.format("%02d.%02d.%04d", rightNow.get(Calendar.DAY_OF_MONTH), rightNow.get(Calendar.MONTH)+1, rightNow.get(Calendar.YEAR));
  }

  public String getParkHoursFrom() {
    if (calendarData == null) return null;
    List<CalendarItem> items = calendarData.getCalendarItemsForDate(getParkEntrances(), getCurrentDate());
    if (items == null || items.size() == 0) return null;
    CalendarItem item = items.get(0);
    if (item.startExtraHours != null && item.endExtraHours.equals(item.startTime)) return item.startExtraHours;
    return (item.startExtraHours2 != null && item.endExtraHours2.equals(item.startTime))? item.startExtraHours2 : item.startTime;
  }

  public String getParkHoursFromWithoutExtra() {
    if (calendarData == null) return null;
    List<CalendarItem> items = calendarData.getCalendarItemsForDate(getParkEntrances(), getCurrentDate());
    if (items == null || items.size() == 0) return null;
    CalendarItem item = items.get(0);
    return item.startTime;
  }

  public String getParkHoursTo() {
    if (calendarData == null) return null;
    List<CalendarItem> items = calendarData.getCalendarItemsForDate(getParkEntrances(), getCurrentDate());
    if (items == null || items.size() == 0) return null;
    CalendarItem item = items.get(0);
    if (item.startExtraHours2 != null && item.startExtraHours2.equals(item.endTime)) return item.endExtraHours2;
    return (item.startExtraHours != null && item.startExtraHours.equals(item.endTime))? item.endExtraHours : item.endTime;
  }

  public abstract String getWaitingTimesDataURL();
  public void downloadError(String strURL, int errorResponseCode) {
  }

  public Map<String, WaitingTimesItem> refreshWaitingTimesData() {
    String waitingTimesDataURL = getWaitingTimesDataURL();
    if (waitingTimesDataURL == null) return null;
    waitingTimesData = null;
    for (int i = 0; i < 10; ++i) {
      waitingTimesData = downloadPage(waitingTimesDataURL, downloadWaitingTimesDataCharsetName);
      if (waitingTimesData != null) break;
      try {
        Thread.sleep(5000);
      } catch (InterruptedException ie) {
      }
    }
    return new HashMap<String, WaitingTimesItem>(50);
  }

  public static void disableCertificateValidation() {
    // Create a trust manager that does not validate certificate chains
    TrustManager[] trustAllCerts = new TrustManager[] {
      new X509TrustManager() {
        public X509Certificate[] getAcceptedIssuers() {
          return new X509Certificate[0];
        }
        public void checkClientTrusted(X509Certificate[] certs, String authType) {}
        public void checkServerTrusted(X509Certificate[] certs, String authType) {}
      }};
    // Ignore differences between given hostname and certificate hostname
    HostnameVerifier hv = new HostnameVerifier() {
      public boolean verify(String hostname, SSLSession session) { return true; }
    };
    // Install the all-trusting trust manager
    try {
      SSLContext sc = SSLContext.getInstance("SSL");
      sc.init(null, trustAllCerts, new SecureRandom());
      HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
      HttpsURLConnection.setDefaultHostnameVerifier(hv);
    } catch (Exception e) {}
  }
  
  public abstract Set<String> closedAttractionIds();

  String downloadPage(String strURL, String charsetName) {
    downloadPageResponseCode = 0;
    if (strURL == null) return null;
    if (downloadWaitingTimesDataPOST == null && cachedPages != null) {
      String s = cachedPages.getCachedPage(strURL);
      if (s != null) return s;
    }
    //WaitingTimesCrawler.trace("start download of calendar page=" + strURL);
    try {
      StringWriter writer = new StringWriter(100000);
      HttpURLConnection connection = null;
      while (true) {
        URL url = new URL(strURL);
        connection = (HttpURLConnection)url.openConnection();
        connection.setInstanceFollowRedirects(false);
        connection.setDoInput(true);
        if (downloadWaitingTimesDataUserAgent != null) connection.setRequestProperty("User-Agent", downloadWaitingTimesDataUserAgent);
        if (downloadWaitingTimesDataProperties.size() > 0) {
          Iterator<String> i = downloadWaitingTimesDataProperties.keySet().iterator();
          while (i.hasNext()) {
            String property = i.next();
            connection.setRequestProperty(property, downloadWaitingTimesDataProperties.get(property));
          }
        }
        if (downloadWaitingTimesDataAccept != null) connection.setRequestProperty("Accept", downloadWaitingTimesDataAccept);
        if (downloadWaitingTimesDataAcceptLanguage != null) connection.setRequestProperty("Accept-Language", downloadWaitingTimesDataAcceptLanguage);
        if (downloadWaitingTimesDataPOST == null) {
          connection.setRequestMethod("GET");
          if (downloadWaitingTimesDataContentType != null) connection.setRequestProperty("Content-Type", downloadWaitingTimesDataContentType);
        } else {
          connection.setRequestMethod("POST");
          connection.setRequestProperty("Content-Length", Integer.toString(downloadWaitingTimesDataPOST.length()));
          if (downloadWaitingTimesDataContentType == null) connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded;charset=" +  charsetName);
          else connection.setRequestProperty("Content-Type", downloadWaitingTimesDataContentType);
          if (downloadWaitingTimesDataCompressed) connection.setRequestProperty("Accept-Encoding", "gzip, deflate");
          connection.setRequestProperty("Connection", "keep-alive");
          connection.setRequestProperty("Pragma", "no-cache");
          if (downloadWaitingTimesDataAccept == null) connection.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
          if (downloadWaitingTimesDataAcceptLanguage == null) connection.setRequestProperty("Accept-Language", "en-us");
          connection.setDoOutput(true);
          DataOutputStream out = new DataOutputStream(connection.getOutputStream());
          out.writeBytes(downloadWaitingTimesDataPOST);
          out.flush();
        }
        //connection.setAllowUserInteraction(false);
        final int responseTimeOutSecs = 60;
        connection.setConnectTimeout(responseTimeOutSecs * 1000);
        connection.setReadTimeout(responseTimeOutSecs * 1000);
        downloadPageResponseCode = connection.getResponseCode();
        if (downloadPageResponseCode == HttpURLConnection.HTTP_MOVED_TEMP || downloadPageResponseCode == HttpURLConnection.HTTP_MOVED_PERM || downloadPageResponseCode == HttpURLConnection.HTTP_SEE_OTHER) {
          strURL = connection.getHeaderField("location");
          WaitingTimesCrawler.trace("redirect to location: " + strURL);
        } else  if (downloadPageResponseCode != HttpURLConnection.HTTP_OK) {
          WaitingTimesCrawler.trace("wrong response code: " + downloadPageResponseCode + " for URL " + strURL);
          downloadError(strURL , downloadPageResponseCode);
          connection.disconnect();
          downloadWaitingTimesDataProperties.clear();
          return null;
        } else break;
        connection.disconnect();
      }
      //WaitingTimesCrawler.trace("response code received");
      InputStream in = connection.getInputStream();
      if (downloadWaitingTimesDataCompressed) {
        ZipInputStream zip = new ZipInputStream(in);
        zip.getNextEntry();
        in = zip;
      }
      InputStreamReader reader = new InputStreamReader(in, charsetName);
      final int maxPageSize = 5000000;
      //WaitingTimesCrawler.trace("transfer data");
      int pageSize = FileUtilities.writeData(reader, writer, true, true, maxPageSize);
      downloadWaitingTimesDataProperties.clear();
      if (pageSize >= maxPageSize) {
        WaitingTimesCrawler.trace("content of page at " + strURL + " is larger than " + maxPageSize + " bytes");
        return null;
      }
      connection.disconnect();
      //WaitingTimesCrawler.trace("page downloaded");
      connection = null;
      String s = writer.toString();
      if (downloadWaitingTimesDataPOST == null && cachedPages != null && s != null) cachedPages.putCachedPage(strURL, s);
      return s;
    } catch (MalformedURLException me) {
      WaitingTimesCrawler.trace("ERROR: invalid URL " + strURL);
    } catch (IOException ioe) {
      WaitingTimesCrawler.trace("Download exception for " + parkId + ": " + ioe.getMessage());
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  String downloadPageHasContent(String strURL, String charsetName) {
    return downloadPageHasContent(strURL, charsetName, 10);
  }

  String downloadPageHasContent(String strURL, String charsetName, int maxRetry) {
    String pageContent = null;
    for (int i = 0; i < maxRetry; ++i) {
      pageContent = downloadPage(strURL, charsetName);
      if (pageContent != null) return pageContent;
      if ((downloadPageResponseCode == 404 || downloadPageResponseCode == 503) && i == 5) return null;
      System.out.println("Retry URL " + strURL);
      try {
        Thread.sleep((downloadPageResponseCode == 503)? 10000 : 1000);
      } catch (InterruptedException ie) {
      }
    }
    return null;
  }

  protected void setSSLContext() {
    // Create a trust manager that does not validate certificate chains
    try {
      final TrustManager[] trustAllCerts = new TrustManager[] { new X509TrustManager() {
        public void checkClientTrusted(final X509Certificate[] chain, final String authType) {
        }
        public void checkServerTrusted(final X509Certificate[] chain, final String authType) {
        }
        public X509Certificate[] getAcceptedIssuers() {
          return null;
        }
      } };
      final SSLContext sslContext = SSLContext.getInstance("SSL");
      sslContext.init(null, trustAllCerts, new java.security.SecureRandom());
      HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.getSocketFactory());
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  
  public static String encodeURLComponent(String s) {
    if (s == null) return "";
    int l = s.length();
    StringBuilder sb = new StringBuilder(l);
    try {
      for (int i = 0; i < l; ++i) {
        final char c = s.charAt(i);
        if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || ((c >= '0') && (c <= '9')) || (c == '-') ||  (c == '.')  || (c == '_') || (c == '~')) {
          sb.append(c);
        } else {
          final byte[] bytes = Character.toString(c).getBytes("UTF-8");
          for (byte b : bytes) {
            sb.append('%');
            int upper = (((int) b) >> 4) & 0xf;
            sb.append(Integer.toHexString(upper).toUpperCase(Locale.US));
            int lower = ((int) b) & 0xf;
            sb.append(Integer.toHexString(lower).toUpperCase(Locale.US));
          }
        }
      }
      return sb.toString();
    } catch (UnsupportedEncodingException uee) {
      throw new RuntimeException("UTF-8 unsupported!?", uee);
    }
  }

  /**
   *  Replaces indicated characters with other characters.
   *  @param text string where characters should be replaced
   *  @param oldCharacters the character to be replaced by <code>newCharacters</code>.
   *  @param newCharacters the character replacing <code>oldCharacters</code>.
   *  @return replaced string.
   **/
  public static String replace(String text, String oldCharacters, String newCharacters) {
    final int l = oldCharacters.length();
    if (l > 0) {
      StringBuilder buffer = new StringBuilder(Math.max(10, text.length()+2*(newCharacters.length()-l)));
      int i = 0;
      for (int j = 0;; i = j+l) {
        j = text.indexOf(oldCharacters, i);
        if (j == -1) {
          break;
        }
        buffer.append(text.substring(i, j));
        buffer.append(newCharacters);
      }
      buffer.append(text.substring(i));
      text = buffer.toString();
    }
    return text;
  }
}
