import java.util.*;

public class CalendarData {
  private String parkId;
  private Map<Set<String>, List<CalendarItem> > openings;

  public CalendarData(String parkId) {
    this.parkId = parkId;
    openings = new HashMap<Set<String>, List<CalendarItem> >(10);
  }

  private void consolidate(Set<String> attractionIds) {
    List<CalendarItem> cl1 = new ArrayList<CalendarItem>(5);
    List<CalendarItem> items = openings.get(attractionIds);
    int i = 0;
    while (i+1 < items.size()) {
      CalendarItem c1 = items.get(i);
      CalendarItem c2 = items.get(i+1);
      if (c1.isSameDay(c2) && i+2 < items.size()) {
        int j = i+1;
        cl1.clear();
        cl1.add(c1);
        do {
          c1 = c2;
          cl1.add(c2);
          c2 = items.get(++j);
        } while (c1.isSameDay(c2) && j+1 < items.size());
        //if (attractionIds.contains("ch03")) System.out.println("j="+j+", items.size()="+items.size()+", before:"+c1.isEndDateOneDayBefore(c2)+", equals:"+c2.equalsTimeFrame(cl1.get(0))+", c1="+c1+", c2="+c2+", cl1="+cl1);
        if (j+1 < items.size() && c1.isEndDateOneDayBefore(c2) && c2.equalsTimeFrame(cl1.get(0))) {
          c1 = c2;
          int k = 1;
          while (j+1 < items.size() && k < cl1.size()) {
            c2 = items.get(++j);
            if (!c1.isSameDay(c2) || !c2.equalsTimeFrame(cl1.get(k))) break;
            ++k;
          }
          //if (attractionIds.contains("ch03")) System.out.println("k="+k+", j="+j+", cl1="+cl1);
          if (k == cl1.size()) {
            while (--k >= 0) {
              c1 = cl1.get(k);
              items.set(i+k, new CalendarItem(c1.startDate, c2.endDate, c1.startTime, c1.endTime, c1.startExtraHours, c1.endExtraHours, c1.startExtraHours2, c1.endExtraHours2, c1.winterData));
              items.remove(j);
              --j;
            }
          } else i = j;
        } else i = j;
      } else if (c1.equalsTimeFrame(c2) && c1.isEndDateOneDayBefore(c2)) {
        items.set(i, new CalendarItem(c1.startDate, c2.endDate, c1.startTime, c1.endTime, c1.startExtraHours, c1.endExtraHours, c1.startExtraHours2, c1.endExtraHours2, c1.winterData));
        items.remove(i+1);
      } else ++i;
    }
  }

  private void parseLine(String line, String attractionIds) {
    // 09.04.2011-06.11.2011;13:00-13:35;15:45-16:20;17:30-18:05
    StringTokenizer aId = new StringTokenizer(attractionIds, ",");
    Set<String> aIds = new HashSet<String>(2*aId.countTokens());
    while (aId.hasMoreTokens()) aIds.add(aId.nextToken());
    StringTokenizer dates = new StringTokenizer(line, ";");
    if (dates.countTokens() > 0) {
      String date = dates.nextToken();
      StringTokenizer startEndDate = new StringTokenizer(date, "-");
      if (startEndDate.countTokens() >= 2) {
        String startDate = startEndDate.nextToken();
        String endDate = startEndDate.nextToken();
        if (startDate != null && endDate != null) {
          boolean winterData = (startEndDate.hasMoreTokens())? startEndDate.nextToken().equals("w") : false;
          String startTime = null;
          String endTime = null;
          String startExtraHours = null;
          String endExtraHours = null;
          String startExtraHours2 = null;
          String endExtraHours2 = null;
          while (dates.hasMoreTokens()) {
            StringTokenizer startEndTime = new StringTokenizer(dates.nextToken(), "-");
            if (startEndTime.countTokens() == 2) {
              String sTime = startEndTime.nextToken();
              String eTime = startEndTime.nextToken();
              boolean extraHours = (eTime.endsWith("+"));
              if (extraHours) {
                eTime = eTime.substring(0, eTime.length()-1);
                if (startExtraHours != null) {
                  startExtraHours2 = sTime;
                  endExtraHours2 = eTime;
                } else {
                  startExtraHours = sTime;
                  endExtraHours = eTime;
                }
              } else {
                if (startTime != null) {
                  CalendarItem item = new CalendarItem(startDate, endDate, startTime, endTime, startExtraHours, endExtraHours, startExtraHours2, endExtraHours2, winterData);
                  add(aIds, item);
                  startTime = null;
                  endTime = null;
                  startExtraHours = null;
                  endExtraHours = null;
                  startExtraHours2 = null;
                  endExtraHours2 = null;
                } else {
                  startTime = sTime;
                  endTime = eTime;
                }
              }
            }
          }
          CalendarItem item = new CalendarItem(startDate, endDate, startTime, endTime, startExtraHours, endExtraHours, startExtraHours2, endExtraHours2, winterData);
          add(aIds, item);
        }
      }
    }
  }
  
  public boolean isEmpty() {
    return (openings == null || openings.isEmpty());
  }

  public void parseData(String data) {
    openings.clear();
    StringTokenizer lines = new StringTokenizer(data, "\n");
    String attractionIds = null;
    if (lines.hasMoreTokens()) lines.nextToken();
    while (lines.hasMoreTokens()) {
      String line = lines.nextToken();
      if (line.length() > 0) {
        if (line.endsWith(":")) attractionIds = line.substring(0, line.length()-1);
        else if (attractionIds != null) parseLine(line, attractionIds);
      }
    }
  }

  public List<CalendarItem> get(Set<String> attractionIds) {
    return openings.get(attractionIds);
  }

  public void add(Set<String> attractionIds, CalendarItem item) {
    List<CalendarItem> items = openings.get(attractionIds);
    if (items == null) {
      items = new ArrayList<CalendarItem>(20);
      items.add(item);
      openings.put(attractionIds, items);
      return;
    }
    int i = 0;
    int l = items.size();
    while (i < l && items.get(i).compareTo(item) < 0) ++i;
    items.add(i, item);
    consolidate(attractionIds);
  }

  // all calendarItems are of same day
  public void add(Set<String> attractionIds, Collection<CalendarItem> calendarItems) {
    Iterator<CalendarItem> iter = calendarItems.iterator();
    if (!iter.hasNext()) return;
    CalendarItem firstItem = iter.next();
    if (!iter.hasNext()) {
      add(attractionIds, firstItem);
      return;
    }
    List<CalendarItem> items = openings.get(attractionIds);
    if (items == null) {
      items = new ArrayList<CalendarItem>(20);
      for (CalendarItem item : calendarItems) items.add(item);
      openings.put(attractionIds, items);
      return;
    }
    int i = 0;
    int l = items.size();
    while (i < l && items.get(i).compareTo(firstItem) < 0) ++i;
    for (CalendarItem item : calendarItems) {
      while (i > 0 && item.isSameDay(items.get(i-1)) && item.compareTo(items.get(i-1)) < 0) --i; // same date same but earlier time
      while (i < l && item.isSameDay(items.get(i)) && item.compareTo(items.get(i)) > 0) ++i; // same date same but later time
      items.add(i, item);
      ++l;
    }
    consolidate(attractionIds);
  }
  
  public List<CalendarItem> getCalendarItemsForDate(Set<String> attractionIds, String date) {
    if (date.length() != 10) return null;
    int year = Integer.parseInt(date.substring(6));
    int month = (10*(date.charAt(3)-'0')+date.charAt(4)-'0');
    int day = (10*(date.charAt(0)-'0')+date.charAt(1)-'0');
    List<CalendarItem> list = openings.get(attractionIds);
    if (list != null) {
      List<CalendarItem> items = new ArrayList<CalendarItem>(5);
      for (CalendarItem item : list) {
        int year2 = Integer.parseInt(item.startDate.substring(6));
        int month2 = (10*(item.startDate.charAt(3)-'0')+item.startDate.charAt(4)-'0');
        int day2 = (10*(item.startDate.charAt(0)-'0')+item.startDate.charAt(1)-'0');
        if (year > year2 || (year == year2 && (month > month2 || (month == month2 && day >= day2)))) {
          year2 = Integer.parseInt(item.endDate.substring(6));
          month2 = (10*(item.endDate.charAt(3)-'0')+item.endDate.charAt(4)-'0');
          day2 = (10*(item.endDate.charAt(0)-'0')+item.endDate.charAt(1)-'0');
          //System.out.println("date:"+date+", day="+day+", month="+month+", year="+year+", day2="+day2+", month2="+month2+", year2="+year2);
          if (year < year2 || (year == year2 && (month < month2 || (month == month2 && day <= day2)))) items.add(item);
        }
      }
      return items;
    }
    return null;
  }

  public String toString() {
    StringBuilder sb = new StringBuilder(400);
    sb.append(parkId);
    sb.append("\n\n");
    Iterator<Set<String> > i = openings.keySet().iterator();
    while (i.hasNext()) {
      Set<String> attractionIds = i.next();
      List<String> aIds = new ArrayList<String>(attractionIds);
      Collections.sort(aIds);
      boolean first = true;
      Iterator<String> j = aIds.iterator();
      while (j.hasNext()) {
        if (!first) sb.append(',');
        sb.append(j.next());
        first = false;
      }
      sb.append(":\n");
      Iterator<CalendarItem> k = openings.get(attractionIds).iterator();
      while (k.hasNext()) {
        sb.append(k.next());
        sb.append('\n');
      }
    }
    return sb.toString();
  }
}
