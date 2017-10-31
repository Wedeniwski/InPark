import java.io.*;
import java.text.*;
import java.util.*;

public class Tour {
  private static List<String> list = null;
  private static String getLocationId(int idx) {
    if (list == null) {
      // read only first line; format <locationId>,...
      List<String> al = new ArrayList<String>(1000);
      BufferedReader reader = null;
      try {
        reader = new BufferedReader(new FileReader("map.txt"));
        String line = reader.readLine();
        int l = line.length();
        for (int i = 0; i < l; ++i) {
          int j = line.indexOf(',', i);
          if (j >= 0) {
            al.add(line.substring(i, j));
            i = j;
          } else {
            al.add(line.substring(i));
            break;
          }
        }
        list = al;
      } catch (IOException ioe) {
        ioe.printStackTrace();
      } finally {
        try {
          reader.close();
        } catch (IOException ioe) {
        }
      }
    }
    return (idx < list.size())? list.get(idx) : null;
  }

  private static String valueOf(String line) {
    if (line != null) {
      int i = line.indexOf('>');
      int j = line.indexOf('<', i+1);
      if (i >= 0 && j > i) {
        return line.substring(i+1, j);
      }
    }
    return null;
  }

  private static String getAttractionName(String id) throws IOException {
    BufferedReader reader = null;
    try {
      reader = new BufferedReader(new FileReader("../de.lproj/Root.plist"));
      String s = "<key>" + id + "</key>";
      while (true) {
        String line = reader.readLine();
        if (line == null) break;
        if (line.indexOf(s) >= 0) {
          do {
            line = reader.readLine();
          } while (line != null && line.indexOf("<key>Name</key>") == -1);
          if (line != null) {
            line = reader.readLine();
            return valueOf(line);
          }
        }
      }
    } finally {
      reader.close();
    }
    return null;
  }
  
  public static void main(String[] args) {
    Set<String> set = new HashSet<String>(1000);
    BufferedWriter writer = null;
    BufferedReader reader = null;
    try {
      writer = new BufferedWriter(new FileWriter("tour.txt"));
      int i = 0;
      while (true) {
        String id = getLocationId(i);
        if (id == null) break;
        writer.write(id);
        set.add(id);
        String s = getAttractionName(id);
        if (s != null) {
          writer.write(": ");
          writer.write(s);
        }
        writer.write("\n");
        ++i;
      }
      reader = new BufferedReader(new FileReader("../de.lproj/Root.plist"));
      String line = null;
      do {
        line = reader.readLine();
      } while (line.indexOf("MENU_ATTRACTION_BY_CATEGORY") == -1);
      while (true) {
        line = reader.readLine();
        if (line == null || line.indexOf("MENU_ATTRACTION_BY_PROFILE") >= 0) break;
        if (line.indexOf("<key>") >= 0) {
          String s = valueOf(line);
          if (!set.contains(s)) {
            System.out.println("MISSING id in tour: " + s + " - " + getAttractionName(s));
          }
          do {
            line = reader.readLine();
          } while (line.indexOf("</dict>") == -1);
        }
      }      
    } catch (Throwable t) {
      t.printStackTrace();
    } finally {
      try {
        if (writer != null) {
          writer.close();
        }
        if (reader != null) {
          reader.close();
        }
      } catch (IOException ioe) {
      }
    }
    
  }
}
