import java.io.*;
import java.text.*;
import java.util.*;

public class FilterAttractionLocations {
  static DateFormat gpxTimeFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static String INTERNAL_WAYPOINT = "INTERNAL";
  private static Map<String, String> similarWaypoints = new HashMap<String, String>(20);
  private static Map wpMapping = null;
  private static int numberOfShortestPathes = 0;

  private static void parseLatLon(String data, double[] latLon) {
    int i = 0;
    while (data.charAt(i) != '\"') ++i;
    int j = i+1;
    while (data.charAt(j) != '\"') ++j;
    latLon[0] = Double.valueOf(data.substring(i+1, j));
    i = j+1;
    while (data.charAt(i) != '\"') ++i;
    j = i+1;
    while (data.charAt(j) != '\"') ++j;
    latLon[1] = Double.valueOf(data.substring(i+1, j));
  }

  private static double parseElevation(String data) {
    int i = data.indexOf("<ele>")+5;
    if (data.charAt(i) == '<') return 0.0;
    int j = i+1;
    while (data.charAt(j) != '<') ++j;
    return Double.valueOf(data.substring(i, j));
  }
  
  private static long parseTime(String data) {
    long time = 0;
    int i = data.indexOf("<time>")+6;
    if (data.charAt(i) == '<') return 0;
    int j = i+1;
    while (data.charAt(j) != '<') ++j;
    try {
      String stringTime = data.substring(i, j);
      if (stringTime.length() == 0 || stringTime.equals("0")) time = 0;
      else {
        Date date = gpxTimeFormat.parse(stringTime);
        time = date.getTime()/1000;
      }
    } catch (ParseException e) {
      e.printStackTrace();
      System.exit(1);
    }
    return time;
  }

  private static String parseName(String data) {
    int i = data.indexOf("<name>")+6;
    //while (data.charAt(i) != '>') ++i;
    int j = i;
    while (data.charAt(j) != '<') ++j;
    return data.substring(i, j);
  }

  private static double deg2rad(double deg) {
    return deg * Math.PI / 180.0;
  }

  private static String getWPMapping(String parkId, String wp, boolean includingSimilarWpt) {
    if (wp == null || wp.length() == 0) return wp;
    if (wpMapping == null) {
      try {
        wpMapping = PList.readPListFile("../data/" + parkId + '/' + parkId + ".plist");
      } catch (IOException ioe) {
        ioe.printStackTrace();
      }
      /*wpMapping = new HashMap<String, String>(100);
      File f = new File("wp_map.txt");
      if (f.exists()) {
        try {
          reader = new BufferedReader(new FileReader(f));
          while (true) {
            String line = reader.readLine();
            if (line == null) break;
            int i = line.indexOf(" WP");
            int j = line.indexOf(": ");
            if (i >= 0 && j > i) {
              String s = line.substring(i+1, j);
              i = line.indexOf(' ', j+2);
              if (i > j+2) wpMapping.put(s, line.substring(j+2, i));
            }
          }
        } catch (IOException ioe) {
          ioe.printStackTrace();
        } finally {
          try {
            if (reader != null) reader.close();
          } catch (IOException ioe) {
          }
        }
      }
    }
    String wpt = wpMapping.get(wp);
    if (wpt != null && !includingSimilarWpt) {
      int i = wpt.indexOf('=');
      if (i >= 0) return wpt.substring(0, i);*/
    }
    if (wpMapping == null) return wp;
    //return (wpt == null)? wp : wpt;
    Map m = (Map)wpMapping.get("IDs");
    if (m == null) return wp;
    boolean noWP = true;
    Iterator<String> keys = m.keySet().iterator();
    while (keys.hasNext()) {
      String attractionId = keys.next();
      if (attractionId == null) break;
      Map attraction = (Map)m.get(attractionId);
      String wpAttraction = (String)attraction.get("WP");
      if (wpAttraction != null) {
        if (wpAttraction.equals(wp)) return (attractionId.length() == 0)? wp : attractionId;
        noWP = false;
      }
    }
    if (noWP) wpMapping.clear();
    return wp;
  }

  private static void readGPXfile(String parkId, String filename, List<TrackSegment> listTrkseg, Map<String, List<AttractionLocation> > mapWpt) throws IOException {
    //int idx = 0;
    //listTrkseg.clear();
    int internalTrackSegementIndex = 0;
    boolean onlyInternalTrackSegementIndex = true;
    TrackSegment currentTrackSegment = null;
    BufferedReader reader = null;
    try {
      reader = new BufferedReader(new FileReader(filename));
      while (true) {
        String line = reader.readLine();
        if (line == null) break;
        if (line.indexOf("<wpt") >= 0) {
          double[] latLon = new double[2];
          double elevation = 0.0;
          parseLatLon(line.substring(line.indexOf("<wpt")+4), latLon);
          String name = null;
          long time = 0;
          while (name == null || time == 0) {
            line = reader.readLine();
            if (line == null || line.indexOf("</wpt>") >= 0) break;
            if (line.indexOf("<name>") >= 0) {
              name = getWPMapping(parkId, parseName(line), true);
              int k = name.indexOf('=');
              if (k >= 0) {
                String rootAttractionId = name.substring(0, k).trim();
                name = name.substring(k+1).trim();
                similarWaypoints.put(name, rootAttractionId);
                name = rootAttractionId;
              }
            }
            if (line.indexOf("<ele>") >= 0) elevation = parseElevation(line);
            if (line.indexOf("<time>") >= 0) time = parseTime(line);
          }
          List<AttractionLocation> list = mapWpt.get(name);
          AttractionLocation loc = new AttractionLocation(name, latLon[0], latLon[1], elevation, time);
          if (list == null) list = new ArrayList<AttractionLocation>(5);
          else if (list.size() > 0) {
            AttractionLocation loc2 = list.get(0);
            if (list.size() > 1 || loc.compareTo(loc2) != 0) {
              System.out.println("ERROR: Multile different points are defined for " + name);
              System.exit(1);
            }
            list = null;
          }
          if (list != null) {
            list.add(loc);
            mapWpt.put(name, list);
          }
          if (line == null) break;
        }
        if (line.indexOf("<trkseg>") >= 0) {
          int i = line.indexOf(" <!-- ");
          int j = line.indexOf(" - ", i+6);
          int k = line.indexOf(" -->", j+3);
          if (j >= 0 && k >= 0 && line.substring(j+3, k).startsWith("INTERN")) j = line.indexOf(" - ", j+3);
          if (i < 0 || j < 0 || k < 0) {
            if (!onlyInternalTrackSegementIndex) {
              System.out.println("ERROR: Missing meta information about attraction IDs as comment of trkseg (" + line + ')');
              System.exit(1);
            }
            if (currentTrackSegment == null || currentTrackSegment.size() > 1) {
              currentTrackSegment = new TrackSegment("WP" + internalTrackSegementIndex);
              ++internalTrackSegementIndex;
              currentTrackSegment.setToAttractionId("WP" + internalTrackSegementIndex);
              listTrkseg.add(currentTrackSegment);
            }
          } else {
            onlyInternalTrackSegementIndex = false;
            String from = getWPMapping(parkId, line.substring(i+6, j), false);
            String to = getWPMapping(parkId, line.substring(j+3, k), false);
            //System.out.println("from=" + from + " (" + line.substring(i+6, j) + "), to=" + to + " (" + line.substring(j+3, k) + ')');
            currentTrackSegment = new TrackSegment(from);
            currentTrackSegment.setToAttractionId(to);
            listTrkseg.add(currentTrackSegment);
          }
        }
        if (line.indexOf("<trkpt") >= 0) {
          double[] latLon = new double[2];
          double elevation = 0.0;
          try {
            parseLatLon(line.substring(line.indexOf("<trkpt")+6), latLon);
          } catch (Exception e) {
            System.out.println("line: " + line);
            e.printStackTrace();
            System.exit(1);
          }
          long time = 0;
          while (time == 0) {
            line = reader.readLine();
            if (line == null || line.indexOf("</trkpt>") >= 0) break;
            if (line.indexOf("<ele>") >= 0) elevation = parseElevation(line);
            if (line.indexOf("<time>") >= 0) time = parseTime(line);
          }
          Trackpoint newTrackpoint = new Trackpoint(latLon[0], latLon[1], elevation, time);
          Trackpoint lastTrackpoint = currentTrackSegment.last();
          if (lastTrackpoint == null || !lastTrackpoint.equalLocation(newTrackpoint)) currentTrackSegment.add(newTrackpoint);
        }
      }
      //Collections.sort(listWpt);
      //Collections.sort(listTrkpt);
    } finally {
      reader.close();
    }
    /*if (idx < waypointsName.size()) {
      String name = getLocationIdforWaypoint(mapFileName, idx, filename);
      if (name != null) {
        System.out.println("More names are existing but NO further track segments available!");
        System.out.println("No segment for name " + name);
      }
    }*/
  }

  private static void mapSegmentsOnRootIds(List<TrackSegment> listTrkseg, Map<String, List<AttractionLocation> > mapWpt) {
    Iterator<TrackSegment> iter = listTrkseg.iterator();
    while (iter.hasNext()) {
      TrackSegment ts = iter.next();
      String from = ts.getFromAttractionId();
      String rootFrom = similarWaypoints.get(from);
      if (rootFrom != null) ts.setFromAttractionId(rootFrom);
      String to = ts.getToAttractionId();
      String rootTo = similarWaypoints.get(to);
      if (rootTo != null) ts.setToAttractionId(rootTo);
    }
    Iterator<String> i = mapWpt.keySet().iterator();
    while (i.hasNext()) {
      String attractionId = i.next();
      String rootAttractionId = similarWaypoints.get(attractionId);
      if (rootAttractionId != null) {
        List<AttractionLocation> data = mapWpt.remove(attractionId);
        if (mapWpt.put(rootAttractionId, data) != null) {
          System.out.println("ERROR: already defined values for " + rootAttractionId + ". Values from " + attractionId + " cannot be moved!");
          System.exit(1);
        }
      }
    }
    iter = listTrkseg.iterator();
    while (iter.hasNext()) {
      TrackSegment ts = iter.next();
      String attractionId = ts.getFromAttractionId();
      List<AttractionLocation> list = mapWpt.get(attractionId);
      if (list == null) {
        Trackpoint t = ts.first();
        System.out.println("Wpt missing for " + attractionId + " (" + t.latitude + ", " + t.longitude + "). Will be added.");
        AttractionLocation loc = new AttractionLocation(attractionId, t.latitude, t.longitude, 0.0, 0);
        list = new ArrayList<AttractionLocation>(5);
        list.add(loc);
        mapWpt.put(attractionId, list);
      }
      attractionId = ts.getToAttractionId();
      list = mapWpt.get(attractionId);
      if (list == null) {
        Trackpoint t = ts.last();
        System.out.println("Wpt missing for " + attractionId + " (" + t.latitude + ", " + t.longitude + "). Will be added.");
        AttractionLocation loc = new AttractionLocation(attractionId, t.latitude, t.longitude, 0.0, 0);
        list = new ArrayList<AttractionLocation>(5);
        list.add(loc);
        mapWpt.put(attractionId, list);
      }
    }
  }

  private static void connectSegments(List<TrackSegment> listTrkseg, Map<String, List<AttractionLocation> > mapWpt) {
    Iterator<TrackSegment> iter = listTrkseg.iterator();
    while (iter.hasNext()) {
      TrackSegment ts = iter.next();
      Trackpoint t = ts.first();
      List<AttractionLocation> list = mapWpt.get(ts.getFromAttractionId());
      int i = 0;
      int l = list.size();
      while (i < l && !t.equalLocation(list.get(i))) ++i;
      if (i == l) ts.add(0, t.getNearestPoint(list));
      t = ts.last();
      list = mapWpt.get(ts.getToAttractionId());
      i = 0;
      l = list.size();
      while (i < l && !t.equalLocation(list.get(i))) ++i;
      if (i == l) ts.add(t.getNearestPoint(list));
    }
  }

  private static void consolidateSegments(List<TrackSegment> listTrkseg) {
    int l = listTrkseg.size();
    for (int i = 0; i < l; ++i) {
      TrackSegment s = listTrkseg.get(i);
      for (int j = i+1; j < l; ++j) {
        TrackSegment t = listTrkseg.get(j);
        if (s.getFromAttractionId().equals(t.getFromAttractionId()) && s.getToAttractionId().equals(t.getToAttractionId())) {
          if (s.equalTrackPoints(t)) {
            listTrkseg.remove(j);
            --j; --l;
          } else {
            System.out.println("ERROR: track segment from " + t.getFromAttractionId() + " to " + t.getToAttractionId() + " already exist and has different coordinates!");
            System.out.println("Distance: " + s.getTrackDistance() + " for " + s.toString());
            System.out.println("Distance: " + t.getTrackDistance() + " for " + t.toString());
          }
        } else if (s.getFromAttractionId().equals(t.getToAttractionId()) && s.getToAttractionId().equals(t.getFromAttractionId())) {
          if (s.equalReverseTrackPoints(t)) {
            listTrkseg.remove(j);
            --j; --l;
          } else {
            System.out.println("ERROR: track segment from " + t.getFromAttractionId() + " to " + t.getToAttractionId() + " already reverse exist and has different coordinates!");
            System.out.println("Distance: " + s.getTrackDistance() + " for " + s.toString());
            System.out.println("Distance: " + t.getTrackDistance() + " for " + t.toString());
          }
        }
      }
    }
  }

  private static void writeGPXfile(String name, List<List<Trackpoint> > trackSegments, Map<String, List<AttractionLocation> > mapWpt) {
    BufferedWriter writer = null;
    try {
      writer = new BufferedWriter(new FileWriter(name + ".gpx"));
      writer.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n");
      writer.write("<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" creator=\"InPark\" version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n");
      writer.write("<trk>\n  <name>");
      writer.write(name);
      writer.write("</name>\n");
      if (trackSegments != null) {
        Iterator<List<Trackpoint> > i = trackSegments.iterator();
        while (i.hasNext()) {
          writer.write("  <trkseg>\n");
          List<Trackpoint> list = i.next();
          Iterator<Trackpoint> j = list.iterator();
          while (j.hasNext()) {
            Trackpoint t = j.next();
            writer.write("    <trkpt lat=\"");
            writer.write(Double.toString(t.latitude));
            writer.write("\" lon=\"");
            writer.write(Double.toString(t.longitude));
            writer.write("\">\n      <ele>");
            writer.write(Double.toString(t.elevation));
            writer.write("</ele>\n      <time>");
            writer.write(gpxTimeFormat.format(new Date(t.time)));
            writer.write("Z</time>\n    </trkpt>\n");
          }
          writer.write("  </trkseg>\n");
        }
      }
      writer.write("</trk>\n");
      if (mapWpt != null) {
        Iterator<String> i = mapWpt.keySet().iterator();
        while (i.hasNext()) {
          String aId = i.next();
          List<AttractionLocation> list = mapWpt.get(aId);
          Iterator<AttractionLocation> j = list.iterator();
          for (int k = 0; j.hasNext(); ++k) {
            AttractionLocation t = j.next();
            writer.write("  <wpt lat=\"");
            writer.write(Double.toString(t.latitude));
            writer.write("\" lon=\"");
            writer.write(Double.toString(t.longitude));
            writer.write("\">\n    <name>");
            writer.write(aId);
            if (k > 0) writer.write("-" + k);
            writer.write("</name>\n    <ele>");
            writer.write(Double.toString(t.elevation));
            writer.write("</ele>\n      <time>");
            writer.write(gpxTimeFormat.format(new Date(t.time)));
            writer.write("Z</time>\n    <sym>Dot</sym>\n  </wpt>\n");
          }
        }
      }
      writer.write("</gpx>");
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      try {
        writer.close();
      } catch (IOException ioe) {
      }
    }
  }
  
  public static void statistics(Map<String, List<AttractionLocation> > mapWpt, List<TrackSegment> listTrkseg) {
    System.out.println("Number of unique way points: " + mapWpt.size());
    //System.out.println("Number of way points in tour: " + waypointsName.size());
    int trkPts = 0;
    int n = 0;
    double minDistance = -1.0;
    double maxDistance = 0.0;
    double avgDistance = 0.0;
    long minTimeDifference = -1;
    long maxTimeDifference = 0;
    long avgTimeDifference = 0;
    Iterator<TrackSegment> i = listTrkseg.iterator();
    while (i.hasNext()) {
      TrackSegment ts = i.next();
      trkPts += ts.size();
      double d = ts.getTrackDistance();
      long t = ts.getTrackTime();
      if (minDistance < 0 || d < minDistance) minDistance = d;
      if (d > maxDistance) maxDistance = d;
      avgDistance += d;
      if (minTimeDifference < 0 || t < minTimeDifference) minTimeDifference = t;
      if (t > minTimeDifference) maxTimeDifference = t;
      avgTimeDifference += t;
      ++n;
    }
    System.out.println("Total distance: " + avgDistance);
    avgDistance /= n; avgTimeDifference /= n;
    System.out.println("Number of track segments: " + listTrkseg.size());
    System.out.println("Number of track points: " + trkPts);
    System.out.println("Number of shortest pathes: " + numberOfShortestPathes);
    System.out.println("Distance between track points: avg - " + avgDistance + ", min - " + minDistance + ", max - " + maxDistance);
    //System.out.println("Time between track points: avg - " + avgTimeDifference + ", min - " + minTimeDifference + ", max - " + maxTimeDifference);
  }

  public static double distance(String fromAttractionId, String toAttractionId, List<TrackSegment> listTrkseg) {
    if (fromAttractionId.equals(toAttractionId)) return 0.0;
    Iterator<TrackSegment> i = listTrkseg.iterator();
    while (i.hasNext()) {
      TrackSegment t = i.next();
      if (fromAttractionId.equals(t.getFromAttractionId())) {
        if (toAttractionId.equals(t.getToAttractionId())) {
          return t.getTrackDistance();
        }
      } else if (fromAttractionId.equals(t.getToAttractionId())) {
        if (toAttractionId.equals(t.getFromAttractionId())) {
          return t.getTrackDistance();
        }
      }
    }
    return -1.0;
  }

  public static String distanceMatrix(String[] attractionIds, List<TrackSegment> listTrkseg) {
    numberOfShortestPathes = 0;
    int n = attractionIds.length;
    if (n > 0) {
      //final boolean track = false;
      //int trackI = (track)? Arrays.binarySearch(attractionIds, "s44") : -1;
      //int trackJ = (track)? Arrays.binarySearch(attractionIds, "sh32@1") : -1;
      double[][] d = new double[n][n];
      List<String>[][] shortestPath = new ArrayList[n][n];
      for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
          shortestPath[i][j] = new ArrayList<String>(10);
          double dist = distance(attractionIds[i], attractionIds[j], listTrkseg);
          //if (track && i == trackI && j == trackJ) System.out.println("INIT DISTANCE: " + dist);
          d[i][j] = dist;
          if (dist >= 0.0) {
            //System.out.println(attractionIds[i] + " - " + attractionIds[j] + ": " + dist);
            shortestPath[i][j].add(Integer.toString(i));//attractionIds[i]);
            shortestPath[i][j].add(Integer.toString(j));//attractionIds[j]);
          }
        }
      }
      for (int k = 0; k < n; ++k) {
        for (int i = 0; i < n; ++i) {
          if (d[i][k] >= 0.0) {
            for (int j = 0; j < n; ++j) {
              if (d[k][j] >= 0.0) {
                double dist = d[i][k] + d[k][j];
                if (d[i][j] < 0.0 || dist < d[i][j]) {
                  d[i][j] = dist;
                  //if (track && i == trackI && j == trackJ) System.out.print(attractionIds[i] + " - " + attractionIds[j] + " / ");
                  shortestPath[i][j].clear();
                  int l = shortestPath[i][k].size();
                  for (int m = 0; m < l; ++m) {
                    shortestPath[i][j].add(shortestPath[i][k].get(m));
                    //if (track && i == trackI && j == trackJ) System.out.print(shortestPath[i][k].get(m) + " (" + attractionIds[Integer.parseInt(shortestPath[i][k].get(m))] + ") - ");
                  }
                  l = shortestPath[k][j].size();
                  for (int m = 1; m < l; ++m) {
                    shortestPath[i][j].add(shortestPath[k][j].get(m));
                    //if (track && i == trackI && j == trackJ) System.out.print(" - " + shortestPath[k][j].get(m) + " (" + attractionIds[Integer.parseInt(shortestPath[k][j].get(m))] + ')');
                  }
                  //if (track && i == trackI && j == trackJ) System.out.println(": " + dist + " (" + shortestPath[i][j].size() + ')');
                }
              }
            }
          }
        }
      }
      StringBuilder buffer = new StringBuilder(50000);
      for (int i = 0; i < n; ++i) {
        for (int j = i+1; j < n; ++j) {
          int l = shortestPath[i][j].size()-1;
          long value = 0;
          if (l > 2) value = n*(1+Integer.parseInt(shortestPath[i][j].get(l-1)));
          if (l >= 2) value += 1+Integer.parseInt(shortestPath[i][j].get(1));
          //if (track && i == trackI && j == trackJ) System.out.println(attractionIds[i] + " - " + attractionIds[j] + ": " + value);
          buffer.append(value);
          buffer.append(';');
          ++numberOfShortestPathes;
        }
      }
      return buffer.toString();
    }
    return "";
  }

  static AttractionLocation equalLocation(AttractionLocation t, Collection<List<AttractionLocation>> list) {
    Iterator<List<AttractionLocation>> iter2 = list.iterator();
    while (iter2.hasNext()) {
      Iterator<AttractionLocation> iter = iter2.next().iterator();
      while (iter.hasNext()) {
        AttractionLocation a = iter.next();
        if (!a.locationId.equals(t.locationId) && a.equalLocation(t) && !(a.locationId.startsWith("000") && t.locationId.startsWith("000"))) return a;
      }
    }
    return null;
  }

  static String pathOfCurrentActiveSimulatorApp(String parkId) {
    File rootPath = new File("/Users/Wedeniwski/Library/Developer/CoreSimulator/Devices");
    File[] allSimulatorPathes = rootPath.listFiles();
    File latestAppPath = null;
    double lastModified = 0.0;
    double lastAppModified = 0.0;
    for (int i = 0; i < allSimulatorPathes.length; ++i) {
      if (allSimulatorPathes[i].isDirectory() && allSimulatorPathes[i].lastModified() > lastModified) {
        // find latest folder containing path "data"
        File[] dataPathes = allSimulatorPathes[i].listFiles();
        for (int j = 0; j < dataPathes.length; ++j) {
          if (dataPathes[j].isDirectory() && dataPathes[j].getName().equals("data")) {
            File[] dPathes = dataPathes[j].listFiles();
            for (int j0 = 0; j0 < dPathes.length; ++j0) {
              if (dPathes[j0].isDirectory() && dPathes[j0].getName().equals("Containers")) {
                File[] d1Pathes = dPathes[j0].listFiles();
                for (int j1 = 0; j1 < d1Pathes.length; ++j1) {
                  if (d1Pathes[j1].isDirectory() && d1Pathes[j1].getName().equals("Data")) {
                    File[] d2Pathes = d1Pathes[j1].listFiles();
                    for (int j2 = 0; j2 < d2Pathes.length; ++j2) {
                      if (d2Pathes[j2].isDirectory() && d2Pathes[j2].getName().equals("Application")) {
                        File[] installedAppPathes = d2Pathes[j2].listFiles();
                        // find latest folder containing "InPark.app"
                        for (int k = 0; k < installedAppPathes.length; ++k) {
                          if (installedAppPathes[k].isDirectory() && installedAppPathes[k].lastModified() > lastAppModified) {
                            // at least one file with suffix .gpx must exist in Documents folder
                            String[] documentFilenames = (new File(installedAppPathes[k].getPath() + "/Documents/")).list();
                            boolean gpxFileExist = false;
                            for (int l2 = 0; l2 < documentFilenames.length; ++l2) {
                              if (documentFilenames[l2].equals(parkId + ".gpx")) {
                                gpxFileExist = true;
                                break;
                              }
                            }
                            if (gpxFileExist) {
                              lastAppModified = installedAppPathes[k].lastModified();
                              lastModified = allSimulatorPathes[i].lastModified();
                              latestAppPath = installedAppPathes[k];
                              break;
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return (latestAppPath == null)? null : latestAppPath.getPath();
  }

  static void createData(String parkId) {
    BufferedWriter writer = null;
    Map<String, List<AttractionLocation> > mapWpt = new HashMap<String, List<AttractionLocation> >(300);
    List<TrackSegment> listTrkseg = new ArrayList<TrackSegment>(600);
    String trackDataFilename = parkId + ".gpx";
    String simulatorFilename = pathOfCurrentActiveSimulatorApp(parkId) + "/Documents/" + trackDataFilename;
    File simulatorFile = new File(simulatorFilename);
    File trackDataFile = new File(trackDataFilename);
    if (simulatorFile.exists() && simulatorFile.lastModified() > trackDataFile.lastModified()) {
      System.out.println("Use newer file at " + simulatorFilename);
      trackDataFilename = simulatorFilename;
    }
    String targetPath = "../data/" + parkId + '/' + parkId + ".txt";
    String tmpPath = parkId + "-tmp.txt";
    try {
      //System.out.println("read: " + trackDataFilename);
      readGPXfile(parkId, trackDataFilename, listTrkseg, mapWpt);
      mapSegmentsOnRootIds(listTrkseg, mapWpt);
      //connectSegments(listTrkseg, mapWpt);
      //consolidateSegments(listTrkseg);
      writer = new BufferedWriter(new FileWriter(tmpPath));
      String[] attractionIds = mapWpt.keySet().toArray(new String[0]);
      Arrays.sort(attractionIds);
      for (int i = 0; i < attractionIds.length; ++i) {
        List<AttractionLocation> list = mapWpt.get(attractionIds[i]);
        int l = list.size();
        if (l > 0) {
          AttractionLocation t = list.get(0);
          AttractionLocation t2 = equalLocation(t, mapWpt.values());
          if (t2 != null) System.out.println("ERROR: " + t.locationId + " and " + t2.locationId + " have same coordinates");
          writer.write(String.format("%s;%.6f;%.6f", t.locationId, t.latitude, t.longitude));
          /*writer.write(t.locationId);
          writer.write(";");
          writer.write(Double.toString(t.latitude));
          writer.write(";");
          writer.write(Double.toString(t.longitude));*/
          if (l > 1) {
            System.out.println("ERROR: Multiple locations (" + l + ") are not supported for one attraction ID (" + attractionIds[i] + ") anymore");
            System.exit(1);
          }
          /*for (int j = 1; j < l; ++j) {
           writer.write(",");
           t = list.get(j);
           t2 = equalLocation(t, mapWpt.values());
           if (t2 != null) System.out.println("ERROR: " + t.locationId + " and " + t2.locationId + " have same coordinates");
           writer.write(Double.toString(t.latitude));
           writer.write(";");
           writer.write(Double.toString(t.longitude));
           }*/
        }
        writer.write(";");
      }
      writer.write("\n");
      Iterator<TrackSegment> j = listTrkseg.iterator();
      while (j.hasNext()) {
        TrackSegment t = j.next();
        if (similarWaypoints.get(t.getToAttractionId()) != null) {
          System.out.println("ERROR! Track segment is defined through " + t.getToAttractionId() + " which is not a root attraction ID. Correct ID is " + similarWaypoints.get(t.getToAttractionId()));
          System.exit(1);
        }
        if (similarWaypoints.get(t.getFromAttractionId()) != null) {
          System.out.println("ERROR! Track segment is defined through " + t.getFromAttractionId() + " which is not a root attraction ID. Correct ID is " + similarWaypoints.get(t.getFromAttractionId()));
          System.exit(1);
        }
        int idx = Arrays.binarySearch(attractionIds, t.getToAttractionId());
        idx *= attractionIds.length;
        idx += Arrays.binarySearch(attractionIds, t.getFromAttractionId());
        writer.write(Integer.toString(idx));
        int l = t.size()-1;
        for (int k = 1; k < l; ++k) {
          Trackpoint tp = t.trackPoints.get(k);
          writer.write(String.format(";%.6f;%.6f", tp.latitude, tp.longitude));
          /*writer.write(";");
          writer.write(Double.toString(tp.latitude));
          writer.write(";");
          writer.write(Double.toString(tp.longitude));*/
        }
        writer.write("\n");
      }
      writer.write("\n");
      writer.write(distanceMatrix(attractionIds, listTrkseg));
      writer.write("\n");
      Iterator<String> iter = similarWaypoints.keySet().iterator();
      if (iter.hasNext()) {
        String key = iter.next();
        writer.write(key);
        writer.write("=");
        writer.write(similarWaypoints.get(key));
        while (iter.hasNext()) {
          key = iter.next();
          writer.write(";");
          writer.write(key);
          writer.write("=");
          writer.write(similarWaypoints.get(key));
        }
      }
    } catch (Throwable t) {
      t.printStackTrace();
    } finally {
      try {
        if (writer != null) {
          writer.close();
        }
      } catch (IOException ioe) {
      }
    }
    statistics(mapWpt, listTrkseg);
    try {
      FileInputStream fin = new FileInputStream(tmpPath);
      if (FileUtilities.equals(fin, targetPath)) {
        System.out.println("No changes for " + parkId);
        FileUtilities.delete(tmpPath);
      } else {
        FileUtilities.delete(targetPath);
        FileUtilities.move(tmpPath, targetPath);
        System.out.println("Copy data " + targetPath + " to path " + pathOfCurrentActiveSimulatorApp(parkId));
        FileUtilities.copy(targetPath, pathOfCurrentActiveSimulatorApp(parkId) + "/Library/Application Support/data/" + targetPath);
      }
    } catch (Throwable t) {
      t.printStackTrace();
    }
  }

  /*static List<String> excludeFiles() {
    List<String> result = new ArrayList<String>(10);
    BufferedReader reader = null;
    try {
      reader = new BufferedReader(new FileReader("exclude.txt"));
      while (true) {
        String line = reader.readLine();
        if (line == null) break;
        StringTokenizer st = new StringTokenizer(line, ",");
        while (st.hasMoreTokens()) result.add(st.nextToken());
      }
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      try {
        if (reader != null) reader.close();
      } catch (IOException ioe) {
      }
    }
    return result;
  }*/

  // java -cp GPS.jar CleanPList <parkId>
  public static void main(String[] args) {
    if (args.length != 1) {
      System.err.println("USAGE: <park id>");
      System.err.println(" e.g. java -jar GPS.jar ep");
      return;
    }
    String parkId = args[0];
    File file = new File(parkId + ".gpx");
    if (file.exists()) {
      file = new File("../data/" + parkId);
      if (file.exists() && file.isDirectory()) {
        similarWaypoints.clear();
        createData(parkId);
      } else System.err.println(parkId + " directory missing in the data path");
    } else System.err.println(parkId + ".gpx file missing in the local directoy");
  }
}
