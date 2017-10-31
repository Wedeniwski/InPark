class WaitingTimesItem {
  int waitTime;
  boolean fastLaneInfoAvailable;
  short fastLaneAvailable; // >0 : Available, <0 : Limited Availability, 0 : Unavailable
  String fastLaneAvailableTimeFrom; // format HHmm
  String fastLaneAvailableTimeTo; // format HHmm
  //String startTimes;
  
  WaitingTimesItem() {
    waitTime = 0;
    fastLaneInfoAvailable = false;
    fastLaneAvailable = 0;
    fastLaneAvailableTimeFrom = fastLaneAvailableTimeTo = null;
    //startTimes = null;
  }
}
