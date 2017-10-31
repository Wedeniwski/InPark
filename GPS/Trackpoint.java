import java.util.*;

class Trackpoint implements Comparable {
  double latitude,longitude,elevation;
  long time;  // time in seconds!
  
  public Trackpoint(double latitude, double longitude, double elevation, long time) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.elevation = elevation;
    this.time = time;
  }
  
  public int compareTo(Object a) {
    long t = ((Trackpoint)a).time;
    if (time < t) return -1;
    if (time > t) return 1;
    return 0;
  }
  
  public boolean equalLocation(Trackpoint a) {
    return (latitude == a.latitude && longitude == a.longitude);
  }
  
  public boolean equals(Object a) {
    return (a != null && compareTo(a) == 0);
  }

  public String toString() {
    return "[" + latitude + ',' + longitude + ',' + elevation + ',' + time + ']';
  }

  public Trackpoint getNearestPoint(List<AttractionLocation> list) {
    Trackpoint nearest = null;
    double dist = 0.0;
    Iterator<AttractionLocation> i = list.iterator();
    while (i.hasNext()) {
      AttractionLocation t = i.next();
      double d = TrackSegment.distance(this, t);
      if (nearest == null || d < dist) {
        nearest = t;
        dist = d;
      }
    }
    return (nearest == null)? null : new Trackpoint(nearest.latitude, nearest.longitude, nearest.elevation, nearest.time);
  }

  public static Trackpoint parse(String data, int idx) {
    if (data.charAt(idx) != '[') return null;
    int l = data.length();
    int i = idx+1;
    while (i < l && data.charAt(i) != ',') ++i;
    if (i == l) return null;
    double lat = Double.valueOf(data.substring(idx+1, i));
    idx = i+1;
    while (++i < l && data.charAt(i) != ',');
    if (i == l) return null;
    double lon = Double.valueOf(data.substring(idx, i));
    idx = i+1;
    while (++i < l && data.charAt(i) != ',');
    if (i == l) return null;
    double ele = Double.valueOf(data.substring(idx, i));
    idx = i+1;
    while (++i < l && data.charAt(i) != ']');
    if (i == l) return null;
    return new Trackpoint(lat, lon, ele, Long.valueOf(data.substring(idx, i)));
  }

  public static int parseEnd(String data, int idx) {
    return data.indexOf(']', idx)+1;
  }
}
