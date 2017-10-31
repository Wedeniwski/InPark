import java.awt.Dimension;
import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;

public class EditorUpload {
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

  private static void uploadOnlyIfNew(FTP ftp, String source, String target, String[] ftpPath) {
    List<String> dir = null;
    List<String> files = null;
    boolean error = false;
    do {
      try {
        error = false;
        dir = ftp.dir();
        files = ftp.longDir();
      } catch (IOException ioe) {
        error = true;
        System.out.println("socket error (" + ioe.getMessage() + ") - retry read dir");
        try {
          Thread.currentThread().sleep(1000);
          ftp.disconnect();
          ftp.connect(FTPCredentials.connect);
          ftp.login(FTPCredentials.user, FTPCredentials.password);
          ftp.setMode(FTP.MODE_BINARY);
          ftp.cd(FTPCredentials.path);
          for (String path : ftpPath) ftp.cd(path);
        } catch (Exception e) {}
      }
    } while (error);
    String tmpFile = null;
    if (source.endsWith(".plist")) {
      try {
        tmpFile = source.substring(0, source.length()-6) + "-tmp.plist";
        FileUtilities.copy(source, tmpFile);
        ProcessUtils.exec("plutil -convert xml1 " + tmpFile);
      } catch (IOException ioe) {
        ioe.printStackTrace();
      }
    }
    do {
      try {
        boolean found = false;
        error = false;
        if (!dir.contains(target)) {
          found = true;
        } else {
          for (String line : files) {
            if (line.endsWith(target)) {
              found = true;
              // -rw-rw-rw-   1 p8049715 ftpusers    94157 May 19 20:00 ep - s01 - haupteingang.jpg
              int i = line.indexOf("ftpusers");
              if (i < 0) throw new IOException("Line '" + line + "' cannot be parsed!");
              i += 8;
              while (line.charAt(i) == ' ') ++i;
              int j = line.indexOf(' ', i);
              long size = Long.parseLong(line.substring(i, j));
              File f = new File((tmpFile != null)? tmpFile : source);
              long localSize = f.length();
              if (localSize == size) target = null;
              break;
            }
          }
          if (!found) System.out.println("File " + target + " could not be found on server");
        }
        if (found && target != null) {
          ftp.put(new FileInputStream((tmpFile != null)? tmpFile : source), target, FTP.MODE_BINARY);
          System.out.println("File " + target + " uploaded on server");
        }
      } catch (IOException ioe) {
        error = true;
        System.out.println("socket error (" + ioe.getMessage() + ") - retry actions for " + target);
        try {
          Thread.currentThread().sleep(1000);
          ftp.disconnect();
          ftp.connect(FTPCredentials.connect);
          ftp.login(FTPCredentials.user, FTPCredentials.password);
          ftp.setMode(FTP.MODE_BINARY);
          ftp.cd(FTPCredentials.path);
          for (String path : ftpPath) ftp.cd(path);
        } catch (Exception e) {}
      }
    } while (error);
    if (tmpFile != null) FileUtilities.delete(tmpFile);
  }

  static void upload(String parkId, String[] images) {
    try {
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("editor");
      ftp.setMode(FTP.MODE_BINARY);
      if (parkId.equals("types.plist")) {
        String[] ftpPath = new String[]{"editor"};
        uploadOnlyIfNew(ftp, "../data/types.plist", "types.plist", ftpPath);
      } else {
        List<String> dir = ftp.dir();
        if (!dir.contains(parkId)) ftp.makeDir(parkId);
        ftp.cd(parkId);
        String[] ftpPath = new String[]{"editor", parkId};
        uploadOnlyIfNew(ftp, "../data/" + parkId + '/' + parkId + ".plist", parkId + ".plist", ftpPath);
        for (String image : images) {
          if (image.endsWith(".jpg")) {
            String path = "../data/" + parkId + '/' + image;
            Dimension d = getImageDimension(path);
            if (d != null && d.width > 200 && d.height > 200) {
              uploadOnlyIfNew(ftp, path, image, ftpPath);
            }
          }
        }
      }
      ftp.disconnect();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public static void uploadNewData() {
    File f = new File("../data");
    String[] files = f.list();
    f = new File("../data/types.plist");
    if (f.exists()) upload("types.plist", null);
    for (int i = 0; i < files.length; ++i) {
      String parkId = files[i];
      if (!parkId.endsWith(".lproj")) {
        f = new File("../data/" + parkId);
        if (f.exists() && f.isDirectory()) {
          System.out.println("***** PARK: " + parkId);
          String[] images = f.list();
          f = new File("../data/" + parkId + '/' + parkId + ".plist");
          if (f.exists()) upload(parkId, images);
        }
      }
    }
  }

  // java -cp GPS.jar PListDownload
  public static void main(String[] args) {
    uploadNewData();
  }
}
