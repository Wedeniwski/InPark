import java.util.*;

class TrackSegment implements Comparable, Iterator<Trackpoint> {
  private String fromAttractionId;
  private String toAttractionId;
  List<Trackpoint> trackPoints;
  private int iter = -1;

  public static double distance(double lat1, double lon1, double lat2, double lon2) {
    final double DEG2RAD = 0.017453292519943;
    final double rlat1 = lat1*DEG2RAD;
    final double rlat2 = lat2*DEG2RAD;
    return Math.acos(Math.sin(rlat1)*Math.sin(rlat2) + Math.cos(rlat1)*Math.cos(rlat2)*Math.cos((lon1-lon2)*DEG2RAD)) * 6371007.2;
  }

  public static double distance(Trackpoint t1, Trackpoint t2) {
    return distance(t1.latitude, t1.longitude, t2.latitude, t2.longitude);
  }

  public TrackSegment(String startId) {
    fromAttractionId = startId;
    toAttractionId = null;
    trackPoints = new ArrayList<Trackpoint>(10);
  }

  public String getFromAttractionId() {
    return fromAttractionId;
  }
  
  public String getToAttractionId() {
    return toAttractionId;
  }
  
  public void setFromAttractionId(String startId) {
    fromAttractionId = startId;
  }
  
  public void setToAttractionId(String endId) {
    toAttractionId = endId;
  }
  
  public void add(Trackpoint t) {
    trackPoints.add(t);
  }
  
  public void add(int idx, Trackpoint t) {
    trackPoints.add(idx, t);
  }
  
  public int size() {
    return trackPoints.size();
  }

  public Trackpoint first() {
    int l = trackPoints.size();
    return (l > 0)? trackPoints.get(0) : null;
  }
  
  public Trackpoint last() {
    int l = trackPoints.size();
    return (l > 0)? trackPoints.get(l-1) : null;
  }
  
  public void resetIterator() {
    iter = -1;
  }

  public boolean hasNext() {
    return (iter+1 < trackPoints.size());
  }

  public Trackpoint next() {
    if (iter+1 < trackPoints.size()) return trackPoints.get(++iter);
    throw new NoSuchElementException();
  }

  public void remove() {
    throw new UnsupportedOperationException();
  }

  public double getTrackDistance() {  // in m
    double d = 0.0;
    Iterator<Trackpoint> i = trackPoints.iterator();
    if (i.hasNext()) {
      Trackpoint t2 = i.next();
      while (i.hasNext()) {
        Trackpoint t1 = t2;
        t2 = i.next();
        d += distance(t1.latitude, t1.longitude, t2.latitude, t2.longitude);
      }
    }
    return d;
  }
  
  public long getTrackTime() {  // in sec
    int l = trackPoints.size();
    if (l > 1) {
      long t1 = trackPoints.get(0).time;
      long t2 = trackPoints.get(l-1).time;
      return t2-t1;
    }
    return 0;
  }
  
  public int compareTo(Object a) {
    return fromAttractionId.compareTo(((TrackSegment)a).fromAttractionId);
  }
  
  public boolean equals(Object a) {
    return (a != null && compareTo(a) == 0);
  }

  public boolean equalTrackPoints(TrackSegment a) {
    int l = trackPoints.size();
    if (l != a.trackPoints.size()) return false;
    for (int i = 0; i < l; ++i) {
      if (!trackPoints.get(i).equalLocation(a.trackPoints.get(i))) return false;
    }
    return true;
  }

  public boolean equalReverseTrackPoints(TrackSegment a) {
    int l = trackPoints.size();
    if (l != a.trackPoints.size()) return false;
    for (int i = 0; i < l; ++i) {
      if (!trackPoints.get(i).equalLocation(a.trackPoints.get(l-1-i))) return false;
    }
    return true;
  }
  
  public String toString() {
    StringBuffer s = new StringBuffer(1000);
    s.append(fromAttractionId);
    s.append(';');
    s.append(toAttractionId);
    int l = trackPoints.size();
    for (int i = 0; i < l; ++i) {
      s.append(trackPoints.get(i).toString());
    }
    return s.toString();
  }
  
  public static TrackSegment parse(String data, int idx) {
    int i = data.indexOf(';', idx);
    int l = data.length();
    if (i < 0 || i+1 >= l) return null;
    TrackSegment segment = new TrackSegment(data.substring(idx, i));
    idx = i+1;
    i = data.indexOf('[', idx);
    if (i < 0 || i+1 >= l) {
      segment.setToAttractionId(data.substring(idx));
      return segment;
    }
    segment.setToAttractionId(data.substring(idx, i));
    while (i > 0 && i < l) {
      Trackpoint t = Trackpoint.parse(data, i);
      if (t == null) break;
      segment.add(t);
      i = Trackpoint.parseEnd(data, i);
    }
    return segment;
  }
}
