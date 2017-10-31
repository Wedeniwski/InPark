import java.io.*;
import java.text.*;
import java.util.*;

public class PList {
  private static String parseValue(String data) {
    int i = data.indexOf('>');
    int j = i+1;
    while (data.charAt(j) != '<') ++j;
    return convertXML(data.substring(i+1, j));
  }

  private static List readArray(BufferedReader reader) throws IOException {
    List array = new ArrayList(100);
    while (true) {
      String line = reader.readLine();
      if (line == null) break;
      if (line.indexOf("</array>") >= 0) break;
      if (line.indexOf("<string>") >= 0) {
        array.add(parseValue(line));
      } else if (line.indexOf("<integer>") >= 0) {
        array.add(new Integer(parseValue(line)));
      } else if (line.indexOf("<true/>") >= 0) {
        array.add(Boolean.TRUE);
      } else if (line.indexOf("<false/>") >= 0) {
        array.add(Boolean.FALSE);
      } else if (line.indexOf("<array>") >= 0) {
        array.add(readArray(reader));
      } else if (line.indexOf("<dict>") >= 0) {
        array.add(readDict(reader));
      }
    }
    return array;
  }

  private static Map readDict(BufferedReader reader) throws IOException {
    Map dict = new HashMap(1000);
    while (true) {
      String line = reader.readLine();
      if (line == null) break;
      if (line.indexOf("</dict>") >= 0) break;
      if (line.indexOf("<key>") >= 0) {
        String key = parseValue(line);
        line = reader.readLine();
        if (line.indexOf("<string>") >= 0) {
          dict.put(key, parseValue(line));
        } else if (line.indexOf("<integer>") >= 0) {
          dict.put(key, new Integer(parseValue(line)));
        } else if (line.indexOf("<true/>") >= 0) {
          dict.put(key, Boolean.TRUE);
        } else if (line.indexOf("<false/>") >= 0) {
          dict.put(key, Boolean.FALSE);
        } else if (line.indexOf("<array>") >= 0) {
          dict.put(key, readArray(reader));
        } else if (line.indexOf("<dict>") >= 0) {
          dict.put(key, readDict(reader));
        }
      }
    }
    return dict;
  }

  static boolean isBinary(String filename) {
    InputStream fin = null;
    try {
      fin = new FileInputStream(filename);
      if (fin.read() != 'b') return false;
      if (fin.read() != 'p') return false;
      if (fin.read() != 'l') return false;
      if (fin.read() != 'i') return false;
      if (fin.read() != 's') return false;
      return (fin.read() == 't');
    } catch (IOException ioe) {
      return false;
    } finally {
      if (fin != null) {
        try { fin.close(); } catch (IOException ioe) {}
      }
    }
  }
  
  static Map readPListFile(String filename) throws IOException {
    if (!filename.endsWith(".plist")) return null;
    String tmpFile = null;
    String inputFile = filename;
    if (isBinary(inputFile)) {
      tmpFile = inputFile.substring(0, inputFile.length()-6) + "-tmp.plist";
      FileUtilities.copy(inputFile, tmpFile);
      ProcessUtils.exec("plutil -convert xml1 " + tmpFile);
      inputFile = tmpFile;
    }
    BufferedReader reader = null;
    try {
      reader = new BufferedReader(new InputStreamReader(new FileInputStream(inputFile), "UTF8"));
      while (true) {
        String line = reader.readLine();
        if (line == null) break;
        if (line.indexOf("<dict>") >= 0) break;
      }
      Map map = readDict(reader);
      return map;
    } finally {
      try {
        if (reader != null) reader.close();
      } catch (IOException ioe) {
        if (tmpFile != null) FileUtilities.delete(tmpFile);
        throw ioe;
      }
      if (tmpFile != null) FileUtilities.delete(tmpFile);
    }
  }

  private static String depth(int d, String s) {
    StringBuffer b = new StringBuffer(2*d+s.length());
    for (int i = 0; i < d; ++i) {
      b.append("  ");
    }
    b.append(s);
    return b.toString();
  }

  private static String convertXML(String text) {
    text = replace(text, "&quot;", "\"");
    text = replace(text, "&apos;", "\'");
    text = replace(text, "&amp;", "&");
    return text;
  }
  
  private static String convertToXML(String text) {
    if (text.equals("&")) return "&amp;";
    return replace(text, " & ", " &amp; ");
  }

  private static void writeArray(BufferedWriter writer, List plist, int depth) throws IOException {
    writer.write(depth(depth, "<array>\n"));
    ++depth;
    Iterator i = plist.iterator();
    while (i.hasNext()) {
      Object o = i.next();
      if (o instanceof List) {
        writeArray(writer, (List)o, depth+1);
      } else if (o instanceof Map) {
        writeDict(writer, (Map)o, depth+1);
      } else if (o instanceof String) {
        writer.write(depth(depth, "<string>"));
        writer.write(convertToXML((String)o));
        writer.write("</string>\n");
      } else if (o instanceof Integer) {
        writer.write(depth(depth, "<integer>"));
        writer.write(((Integer)o).toString());
        writer.write("</integer>\n");
      } else if (o instanceof Boolean) {
        if (Boolean.TRUE.equals(o)) {
          writer.write(depth(depth, "<true/>\n"));
        } else {
          writer.write(depth(depth, "<false/>\n"));
        }
      }
    }
    --depth;
    writer.write(depth(depth, "</array>\n"));
  }
  
  private static void writeDict(BufferedWriter writer, Map plist, int depth) throws IOException {
    writer.write(depth(depth, "<dict>\n"));
    ++depth;
    Iterator i = plist.keySet().iterator();
    while (i.hasNext()) {
      Object key = i.next();
      writer.write(depth(depth, "<key>"));
      writer.write(convertToXML((String)key));
      writer.write("</key>\n");
      Object o = plist.get(key);
      if (o instanceof List) {
        writeArray(writer, (List)o, depth+1);
      } else if (o instanceof Map) {
        writeDict(writer, (Map)o, depth+1);
      } else if (o instanceof String) {
        writer.write(depth(depth, "<string>"));
        writer.write(convertToXML((String)o));
        writer.write("</string>\n");
      } else if (o instanceof Integer) {
        writer.write(depth(depth, "<integer>"));
        writer.write(((Integer)o).toString());
        writer.write("</integer>\n");
      } else if (o instanceof Boolean) {
        if (Boolean.TRUE.equals(o)) {
          writer.write(depth(depth, "<true/>\n"));
        } else {
          writer.write(depth(depth, "<false/>\n"));
        }
      }
    }
    --depth;
    writer.write(depth(depth, "</dict>\n"));
  }

  static void writePListFile(String filename, Map plist) throws IOException {
    BufferedWriter writer = null;
    try {
      writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(filename), "UTF8"));
      writer.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
      writer.write("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
      writer.write("<plist version=\"1.0\">\n");
      writeDict(writer, plist, 0);
      writer.write("</plist>");
    } finally {
      if (writer != null) writer.close();
      ProcessUtils.exec("plutil -convert binary1 " + filename);
    }
  }

  /**
   *  Replaces indicated characters with other characters.
   *  @param text string where characters should be replaced
   *  @param oldCharacters the character to be replaced by <code>newCharacters</code>.
   *  @param newCharacters the character replacing <code>oldCharacters</code>.
   *  @return replaced string.
   **/
  public static String replace(String text, String oldCharacters, String newCharacters) {
    final int l = oldCharacters.length();
    if (l > 0) {
      StringBuffer buffer = new StringBuffer(Math.max(10, text.length()+2*(newCharacters.length()-l)));
      int i = 0;
      for (int j = 0;; i = j+l) {
        j = text.indexOf(oldCharacters, i);
        if (j == -1) {
          break;
        }
        buffer.append(text.substring(i, j));
        buffer.append(newCharacters);
      }
      buffer.append(text.substring(i));
      text = buffer.toString();
    }
    return text;
  }
}
