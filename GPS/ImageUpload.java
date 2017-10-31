import java.awt.Dimension;
import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;

public class ImageUpload {
  private static Map attractionIds = null;
  private static String attractionIdsOfParkId = null;
  private static Dimension getImageDimension(String path) {
    final String suffix = "jpg";
    if (!path.endsWith("." + suffix)) return null;
    Dimension result = null;
    Iterator<ImageReader> iter = ImageIO.getImageReadersBySuffix(suffix);
    if (iter.hasNext()) {
      ImageReader reader = iter.next();
      try {
        ImageInputStream stream = new FileImageInputStream(new File(path));
        reader.setInput(stream);
        int width = reader.getWidth(reader.getMinIndex());
        int height = reader.getHeight(reader.getMinIndex());
        result = new Dimension(width, height);
      } catch (IOException e) {
        e.printStackTrace();
        return null;
      } finally {
        reader.dispose();
      }
    } else {
      System.out.println("No reader found for given format: " + suffix);
    }
    return result;
  }

  static Map getAttractionIds(String parkId) {
    if (attractionIds != null && parkId.equals(attractionIdsOfParkId)) return attractionIds;
    attractionIds = null;
    attractionIdsOfParkId = null;
    try {
      Map plist = PList.readPListFile("../data/" + parkId + '/' + parkId + ".plist");
      if (plist == null) System.out.println("Missing plist for " + parkId);
      else {
        attractionIds = (Map)plist.get("IDs");
        if (attractionIds == null) System.out.println("Missing IDs entry inside plist");
        else attractionIdsOfParkId = parkId;
      }
    } catch (IOException ioe) {
      ioe.printStackTrace();
    }
    return attractionIds;
  }

  static int upload(String parkId) {
    int updateImageIndex = 0;
    boolean error = false;
    try {
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("data");
      ftp.cd(parkId);
      ftp.setMode(FTP.MODE_BINARY);
      List<String> dir = ftp.dir();
      Set<String> allAttractionIds = getAttractionIds(parkId).keySet();
      for (String attractionId : allAttractionIds) {
        String image = (String)((Map)getAttractionIds(parkId).get(attractionId)).get("Bild");
        String path = "bilder/" + parkId + '/' + image;
        File file = new File(path);
        if (!file.exists()) continue;
        Dimension d = getImageDimension(path);
        //System.out.println(path + "  -  " + d);
        if (d != null && d.width > 200 && d.height > 200) {
          boolean retry = false;
          do {
            try {
              error = false;
              if (!dir.contains(attractionId)) {
                if (!retry) ftp.makeDir(attractionId);
                ftp.cd(attractionId);
                ftp.put(path, image, FTP.MODE_BINARY);
                ftp.put(new ByteArrayInputStream(image.getBytes()), attractionId + ".txt", FTP.MODE_BINARY);
                System.out.println("Uploaded (" + attractionId + "): " + image);
                if (updateImageIndex == 0) updateImageIndex = 1;
              } else {
                boolean found = false;
                ftp.cd(attractionId);
                List<String> files = ftp.longDir();
                for (String line : files) {
                  if (line.endsWith(image)) {
                    found = true;
                    File f = new File(path);
                    // -rw-rw-rw-   1 p8049715 ftpusers    94157 May 19 20:00 ep - s01 - haupteingang.jpg
                    int i = line.indexOf("ftpusers");
                    if (i < 0) throw new IOException("Line '" + line + "' cannot be parsed!");
                    i += 8;
                    while (line.charAt(i) == ' ') ++i;
                    int j = line.indexOf(' ', i);
                    long size = Long.parseLong(line.substring(i, j));
                    long localSize = f.length();
                    if (localSize != size) {
                      System.out.println("Image " + image + " has local (" + localSize + ") a different file size as on server (" + size + ')');
                      updateImageIndex = 2;
                      ftp.put(path, image, FTP.MODE_BINARY);
                    }
                  }
                }
                if (!found) {
                  System.out.println("Image " + image + " could not be found on server - save folder content and create new one");
                }
              }
              ftp.cd("..");
            } catch (IOException ioe) {
              retry = true;
              error = true;
              System.out.println("socket error (" + ioe.getMessage() + ") - retry actions for " + attractionId);
              try {
                Thread.currentThread().sleep(1000);
              } catch (InterruptedException ie) {}
              ftp.disconnect();
              ftp.connect(FTPCredentials.connect);
              ftp.login(FTPCredentials.user, FTPCredentials.password);
              ftp.setMode(FTP.MODE_BINARY);
              ftp.cd(FTPCredentials.path);
              ftp.cd("data");
              ftp.cd(parkId);
            }
          } while (error);
        }
      }
      ftp.disconnect();
      //Delete.main(null);
    } catch (Exception e) {
      e.printStackTrace();
    }
    return updateImageIndex;
  }

  // java -cp GPS.jar ImageUpload
  public static void main(String[] args) {
    int updateImageIndex = 0;
    if (args.length > 0) {
      String parkId = args[0];
      System.out.println("PARK: " + parkId);
      int u = upload(parkId);
      if (u == 2 || u == 1 && updateImageIndex == 0) updateImageIndex = u;
    } else {
      File f = new File("bilder");
      String[] files = f.list();
      for (int i = 0; i < files.length; ++i) {
        f = new File("bilder/" + files[i]);
        if (f.exists() && f.isDirectory()) {
          String parkId = files[i];
          File file = new File("../data/" + parkId);
          if (file.exists() && file.isDirectory()) {
            System.out.println("***** PARK: " + parkId);
            int u = upload(parkId);
            if (u == 2 || u == 1 && updateImageIndex == 0) updateImageIndex = u;
          }
        }
      }
    }
    if (updateImageIndex > 0) CreateImageIndex.createIndex(updateImageIndex > 1);
  }
}
