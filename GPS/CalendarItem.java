import java.text.*;
import java.util.*;

public class CalendarItem implements Comparable<CalendarItem> {
	String startDate; // dd.MM.yyyy
	String endDate;
	String startTime;
	String endTime;
  String startExtraHours;
  String endExtraHours;
  String startExtraHours2;
  String endExtraHours2;
  boolean winterData;

  public CalendarItem(String startDate, String endDate, String startTime, String endTime, String startExtraHours, String endExtraHours, String startExtraHours2, String endExtraHours2, boolean winterData) {
    this.startDate = startDate;
    this.endDate = endDate;
    this.startTime = startTime;
    this.endTime = endTime;
    this.startExtraHours = startExtraHours;
    this.endExtraHours = endExtraHours;
    this.startExtraHours2 = startExtraHours2;
    this.endExtraHours2 = endExtraHours2;
    this.winterData = winterData;
  }

  public boolean equalsTimeFrame(CalendarItem item) {
    if (startExtraHours == null) {
      if (item.startExtraHours != null) return false;
    } else if (item.startExtraHours == null) return false;
    if (startExtraHours2 == null) {
      if (item.startExtraHours2 != null) return false;
    } else if (item.startExtraHours2 == null) return false;
    return (winterData == item.winterData && startTime.equals(item.startTime) && endTime.equals(item.endTime) && (startExtraHours == null || startExtraHours.equals(item.startExtraHours) && endExtraHours.equals(item.endExtraHours)) && (startExtraHours2 == null || startExtraHours2.equals(item.startExtraHours2) && endExtraHours2.equals(item.endExtraHours2)));
  }
  
  public boolean equals(Object obj) {
    if (obj instanceof CalendarItem) {
      CalendarItem c = (CalendarItem)obj;
      return (startTime.equals(c.startTime) && endTime.equals(c.endTime) && startDate.equals(c.startDate) && endDate.equals(c.endDate));
    }
    return false;
  }

  public int compareTo(CalendarItem item) {
    if (startDate.length() != 10 || item.startDate.length() != 10) return 0;
    int c = startDate.substring(6).compareTo(item.startDate.substring(6));
    if (c != 0) return c;
    c = (10*(startDate.charAt(3)-'0')+startDate.charAt(4)-'0');
    int d = (10*(item.startDate.charAt(3)-'0')+item.startDate.charAt(4)-'0');
    if (c < d) return -1;
    if (c > d) return 1;
    c = (10*(startDate.charAt(0)-'0')+startDate.charAt(1)-'0');
    d = (10*(item.startDate.charAt(0)-'0')+item.startDate.charAt(1)-'0');
    if (c < d) return -1;
    if (c > d) return 1;
    c = startTime.compareTo(item.startTime);
    if (c != 0) return c;
    return endTime.compareTo(item.endTime);
  }

  public boolean isSameDay(CalendarItem item) {
    if (startDate.length() != 10 || item.startDate.length() != 10) return false;
    if (startDate.charAt(0) != item.startDate.charAt(0) || startDate.charAt(1) != item.startDate.charAt(1)) return false;
    if (startDate.charAt(3) != item.startDate.charAt(3) || startDate.charAt(4) != item.startDate.charAt(4)) return false;
    return (startDate.substring(6).equals(item.startDate.substring(6)));
  }

  public boolean isEndDateOneDayBefore(CalendarItem item) {
    String date = item.startDate;
    if (endDate.equals(date)) return false;
    Calendar calendar = Calendar.getInstance();
    calendar.setTime(formatterDate.parse(endDate, new ParsePosition(0)));
    calendar.set(Calendar.HOUR, 0);
    calendar.set(Calendar.MINUTE, 0);
    calendar.set(Calendar.SECOND, 1);
    calendar.set(Calendar.MILLISECOND, 0);
    String dateLower = formatterDate.format(calendar.getTime());
    calendar.add(Calendar.HOUR_OF_DAY, 25);
    String dateHigher = formatterDate.format(calendar.getTime());
    if (dateLower.length() != 10 || dateHigher.length() != 10 || date.length() != 10) return false;
    int yl = Integer.parseInt(dateLower.substring(6));
    int yh = Integer.parseInt(dateHigher.substring(6));
    int y = Integer.parseInt(date.substring(6));
    //System.out.println("startDate="+startDate+", endDate="+endDate+", dateLower="+dateLower+", dateHigher="+dateHigher+", date="+date);
    if (yl > y || yh < y) return false;
    int ml = (10*(dateLower.charAt(3)-'0')+dateLower.charAt(4)-'0');
    int mh = (10*(dateHigher.charAt(3)-'0')+dateHigher.charAt(4)-'0');
    int m = (10*(date.charAt(3)-'0')+date.charAt(4)-'0');
    //if (ml > m || mh < m) return false;
    int dl = (10*(dateLower.charAt(0)-'0')+dateLower.charAt(1)-'0');
    int dh = (10*(dateHigher.charAt(0)-'0')+dateHigher.charAt(1)-'0');
    int d = (10*(date.charAt(0)-'0')+date.charAt(1)-'0');
    return (yl == y && ml == m && dl == d || yh == y && mh == m && dh == d);
  }

  public String getTimeFrame() {
    return startTime + '-' + endTime;
  }

  public String toString() {
    if (startExtraHours != null) {
      if (startExtraHours2 != null) {
        return (winterData)? startDate + '-' + endDate + "-w;" + startTime + '-' + endTime + ';' + startExtraHours + '-' + endExtraHours + "+;" + startExtraHours2 + '-' + endExtraHours2 + '+' : startDate + '-' + endDate + ';' + startTime + '-' + endTime + ';' + startExtraHours + '-' + endExtraHours + "+;" + startExtraHours2 + '-' + endExtraHours2 + '+';
      } else {
        return (winterData)? startDate + '-' + endDate + "-w;" + startTime + '-' + endTime + ';' + startExtraHours + '-' + endExtraHours + '+' : startDate + '-' + endDate + ';' + startTime + '-' + endTime + ';' + startExtraHours + '-' + endExtraHours + '+';
      }
    }
    return (winterData)? startDate + '-' + endDate + "-w;" + startTime + '-' + endTime : startDate + '-' + endDate + ';' + startTime + '-' + endTime;
  }

  private SimpleDateFormat formatterDate = new SimpleDateFormat("dd.MM.yyyy");
}
