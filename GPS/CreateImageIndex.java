import java.io.*;
import java.util.*;
import java.util.zip.*;

class ImageProperty {
  public String imageName;
  public int size;
  public long timestamp;
}

public class CreateImageIndex {
  public static void bzip2CompressData(InputStream in, OutputStream out) throws IOException {
    Bzip2OutputStream bzout = null;
    try {
      out.write('B');
      out.write('Z');
      int ch = in.read();
      if (ch != -1) { // Bug if file size equal to 0
        bzout = new Bzip2OutputStream(out);
        do {
          bzout.write(ch);
          ch = in.read();
        } while (ch != -1);
        bzout.flush();
      }
    } finally {
      in.close();
      if (bzout != null) bzout.close();
      out.close();
    }
  }

  public static void bzip2UncompressData(InputStream in, OutputStream out) throws IOException {
    BufferedInputStream bin = null;
    Bzip2InputStream bzin = null;
    try {
      bin = new BufferedInputStream(in, 4*1024);
      if (bin.read() != 'B' || bin.read() != 'Z') {
        return;
      }
      bzin = new Bzip2InputStream(bin);
      for (int ch = bzin.read(); ch != -1; ch = bzin.read()) {
        out.write(ch);
      }
      out.flush();
    } finally {
      bzin.close();
      in.close();
      out.close();
    }
  }

  static List<String> parse(String dirContent) {
    StringTokenizer tokens = new StringTokenizer(dirContent, "\r\n");
    List<String> array = new ArrayList(tokens.countTokens());
    while (tokens.hasMoreTokens()) {
      String s = tokens.nextToken();
      if (s.length() > 0) array.add(s);
    }
    return array;
  }

  static Map<String, Map<String, List<ImageProperty> > > parseData(String data) {
    Map<String, Map<String, List<ImageProperty> > > indexData = new HashMap<String, Map<String, List<ImageProperty> > >(10);
    String line = null;
    StringTokenizer tokens = new StringTokenizer(data, "\r\n");
    while (tokens.hasMoreTokens()) {
      String parkId = (line != null)? line : tokens.nextToken();
      line = null;
      if (parkId == null || parkId.length() == 0) break;
      //System.out.println("Parsing park " + parkId);
      Map<String, List<ImageProperty> > parkData = new HashMap<String, List<ImageProperty> >(200);
      while (tokens.hasMoreTokens()) {
        String attractionId = (line != null)? line : tokens.nextToken();
        if (attractionId != null) {
          if (attractionId.endsWith(".jpg") || attractionId.indexOf(',') > 0) {
            line = null;
            continue;
          }
          if (data.indexOf("\n\n" + attractionId + '\n') >= 0) {
            line = attractionId;
            break;
          }
        }
        line = null;
        if (attractionId.length() == 0) break;
        List<ImageProperty> images = new ArrayList<ImageProperty>(3);
        while (tokens.hasMoreTokens()) {
          line = tokens.nextToken();
          int n = line.indexOf(',');
          if (n < 0) break;
          int n2 = line.indexOf(',', n+1);
          if (n2 < 0) break;
          ImageProperty image = new ImageProperty();
          image.timestamp = Long.parseLong(line.substring(0, n));
          image.size = Integer.parseInt(line.substring(n+1, n2));
          image.imageName = line.substring(n2+1);
          if (image.imageName.indexOf(" - " + attractionId + " - ") > 0 && image.imageName.endsWith(".jpg")) images.add(image);
        }
        parkData.put(attractionId, images);
      }
      indexData.put(parkId, parkData);
    }
    return indexData;
  }

  static String getLine(String filename, List<String> list) {
    filename = " " + filename;
    for (String line : list) {
      if (line.endsWith(filename)) return line;
    }
    return null;
  }

  static long getTimestamp(String date) {
    final String month[] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
    for (int i = 0; i < month.length; ++i) {
      if (date.startsWith(month[i])) {
        Calendar calendar = Calendar.getInstance();
        int year = calendar.get(Calendar.YEAR);
        int day = date.charAt(5)-'0';
        char c = date.charAt(4);
        if (c != ' ') day += 10*(c-'0');
        int hourOfDay = 0;
        int minute = 0;
        if (date.charAt(9) == ':') {
          hourOfDay = 10*(date.charAt(7)-'0') + (date.charAt(8)-'0');
          minute = 10*(date.charAt(10)-'0') + (date.charAt(11)-'0');
        } else {
          year = Integer.parseInt(date.substring(8, 12));
        }
        calendar.set(year, i, day, hourOfDay, minute);
        calendar.set(calendar.SECOND, 0);
        calendar.set(calendar.MILLISECOND, 0);
        if (calendar.getTime().getTime() > System.currentTimeMillis()) calendar.set(calendar.YEAR, year-1);
        //System.out.println("DEBUG Date: "+date);
        //System.out.println("DEBUG Calendar: "+calendar.getTime());
        //System.exit(1);
        return calendar.getTime().getTime();
      }
    }
    return -1;
  }

  static long getTimestamp(String filename, String line) throws IOException {
    //System.out.println("timestamp line: " + line);
    int i = line.indexOf("ftpusers");
    if (i < 0) throw new IOException("Line '" + line + "' cannot be parsed!");
    i += 8;
    while (line.charAt(i) == ' ') ++i;
    int j = line.indexOf(' ', i);
    i = line.length()-filename.length();
    long timestamp = getTimestamp(line.substring(j+1, i));
    if (timestamp < 0) throw new IOException("Date of line '" + line + "' cannot be parsed!");
    return timestamp;
  }
  
  static long getTimestamp(String filename, List<String> allFiles) throws Exception {
    String line = getLine(filename, allFiles);
    if (line == null) throw new IOException("Missing file '" + filename + "'");
    try {
      return getTimestamp(filename, line);
    } catch (Exception e) {
      System.out.println("Error line: " + line);
      throw e;
    }
  }

  static String toString(List<ImageProperty> data) {
    StringBuilder sb = new StringBuilder(20*data.size());
    for (ImageProperty image : data) {
      sb.append(image.timestamp);
      sb.append(',');
      sb.append(image.size);
      sb.append(',');
      sb.append(image.imageName);
      sb.append('\n');
    }
    return sb.toString();
  }

  static String toString(Map<String, List<ImageProperty> > data) {
    StringBuilder sb = new StringBuilder(100*data.size());
    for (String attractionId : data.keySet()) {
      List<ImageProperty> list = data.get(attractionId);
      sb.append(attractionId);
      sb.append('\n');
      sb.append(toString(list));
    }
    return sb.toString();
  }
  
  static void createIndex(boolean checkIfCompleteRefreshNeeded) {
    try {
      System.out.println("Now: " + new Date(System.currentTimeMillis()));
      if (checkIfCompleteRefreshNeeded) System.out.println("check complete content on attraction level");
      int numberOfImages = 0;
      int numberOfUpdatedImages = 0;
      ByteArrayOutputStream allImages = new ByteArrayOutputStream(100000);
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("data");
      ftp.setMode(FTP.MODE_BINARY);
      Map<String, Map<String, List<ImageProperty> > > currentIndexInfo = null;
      ByteArrayOutputStream output = new ByteArrayOutputStream(800000);
      long indexInfoTimestamp = 0;
      List<String> allFiles = ftp.longDir();
      String indexInfo = getLine("index.info", allFiles);
      if (indexInfo == null) System.out.println("File 'index.info' missing.");
      else {
        indexInfoTimestamp = getTimestamp("index.info", indexInfo);
        if (indexInfoTimestamp < 0) System.out.println("Date of index info line '" + indexInfo + "' cannot be parsed!");
        System.out.println("Downloading 'index.info' with timestamp: " + new Date(indexInfoTimestamp));
        ftp.get("index.info", output, FTP.MODE_BINARY);
        System.out.println("Uncompressing and parsing 'index.info'");
        bzip2UncompressData(new ByteArrayInputStream(output.toByteArray()), allImages);
        allImages.close();
        currentIndexInfo = parseData(allImages.toString());
        if (currentIndexInfo != null) System.out.println("Data parsed for " + currentIndexInfo.size() + " park IDs");
        else System.out.println("Data cannot be parsed");
        allImages.reset();
      }
      List<String> dirParkIds = ftp.longDir();
      List<String> parkIds = ftp.dir();
      boolean first = true;
      for (String parkId : parkIds) {
        if (parkId.indexOf('.') >= 0) continue;
        String s = (first)? parkId + '\n' : "\n" + parkId + '\n';
        allImages.write(s.getBytes());
        first = false;
        long timestamp = getTimestamp(parkId, dirParkIds);
        int n = numberOfImages;
        Map<String, List<ImageProperty> > parkData = (currentIndexInfo != null)? currentIndexInfo.get(parkId) : null;
        /*if (parkData != null && timestamp < indexInfoTimestamp) {
          System.out.println("No image updates for park " + parkId + " because of timestamp " + timestamp);
          allImages.write(toString(parkData).getBytes());
          for (String attractionId : parkData.keySet()) {
            numberOfImages += parkData.get(attractionId).size();
          }
        } else {*/
        File file = new File("../data/" + parkId + '/' + parkId + ".plist");
        if (!file.exists()) {
          System.out.println("Error park " + parkId + " (" + new Date(timestamp) + ") cannot be scanned because local plist file not exist!");
          continue;
        }
          System.out.println("Scan park " + parkId + " (" + new Date(timestamp) + ')');
          ftp.cd(parkId);
          Map plist = PList.readPListFile("../data/" + parkId + '/' + parkId + ".plist");
          if (plist == null) System.out.println("missing plist for " + parkId);
          Map plistAttractionIds = (Map)plist.get("IDs");
          List<String> dirAttractionIds = ftp.longDir();
          List<String> attractionIds = ftp.dir();
          for (String attractionId : attractionIds) {
            if (attractionId.startsWith(".") || attractionId.endsWith(".txt") || attractionId.endsWith(".bz2") || attractionId.endsWith(".gz") || attractionId.endsWith(".lproj")) continue;
            if (plistAttractionIds.get(attractionId) == null) {
              System.out.println("attraction ID image folder " + attractionId + " not listed in " + parkId + ".plist and will be deleted");
              boolean error = false;
              do {
                try {
                  error = false;
                  if (ftp == null) {
                    ftp = new FTP();
                    ftp.connect(FTPCredentials.connect);
                    ftp.login(FTPCredentials.user, FTPCredentials.password);
                    ftp.setMode(FTP.MODE_BINARY);
                    ftp.cd(FTPCredentials.path);
                    ftp.cd("data");
                    ftp.cd(parkId);
                  }
                  ftp.cd(attractionId);
                  List<String> images = ftp.dir();
                  for (String imageName : images)
                    if (!imageName.startsWith(".")) ftp.deleteFile(imageName);
                  ftp.cd("..");
                  ftp.deleteDir(attractionId);
                } catch (IOException ioe) {
                  error = true;
                  System.out.println("socket error (" + ioe.getMessage() + ") - retry to delete folder " + attractionId);
                  try {
                    Thread.currentThread().sleep(1000);
                  } catch (InterruptedException ie) {}
                  ftp.disconnect();
                  ftp = null;
                }
              } while (error);
              continue;
            }
            timestamp = getTimestamp(attractionId, dirAttractionIds);
            List<ImageProperty> attractionData = (!checkIfCompleteRefreshNeeded && timestamp < indexInfoTimestamp && parkData != null)? parkData.get(attractionId) : null;
            //System.out.println("attractionData: " + attractionData + ", attractionId: " + attractionId);
            if (attractionData != null) {
              s = attractionId + '\n' + toString(attractionData);
              allImages.write(s.getBytes());
              numberOfImages += attractionData.size();
            } else {
              s = attractionId + '\n';
              allImages.write(s.getBytes());
              List<String> imagesInFolder = null;
              boolean error = false;
              do {
                try {
                  error = false;
                  if (ftp == null) {
                    ftp = new FTP();
                    ftp.connect(FTPCredentials.connect);
                    ftp.login(FTPCredentials.user, FTPCredentials.password);
                    ftp.setMode(FTP.MODE_BINARY);
                    ftp.cd(FTPCredentials.path);
                    ftp.cd("data");
                    ftp.cd(parkId);
                  }
                  ftp.cd(attractionId);
                  allFiles = ftp.longDir();
                  imagesInFolder = ftp.dir();
                  output.reset();
                  ftp.get(attractionId + ".txt", output, FTP.MODE_BINARY);
                } catch (IOException ioe) {
                  error = true;
                  System.out.println("socket error (" + ioe.getMessage() + ") - retry to download " + attractionId);
                  try {
                    Thread.currentThread().sleep(1000);
                  } catch (InterruptedException ie) {}
                  ftp.disconnect();
                  ftp = null;
                }
              } while (error);
              List<String> images = parse(output.toString());
              for (String imageInFolder : imagesInFolder) {
                if (!imageInFolder.startsWith(".") && !imageInFolder.endsWith(".txt") && !imageInFolder.endsWith(".zip") && !imageInFolder.endsWith(".bz2") && !imageInFolder.endsWith(".gz") && images.indexOf(imageInFolder) < 0)
                  System.out.println("Not linked file '" + imageInFolder + "' from folder at " + parkId + '/' + attractionId);
              }
              System.out.println("Update " + images.size() + " images for attraction " + attractionId + " (" + new Date(timestamp) + ')');
              //System.out.println(output.toString());
              //System.exit(1);
              long latestTimestamp = 0;
              for (String imageFilename : images) {
                String line = getLine(imageFilename, allFiles);
                if (line == null) System.out.println("Missing file '" + imageFilename + "' at " + parkId);
                else {
                  // -rw-rw-rw-   1 p8049715 ftpusers    94157 May 19 20:00 ep - s01 - haupteingang.jpg
                  int i = line.indexOf("ftpusers");
                  if (i < 0) throw new IOException("Line '" + line + "' cannot be parsed!");
                  i += 8;
                  while (line.charAt(i) == ' ') ++i;
                  int j = line.indexOf(' ', i);
                  long size = Long.parseLong(line.substring(i, j));
                  i = line.length()-imageFilename.length();
                  timestamp = getTimestamp(line.substring(j+1, i));
                  if (timestamp < 0) throw new IOException("Date of line '" + line + "' cannot be parsed!");
                  if (timestamp > latestTimestamp) latestTimestamp = timestamp;
                  s = Long.toString(timestamp) + ',' + size + ',' + imageFilename + '\n';
                  allImages.write(s.getBytes());
                  ++numberOfImages;
                  ++numberOfUpdatedImages;
                }
              }
              if (images.size() > 1) { // create ZIP container
                boolean refreshPackage = true;
                String line = getLine(attractionId + ".zip", allFiles);
                if (line == null) System.out.println("Missing zip package '" + attractionId + ".zip' at " + parkId);
                else {
                  int i = line.indexOf("ftpusers");
                  if (i < 0) throw new IOException("Line '" + line + "' cannot be parsed!");
                  i += 8;
                  while (line.charAt(i) == ' ') ++i;
                  int j = line.indexOf(' ', i);
                  i = line.length()-attractionId.length()-4;
                  refreshPackage = (latestTimestamp >= getTimestamp(line.substring(j+1, i)));
                }
                if (refreshPackage) {
                  System.out.println("Update zip package needed for " + attractionId);
                  ByteArrayOutputStream zipContent = new ByteArrayOutputStream(8000000);
                  do {
                    try {
                      error = false;
                      if (ftp == null) {
                        ftp = new FTP();
                        ftp.connect(FTPCredentials.connect);
                        ftp.login(FTPCredentials.user, FTPCredentials.password);
                        ftp.setMode(FTP.MODE_BINARY);
                        ftp.cd(FTPCredentials.path);
                        ftp.cd("data");
                        ftp.cd(parkId);
                        ftp.cd(attractionId);
                      }
                      zipContent.reset();
                      ZipOutputStream zipOut = new ZipOutputStream(zipContent);
                      zipOut.setLevel(9);
                      for (String imageFilename : images) {
                        output.reset();
                        ftp.get(imageFilename, output, FTP.MODE_BINARY);
                        zipOut.putNextEntry(new ZipEntry(imageFilename));
                        zipOut.write(output.toByteArray());
                        zipOut.closeEntry();
                      }
                      zipOut.close();
                      ftp.put(new ByteArrayInputStream(zipContent.toByteArray()), attractionId + ".zip", FTP.MODE_BINARY);
                    } catch (IOException ioe) {
                      error = true;
                      System.out.println("socket error (" + ioe.getMessage() + ") - retry to create and upload ZIP for " + attractionId);
                      try {
                        Thread.currentThread().sleep(1000);
                      } catch (InterruptedException ie) {}
                      ftp.disconnect();
                      ftp = null;
                    }
                  } while (error);
                }
              }
              ftp.cd("..");
            }
          }
          ftp.cd("..");
        //}
        System.out.println("Park " + parkId + " contains " + (numberOfImages-n) + " images");
      }
      allImages.close();
      ByteArrayOutputStream allImagesCompressed = new ByteArrayOutputStream(100000);
      bzip2CompressData(new ByteArrayInputStream(allImages.toByteArray()), allImagesCompressed);
      allImagesCompressed.close();
      try {
        ftp.put(new ByteArrayInputStream(allImagesCompressed.toByteArray()), "index2.info", FTP.MODE_BINARY);
        try {
          ftp.deleteFile("index.info");
        } catch (IOException ioe) {
          ioe.printStackTrace();
        }
        ftp.rename("index2.info", "index.info");
      } catch (IOException ioe) {
        ioe.printStackTrace();
        System.out.println("Store 'index.info' localy");
        FileOutputStream out = new FileOutputStream("index.info");
        out.write(allImagesCompressed.toByteArray());
        out.close();
      }
      ftp.disconnect();
      System.out.println("Index of all " + numberOfUpdatedImages + " (of " + numberOfImages + ") images successfully updated.");
      createVersionInfo();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  static void createVersionInfo() {
    try {
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("data");
      ftp.setMode(FTP.MODE_BINARY);
      List<String> allFiles = ftp.longDir();
      long timestamp1 = getTimestamp("inpark.info", allFiles);
      long timestamp2 = getTimestamp("index.info", allFiles);
      String s = Long.toString(timestamp1) + ',' + timestamp2;
      ByteArrayOutputStream result = new ByteArrayOutputStream(100);
      result.write(s.getBytes());
      result.close();
      ftp.put(new ByteArrayInputStream(result.toByteArray()), "version2.info", FTP.MODE_BINARY);
      try {
        ftp.deleteFile("version.info");
      } catch (IOException ioe) {
        ioe.printStackTrace();
      }
      ftp.rename("version2.info", "version.info");
      ftp.disconnect();
      System.out.println("Version info successfully updated (inpark.info: " + timestamp1 + ", index.info: " + timestamp2 + ')');
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  // java -cp GPS.jar CreateImageIndex
  public static void main(String[] args) {
    createIndex(args.length > 0);
    /*File f = new File("bilder");
    String[] files = f.list();
    for (int i = 0; i < files.length; ++i) {
      f = new File("bilder/" + files[i]);
      if (f.exists() && f.isDirectory()) {
        String parkId = files[i];
        File file = new File("../data/" + parkId);
        if (file.exists() && file.isDirectory()) {
          System.out.println("***** PARK: " + parkId);
          upload(parkId, f.list());
        }
      }
    }*/
  }
}
