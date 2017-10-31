<?php
require_once('CalendarItem.php');

class CalendarData {
  protexted $parkId = null;
  //protected Map<Set<String>, List<CalendarItem> > openings;
  protected $openings = array();

  public function __construct($parkId) {
    $this->parkId = $parkId;
    //$this->openings = array();
  }

  protected function consolidate() {
    foreach ($this->openings as $key => $items) {
      int $i = 0;
      while ($i+1 < count($items)) {
        $c1 = $items[i];
        $c2 = $items[i+1];
        if ($c1->equalsTimeFrame($c2) && $c1->isEndDateOneDayBefore($c2)) {
          $items[i] = new CalendarItem($c1->startDate, $c2->endDate, $c1->startTime, $c1->endTime, $c1->startExtraHours, $c1->endExtraHours, $c1->startExtraHours2, $c1->endExtraHours2, $c1->winterData));
          unset($items[i+1]); // items.remove(i+1);
          $items = array_values($items);
        } else ++$i;
      }
    }
  }

  public function add($attractionIds, $item) {
    // ToDo: check if key can be array? Set<String>
    // ToDo: change completely!
    if (!isset($this->openings[$attractionIds])) {
      $items = array();
      $items[] = $item;
      $openings[$attractionIds] = $items;
      return;
    }
    $items = $this->openings[$attractionIds];
    $i = 0;
    $l = count($items);
    while ($i < $l) {
      $c = $items[$i];
      if ($item->isEndDateOneDayBefore($c)) {
        if ($item->equalsTimeFrame($c)) {
          $items[$i] = new CalendarItem($item->startDate, $c->endDate, $item->startTime, $item->endTime, $item->startExtraHours, $item->endExtraHours, $item->startExtraHours2, $item->endExtraHours2, $item->winterData));
        } else {
          $items[$i] = $item;
        }
        $this->consolidate();
        return;
      } else if ($c->isEndDateOneDayBefore($item)) {
        if ($item->equalsTimeFrame($c)) {
          $items[$i] = new CalendarItem($c->startDate, $item->endDate, $item->startTime, $item->endTime, $item->startExtraHours, $item->endExtraHours, $item->startExtraHours2, $item->endExtraHours2, $item->winterData));
        } else {
          $items[$i+1] = $item;
        }
        $this->consolidate();
        return;
      } else if ($c->compareTo($item) >= 0) {
        break;
      }
      ++$i;
    }
    while ($i > 0 && $item->isSameDay($items[$i-1]) && $item->compareTo($items[$i-1]) < 0) --$i;
    while ($i < $l && $item->isSameDay($items[$i]) && $item->compareTo($items[$i]) > 0) ++$i;
    $items[$i] = $item;
    $this->consolidate();
  }

  public function getCalendarItemsForDate($attractionIds, $date) {
    if (strlen($date) != 10) return null;
    $year = (10*($date[6]-'0')+$date[7]-'0');
    $month = (10*($date[3]-'0')+$date[4]-'0');
    $day = (10*($date[0]-'0')+$date[1]-'0');
    if (isset($this->openings[$attractionIds])) {
      $lst = $this->openings[$attractionIds];
      $items = array();
      foreach ($lst as $item) {
        $year2 = (10*($item->startDate[6]-'0')+$$item->startDate[7]-'0');
        $month2 = (10*($item->startDate[3]-'0')+$item->startDate[4]-'0');
        $day2 = (10*($item->startDate[0]-'0')+$item->startDate[1]-'0');
        if ($year > $year2 || ($year == $year2 && ($month > $month2 || ($month == $month2 && $day >= $day2)))) {
          $year2 = (10*($item->endDate[6]-'0')+$$item->endDate[7]-'0');
          $month2 = (10*($item->endDate[3]-'0')+$item->endDate[4]-'0');
          $day2 = (10*($item->endDate[0]-'0')+$item->endDate[1]-'0');
          if ($year < $year2 || ($year == $year2 && ($month < $month2 || ($month == $month2 && $day <= $day2)))) $items[] = $item;
        }
      }
      return $items;
    }
    return null;
  }

  public function toString() {
    // ToDo: performance similar to StringBuilder
    $sb = array($parkId, "\n\n");
    foreach ($this->openings as $attractionIds => $items) {
      $first = true;
      // ToDo: change $attractionIds to string!
      foreach ($attractionIds as $attractionId) {
        if (!$first) $sb[] = ',';
        $sb[] = $attractionId;
        $first = false;
      }
      $sb[] = ":\n";
      foreach ($items as $item) {
        $sb[] = $item->toString();
        $sb[] = "\n";
      }
    }
    return implode($sb);
  }
}
