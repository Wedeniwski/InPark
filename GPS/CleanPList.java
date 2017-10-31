import java.io.*;
import java.util.*;

public class CleanPList {
  // java -cp GPS.jar CleanPList <parkId>
  public static void main(String[] args) {
    try {
      String parkId = args[0];
      System.out.println("PARK: " + parkId);
      Map plist = PList.readPListFile("../data/" + parkId + '/' + parkId + ".plist");
      Object o = plist.get("Land");
      if (o instanceof Map) {
        Map name = (Map)o;
        String en = (String)name.get("English.lproj");
        String de = (String)name.get("German.lproj");
        if (en != null) {
          name.remove("English.lproj");
          name.put("en", en);
        }
        if (de != null) {
          name.remove("German.lproj");
          name.put("de", de);
        }
      }
      Map m = (Map)plist.get("IDs");
      Iterator<String> keys = m.keySet().iterator();
      Set<String> internalKeys = new HashSet<String>(50);
      while (keys.hasNext()) {
        String attractionId = keys.next();
        if (attractionId == null) break;
        if (attractionId.startsWith("WP") && attractionId.endsWith(" - INTERN")) internalKeys.add(attractionId);
        Map attraction = (Map)m.get(attractionId);
        if (attraction.get("WP") != null) attraction.remove("WP");
        if (attraction.get("INCLUDED_DINING-ID") != null) attraction.remove("INCLUDED_DINING-ID");
        Object obj = attraction.get("Name");
        if (obj instanceof Map) {
          Map name = (Map)obj;
          String en = (String)name.get("English.lproj");
          String de = (String)name.get("German.lproj");
          if (en != null) {
            name.remove("English.lproj");
            name.put("en", en);
          }
          if (de != null) {
            name.remove("German.lproj");
            name.put("de", de);
          }
        }
        obj = attraction.get("Bild");
        if (obj instanceof String) {
          String name = (String)obj;
          if (name.length() > 0 && !name.endsWith(".jpg")) attraction.put("Bild", name+".jpg");
        }
        attraction.remove("Kategorie");
        obj = attraction.get("Kurzbeschreibung");
        if (obj instanceof Map) {
          Map name = (Map)obj;
          String en = (String)name.get("English.lproj");
          String de = (String)name.get("German.lproj");
          if (en != null) {
            name.remove("English.lproj");
            name.put("en", en);
          }
          if (de != null) {
            name.remove("German.lproj");
            name.put("de", de);
          }
        }
        obj = attraction.get("Name");
        if (obj instanceof Map) {
          Map name = (Map)obj;
          String en = (String)name.get("English.lproj");
          String de = (String)name.get("German.lproj");
          if (en != null) {
            name.remove("English.lproj");
            name.put("en", en);
          }
          if (de != null) {
            name.remove("German.lproj");
            name.put("de", de);
          }
        }
      }
      for (String internalWP : internalKeys) m.remove(internalWP);
      PList.writePListFile(parkId + "-new.plist", plist);
    } catch (IOException ioe) {
      ioe.printStackTrace();
    }
  }
}
