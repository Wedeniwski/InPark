import java.io.*;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import java.util.zip.*;

class PackagesComparator implements Comparator<String> {
  String dataPath;

  public PackagesComparator(String dataPath) {
    this.dataPath = dataPath;
  }

  public int compare(String parkId1, String parkId2) {
    String[] t1 = CreateDownloads.getParkNameGroupCountry(dataPath, parkId1);
    String[] t2 = CreateDownloads.getParkNameGroupCountry(dataPath, parkId2);
    int c = t1[2].compareToIgnoreCase(t2[2]);
    if (c == 0) c = t1[0].compareToIgnoreCase(t2[0]);
    return c;
  }

  public boolean equals(Object obj) {
    return false;
  }
}

public class CreateDownloads {
  private static final String PLAIN_ASCII =
  "AaEeIiOoUu"    // grave
  + "AaEeIiOoUuYy"  // acute
  + "AaEeIiOoUuYy"  // circumflex
  + "AaOoNn"        // tilde
  + "AaEeIiOoUuYy"  // umlaut
  + "s"             // ß
  + "Aa"            // ring
  + "Cc"            // cedilla
  + "OoUu"          // double acute
  ;
  
  private static final String UNICODE =
  "\u00C0\u00E0\u00C8\u00E8\u00CC\u00EC\u00D2\u00F2\u00D9\u00F9"             
  + "\u00C1\u00E1\u00C9\u00E9\u00CD\u00ED\u00D3\u00F3\u00DA\u00FA\u00DD\u00FD" 
  + "\u00C2\u00E2\u00CA\u00EA\u00CE\u00EE\u00D4\u00F4\u00DB\u00FB\u0176\u0177" 
  + "\u00C3\u00E3\u00D5\u00F5\u00D1\u00F1"
  + "\u00C4\u00E4\u00CB\u00EB\u00CF\u00EF\u00D6\u00F6\u00DC\u00FC\u0178\u00FF" 
  + "\u00DF"
  + "\u00C5\u00E5"                                                             
  + "\u00C7\u00E7" 
  + "\u0150\u0151\u0170\u0171" 
  ;

  // remove accentued from a string and replace with ascii equivalent
  private static String removingAccents(String s) {
    if (s == null) return null;
    s = s.replace("Ä", "ae");
    s = s.replace("ä", "ae");
    s = s.replace("Ö", "oe");
    s = s.replace("ö", "oe");
    s = s.replace("Ü", "ue");
    s = s.replace("ü", "ue");
    s = s.replace("ß", "ss");
    s = s.replace("é", "e");
    int l = s.length();
    StringBuilder sb = new StringBuilder(l+10);
    for (int i = 0; i < l; ++i) {
      char c = s.charAt(i);
      int pos = UNICODE.indexOf(c);
      if (pos >= 0) {
        sb.append(PLAIN_ASCII.charAt(pos));
        if (pos >= 40 && pos <= 51) sb.append('e');
        else if (pos == 52) sb.append('s');
      } else {
        sb.append(Character.toLowerCase(c));
      }
    }
    return sb.toString();
  }

  private static String nameForView(String s) {
    return s.replace("&apos;", "'");
  }
  
  static String line(String parkId, String parkGroupId, String parkName, String country, long version, String path, long fileSize, String hashCode) {
    StringBuffer buffer = new StringBuffer(200);
    buffer.append(parkId);
    buffer.append(',');
    buffer.append(parkGroupId);
    buffer.append(',');
    buffer.append(parkName);
    buffer.append(',');
    buffer.append(country);
    buffer.append(',');
    buffer.append(version);
    buffer.append(',');
    buffer.append(path);
    buffer.append(',');
    buffer.append(fileSize);
    buffer.append(',');
    buffer.append(hashCode);
    return buffer.toString();
  }

  private static List<String> getPackages(String dataPath) {
    List<String> packages = new ArrayList(20);
    packages.add("core");
    File f = new File(dataPath);
		File[] files = f.listFiles();
    for (int i = 0; i < files.length; ++i) {
      if (files[i].isDirectory() && !files[i].getName().endsWith(".lproj")) {
        packages.add(files[i].getName());
      }
    }
    return packages;
  }

  static String[] getParkNameGroupCountry(String dataPath, String parkId) {
    if (parkId.equals("core")) return new String[] { "Core Data", "core", "core" };
    BufferedReader reader = null;
    String parkName = null;
    String parkGroup = null;
    String country = null;
    String filename = dataPath + '/' + parkId + '/' + parkId + ".plist";
    String tmpFile = dataPath + '/' + parkId + '/' + parkId + "-tmp.plist";
    try {
      FileUtilities.copy(filename, tmpFile);
      if (PList.isBinary(tmpFile)) ProcessUtils.exec("plutil -convert xml1 " + tmpFile);
      reader = new BufferedReader(new FileReader(tmpFile));
      while (true) {
        String line = reader.readLine();
        if (line == null) break;
        if (parkName == null && line.indexOf("<key>Parkname</key>") >= 0) {
          line = reader.readLine();
          parkName = nameForView(line.substring(line.indexOf('>')+1, line.indexOf("</")));
        }
        if (parkGroup == null && line.indexOf("<key>Parkgruppe</key>") >= 0) {
          line = reader.readLine();
          parkGroup = nameForView(line.substring(line.indexOf('>')+1, line.indexOf("</")));
        }
        if (country == null && line.indexOf("<key>Land</key>") >= 0) {
          line = reader.readLine();
          if (line.indexOf("<dict>") >= 0) {
            do {
              line = reader.readLine();
            } while (line.indexOf("<key>en</key>") < 0);
            line = reader.readLine();
          }
          country = line.substring(line.indexOf('>')+1, line.indexOf("</"));
        }
      }
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      try {
        if (reader != null) reader.close();
      } catch (IOException ioe) {
      }
      FileUtilities.delete(tmpFile);
    }
    return new String[] { parkName, parkGroup, country };
  }

  private static void normalizePackage(String dataPath, String parkId) {
    if (parkId.equals("core")) return;
    BufferedReader reader = null;
    BufferedWriter writer = null;
    boolean changed = false;
    String sourcePath = dataPath + '/' + parkId + '/' + parkId + ".plist";
    String tempPath = dataPath + '/' + parkId + "-tmp.plist"; // not in parkId path to avoid modification changes inside the path
    String tmpSourcePath = dataPath + '/' + parkId + '/' + parkId + "-tmp2.plist";
    try {
      FileUtilities.copy(sourcePath, tmpSourcePath);
      if (PList.isBinary(tmpSourcePath)) ProcessUtils.exec("plutil -convert xml1 " + tmpSourcePath);
      reader = new BufferedReader(new FileReader(tmpSourcePath));
      writer = new BufferedWriter(new FileWriter(tempPath));
      while (true) {
        String line = reader.readLine();
        if (line == null) break;
        if (line.indexOf("<key>Bild</key>") >= 0) {
          writer.write(line + '\n');
          line = reader.readLine();
          String name = line.substring(line.indexOf('>')+1, line.indexOf("</"));
          String filename = removingAccents(name);
          if (!filename.equals(name)) {
            System.out.println("Change plist entry " + name + " to " + filename);
            changed = true;
            writer.write("          <string>");
            writer.write(filename);
            writer.write("</string>\n");
          } else {
            writer.write(line + '\n');
          }
        } else if (line.indexOf("<key>WP") >= 0) {
          line = reader.readLine();
          if (line.indexOf("<dict>") >= 0) {
            for (int n = 0; n >= 0;) {
              line = reader.readLine();
              if (line.indexOf("<dict>") >= 0) ++n;
              else if (line.indexOf("</dict>") >= 0) --n;
            }
          }
          changed = true;
        } else {
          writer.write(line + '\n');
        }
      }
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      try {
        if (reader != null) reader.close();
        if (writer != null) writer.close();
      } catch (IOException ioe) {
      }
      new File(tmpSourcePath).delete();
    }
    if (changed) {
      new File(sourcePath).delete();
      new File(tempPath).renameTo(new File(sourcePath));
    } else {
      new File(tempPath).delete();
    }
  }

  private static void createPackage(String sourcePath, String targetPath, List<String> excludeDirectories) {
    ZipOutputStream fout = null;
    try {
      fout = new ZipOutputStream(new FileOutputStream(targetPath));
      fout.setLevel(9);
      addDirectory(fout, new File(sourcePath), "." + File.separator, excludeDirectories);
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      try {
        if (fout != null) fout.close();
      } catch (IOException ioe) {
      }
    }
  }
  
	private static boolean addDirectory(ZipOutputStream zout, File fileSource, String baseDirectory, List<String> excludeDirectories) throws IOException {
    boolean changed = false;
    byte[] buffer = new byte[4*8192];
		File[] files = fileSource.listFiles();
		for (int i = 0; i < files.length; ++i) {
      String sourceFilename = files[i].getName();
			if (files[i].isDirectory()) {
        if (excludeDirectories == null || excludeDirectories.indexOf(sourceFilename) < 0) {
          String dir = baseDirectory + sourceFilename + File.separator;
          zout.putNextEntry(new ZipEntry(dir));
          zout.closeEntry();
          changed |= addDirectory(zout, files[i], dir, excludeDirectories);
        }
      } else if (!sourceFilename.endsWith(".zip") && !sourceFilename.startsWith("inpark") && !sourceFilename.endsWith(".info") && !sourceFilename.startsWith(".")) {
        String filename = removingAccents(sourceFilename);
        if (!filename.equals(sourceFilename)) {
          File newFile = new File(files[i].getParent() + '/' + filename);
          System.out.println("Filename " + sourceFilename + " changed to " + newFile.getName());
          files[i].renameTo(newFile);
          files[i] = newFile;
          sourceFilename = files[i].getName();
          changed = true;
        }
        if (sourceFilename.endsWith(".plist") && !PList.isBinary(sourceFilename)) ProcessUtils.exec("plutil -convert binary1 " + sourceFilename);
				FileInputStream fin = new FileInputStream(files[i]);
				zout.putNextEntry(new ZipEntry(baseDirectory + filename));
        while (true) {
          int n = fin.read(buffer);
          if (n < 0) break;
          zout.write(buffer, 0, n);
        }
        zout.closeEntry();
        fin.close();
			}
		}
    return changed;
	}

  static List<String> parseCurrentUpdateFile(String infoPath) throws IOException {
    BufferedReader reader = null;
    List<String> entries = new ArrayList<String>(100);
    if (new File(infoPath).exists()) {
      try {
        reader = new BufferedReader(new FileReader(infoPath));
        while (true) {
          String line = reader.readLine();
          if (line == null) break;
          entries.add(line);
        }
      } finally {
        if (reader != null) reader.close();
      }
    }
    return entries;
  }

  static String matchToExistingEntry(List<String> currentEntries, String dataPath, String parkId, long packageSize, String hashCode) throws IOException {
    String contain = "," + Long.toString(packageSize) + ',';
    for (String line : currentEntries) {
      if (line.startsWith(parkId) /*&& line.endsWith(hashCode)*/ /*&& line.indexOf(contain) >= 0*/) {
        ZipInputStream in = null;
        try {
          int idx2 = line.lastIndexOf(',');
          idx2 = line.lastIndexOf(',', idx2-1);
          int idx1 = line.lastIndexOf(',', idx2-1);
          File file = new File(dataPath + '/' + line.substring(idx1+1, idx2) + ".zip");
          if (!file.exists()) return null;
          in = new ZipInputStream(new FileInputStream(file));
          while (true) {
            ZipEntry entry = in.getNextEntry();
            if (entry == null) break;
            String name = entry.getName();
            if (!name.startsWith("./.")) {
              String filename = dataPath + '/' + parkId + '/' + name;
              filename = filename.replace("/core/./", "/");
              File f = new File(filename);
              long size = entry.getSize();
              if (!f.isDirectory() && !FileUtilities.equals(in, filename)) {
                System.out.println("> content of " + name + " (" + size + ") not equal to file " + filename + " (" + f.length() + ')');
                return null;
              }
            }
          }
        } finally {
          if (in != null) in.close();
        }
        return line;
      }
    }
    return null;
  }

  static List<String> writeUpdateFile(String dataPath, String suffix) throws IOException, NoSuchAlgorithmException {
    List<String> updates = new ArrayList<String>(10);
    List<String> currentEntries = parseCurrentUpdateFile(dataPath + "/inpark" + suffix + ".info");
    long version = System.currentTimeMillis()/1000;
    String filename = dataPath + "/inpark_" + version + suffix + ".info";
    String filename2 = dataPath + "/inpark" + suffix + ".info";
    BufferedWriter writer = null;
    BufferedWriter writer2 = null;
    try {
      writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(filename), "UTF8"));
      writer2 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(filename2), "UTF8"));
      List<String> packages = getPackages(dataPath);
      Collections.sort(packages, new PackagesComparator(dataPath)); // sort packages by countries
      for (String parkId : packages) {
        String[] t = getParkNameGroupCountry(dataPath, parkId);
        System.out.println("create package: " + t[0] + " (" + parkId + " / " + t[1] + ") - " + t[2]);
        String path = parkId + '_' + Long.toString(version);
        String packageName = dataPath + '/' + path + ".zip";
        if (parkId.equals("core")) {
          createPackage(dataPath, packageName, packages);
        } else {
          normalizePackage(dataPath, parkId);
          createPackage(dataPath + '/' + parkId, packageName, null);
        }
        File packageFile = new File(packageName);
        String hashCode = FileUtilities.hashCode(packageName);
        String existingEntry = matchToExistingEntry(currentEntries, dataPath, parkId, packageFile.length(), hashCode);
        if (existingEntry == null) {
          String s = line(parkId, t[1], t[0], t[2], version, path, packageFile.length(), hashCode);
          writer.write(s);
          writer2.write(s);
          updates.add(path);
        } else {
          writer.write(existingEntry);
          writer2.write(existingEntry);
          System.out.println(">no updates for " + parkId + ", " + packageName + ((packageFile.delete())? " successfully" : " NOT" ) + " deleted");
        }
        writer.write("\n");
        writer2.write("\n");
      }
    } finally {
      if (writer != null) writer.close();
      if (writer2 != null) writer2.close();
    }
    updates.add("inpark_" + version + suffix + ".info");
    return updates;
  }

  public static void main(String[] args) {
    // java -cp GPS.jar CreateDownloads
    List<String> updates = null;
    try {
      /*String dataPath = "../data/";
      String parkId = "usdcaca";
      String baseDirectory  = parkId + '/';
      String filename = parkId + ".plist";
      String sourceFilename = dataPath + baseDirectory + filename;
      byte[] buffer = new byte[4*8192];
      ZipOutputStream zout = new ZipOutputStream(new FileOutputStream("test.zip"));
      zout.setLevel(9);
      if (sourceFilename.endsWith(".plist") && !PList.isBinary(sourceFilename)) ProcessUtils.exec("plutil -convert binary1 " + sourceFilename);
      FileInputStream fin = new FileInputStream(sourceFilename);
      zout.putNextEntry(new ZipEntry(filename));
      while (true) {
        int n = fin.read(buffer);
        if (n < 0) break;
        zout.write(buffer, 0, n);
      }
      zout.closeEntry();
      fin.close();
      if (sourceFilename.endsWith(".plist") && !PList.isBinary(sourceFilename)) ProcessUtils.exec("plutil -convert binary1 " + sourceFilename);
      ZipInputStream in = new ZipInputStream(new FileInputStream("test.zip"));
      while (true) {
        ZipEntry entry = in.getNextEntry();
        if (entry == null) break;
        String name = entry.getName();
        if (!name.startsWith("./.")) {
          filename = dataPath + '/' + parkId + '/' + name;
          File f = new File(filename);
          long size = entry.getSize();
          if (!f.isDirectory() && !FileUtilities.equals(in, filename)) {
            System.out.println("> content of " + name + " (" + size + ") not equal to file " + filename + " (" + f.length() + ')');
          }
        }
      }
      System.exit(1);*/

      String suffix = (args.length > 0)? "." + args[0] : "";
      // create core package
      updates = writeUpdateFile("../data", suffix);
      // FTP
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("data");
      ftp.setMode(FTP.MODE_BINARY);
      for (String update : updates) {
        String updateFileName = (update.startsWith("inpark_"))? update : update + ".zip";
        String updateFilePath = "../data/" + updateFileName;
        File f = new File(updateFilePath);
        int error = 0;
        do {
          try {
            System.out.println("Upload " +  updateFileName + " (" + f.length()/1024 + " kB)");
            ftp.put(updateFilePath, updateFileName, FTP.MODE_BINARY);
            error = 0;
          } catch (IOException ioe) {
            System.out.println("Error uploading package " + update + ". Retry uploading this package.");
            ioe.printStackTrace();
            Thread.currentThread().sleep(500);
            ftp.disconnect();
            ++error;
            ftp.connect(FTPCredentials.connect);
            ftp.login(FTPCredentials.user, FTPCredentials.password);
            ftp.cd(FTPCredentials.path);
            ftp.setMode(FTP.MODE_BINARY);
            ftp.cd("data");
          }
        } while (error > 0);
      }
      int error = 0;
      do {
        try {
          ftp.put("../data/inpark" + suffix + ".info", "inpark2" + suffix + ".info", FTP.MODE_BINARY);
          error = 0;
        } catch (IOException ioe) {
          Thread.currentThread().sleep(500);
          ftp.disconnect();
          ++error;
          ftp.connect(FTPCredentials.connect);
          ftp.login(FTPCredentials.user, FTPCredentials.password);
          ftp.cd(FTPCredentials.path);
          ftp.setMode(FTP.MODE_BINARY);
          ftp.cd("data");
        }
      } while (error > 0);
      ftp.deleteFile("inpark" + suffix + ".info");
      ftp.rename("inpark2" + suffix + ".info", "inpark" + suffix + ".info");
      System.out.println("Updates are activated");
      ftp.disconnect();
      if (suffix.length() == 0) Delete.main(null);
      if (updates.size() > 2 || updates.size() == 2 && !updates.get(0).startsWith("core_")) {
        EditorUpload.uploadNewData();
        CreateImageIndex.createIndex(false);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}
