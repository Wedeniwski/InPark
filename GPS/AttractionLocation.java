class AttractionLocation extends Trackpoint {
  String locationId;
  
  public AttractionLocation(String locationId, double latitude, double longitude, double elevation, long time) {
    super(latitude, longitude, elevation, time);
    this.locationId = locationId;
  }

  public int compareTo(Object a) {
    String aId = ((AttractionLocation)a).locationId;
    if (locationId.length() < aId.length()) return -1;
    if (locationId.length() > aId.length()) return 1;
    int c = locationId.compareTo(aId);
    return (c != 0)? c : super.compareTo(a);
  }
  
  public String toString() {
    return locationId + super.toString();
  }
  
  public String keysToString() {
    return "@\"" + locationId + "\"";
  }
  
  public static AttractionLocation parse(String data, int idx) {
    int i = data.indexOf('[', idx);
    int l = data.length();
    if (i < 0 || i+1 >= l || data.indexOf(';', idx) >= 0) return null;
    String lId = data.substring(idx, i);
    idx = i+1;
    while (++i < l && data.charAt(i) != ',');
    if (i == l) return null;
    double lat = Double.valueOf(data.substring(idx, i));
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
    return new AttractionLocation(lId, lat, lon, ele, Long.valueOf(data.substring(idx, i)));
  }

  public static int parseEnd(String data, int idx) {
    return data.indexOf(']', idx)+1;
  }
}

