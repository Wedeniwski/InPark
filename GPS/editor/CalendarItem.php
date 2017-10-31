<?php
class CalendarItem implements Comparable {
	$startDate; // dd.MM.yyyy
	$endDate;
	$startTime;
	$endTime;
  $startExtraHours;
  $endExtraHours;
  $startExtraHours2;
  $endExtraHours2;
  $winterData;

  public function __construct($startDate, $endDate, $startTime, $endTime, $startExtraHours, $endExtraHours, $startExtraHours2, $endExtraHours2, $winterData) {
    $this->startDate = $startDate;
    $this->endDate = $endDate;
    $this->startTime = $startTime;
    $this->endTime = $endTime;
    $this->startExtraHours = $startExtraHours;
    $this->endExtraHours = $endExtraHours;
    $this->startExtraHours2 = $startExtraHours2;
    $this->endExtraHours2 = $endExtraHours2;
    $this->winterData = $winterData;
  }

  /*public function __construct($startDate, $endDate, $startTime, $endTime, $startExtraHours, $endExtraHours, $winterData) {
    // ToDo: check 2 constructors and constructor call; may be with new
    __construct($startDate, $endDate, $startTime, $endTime, $startExtraHours, $endExtraHours, null, null, $winterData);
  }*/
  
  public function equalsTimeFrame($item) {
    if ($this->startExtraHours == null) {
      if ($item->startExtraHours != null) return false;
    } else if ($item->startExtraHours == null) return false;
    if ($this->startExtraHours2 == null) {
      if ($item->startExtraHours2 != null) return false;
    } else if ($item->startExtraHours2 == null) return false;
    return ($this->winterData == $item->winterData && strcmp($this->startTime, $item->startTime) == 0 && strcmp($this->endTime, $item->endTime) == 0 && ($this->startExtraHours == null || strcmp($this->startExtraHours, $item->startExtraHours) == 0 && strcmp($this->endExtraHours, $item->endExtraHours) == 0) && ($this->startExtraHours2 == null || strcmp($this->startExtraHours2, $item->startExtraHours2) == 0 && strcmp($this->endExtraHours2, $item->endExtraHours2) == 0));
  }
  
  public function equals($obj) {
    if ($obj instanceof CalendarItem) {
      return (strcmp($this->startTime, $obj->startTime) == 0 && strcmp($this->endTime, $obj->endTime) == 0 && strcmp($this->startDate, $obj->startDate) == 0 && strcmp($this->endDate, $obj->endDate) == 0);
    }
    return false;
  }

  public function compareTo($item) {
    if ($this->startDate.length() != 10 || $item->startDate.length() != 10) return 0;
    $c = (10*($this->startDate[6]-'0')+$this->startDate[7]-'0');
    $d = (10*($item->startDate[6]-'0')+$item->startDate[7]-'0');
    if ($c < $d) return -1;
    if ($c > $d) return 1;
    $c = (10*($this->startDate[3]-'0')+$this->startDate[4]-'0');
    $d = (10*($item->startDate[3]-'0')+$item->startDate[4]-'0');
    if ($c < $d) return -1;
    if ($c > $d) return 1;
    $c = (10*($this->startDate[0]-'0')+$this->startDate[1]-'0');
    $d = (10*($item->startDate[0]-'0')+$item->startDate[1]-'0');
    if ($c < $d) return -1;
    if ($c > $d) return 1;
    $c = strcmp($this->startTime, $item->startTime);
    if ($c != 0) return $c;
    return strcmp($this->endTime, $item->endTime);
  }

  public function isSameDay($item) {
    if ($this->startDate.length() != 10 || $item->startDate.length() != 10) return false;
    if ($this->startDate[0] != $item->startDate[0] || $this->startDate[1] != $item->startDate[1]) return false;
    if ($this->startDate[3] != $item->startDate[3] || $this->startDate[4] != $item->startDate[4]) return false;
    return (strcmp($this->startDate+6, $item->startDate+6) == 0);
  }
  
  //private static SimpleDateFormat formatterDate = new SimpleDateFormat("dd.MM.yyyy");
  /*public function isEndDateOneDayBefore($item) {
    // ToDo: how implement Calendar
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
  }*/

  public function getTimeFrame() {
    return $this->startTime . '-' . $this->endTime;
  }

  public function toString() {
    if ($this->startExtraHours != null) {
      if ($this->startExtraHours2 != null) {
        return ($this->winterData)? $this->startDate . '-' . $this->endDate . "-w;" . $this->startTime . '-' . $this->endTime . ';' . $this->startExtraHours . '-' . $this->endExtraHours . "+;" . $this->startExtraHours2 . '-' . $this->endExtraHours2 . '+' : $this->startDate . '-' . $this->endDate . ';' . $this->startTime . '-' . $this->endTime . ';' . $this->startExtraHours . '-' . $this->endExtraHours . "+;" . $this->startExtraHours2 . '-' . $this->endExtraHours2 . '+';
      } else {
        return ($this->winterData)? $this->startDate . '-' . $this->endDate . "-w;" . $this->startTime . '-' . $this->endTime . ';' . $this->startExtraHours . '-' . $this->endExtraHours . '+' : $this->startDate . '-' . $this->endDate . ';' . $this->startTime . '-' . $this->endTime . ';' . $this->startExtraHours . '-' . $this->endExtraHours . '+';
      }
    }
    return ($this->winterData)? $this->startDate . '-' . $this->endDate . "-w;" . $this->startTime . '-' . $this->endTime : $this->startDate . '-' . $this->endDate . ';' . $this->startTime . '-' . $this->endTime;
  }
}
