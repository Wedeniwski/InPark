import java.io.*;
import java.util.*;
import java.util.zip.*;

public class InfoUpload {
  static void upload(String parkId, String languageId, String[] info) {
    boolean error = false;
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream(100000);
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("data");
      List<String> dir = ftp.dir();
      if (!dir.contains(parkId)) ftp.makeDir(parkId);
      ftp.cd(parkId);
      dir = ftp.dir();
      if (!dir.contains(languageId)) ftp.makeDir(languageId);
      ftp.cd(languageId);
      ftp.setMode(FTP.MODE_BINARY);
      dir = ftp.dir();
      List<String> files = ftp.longDir();
      // ToDo: reuse function from EditorUpload
      for (String infoFile : info) {
        if (infoFile.startsWith(".")) continue;
        String path = "../data/" + parkId + '/' + languageId + '/' + infoFile;
        do {
          try {
            boolean found = false;
            error = false;
            if (!dir.contains(infoFile)) {
              found = true;
              System.out.println("Upload: " + path);
            } else {
              for (String line : files) {
                if (line.endsWith(infoFile)) {
                  found = true;
                  // -rw-rw-rw-   1 p8049715 ftpusers    94157 May 19 20:00 ep - s01 - haupteingang.jpg
                  int i = line.indexOf("ftpusers");
                  if (i < 0) throw new IOException("Line '" + line + "' cannot be parsed!");
                  i += 8;
                  while (line.charAt(i) == ' ') ++i;
                  int j = line.indexOf(' ', i);
                  long size = Long.parseLong(line.substring(i, j));
                  File f = new File(path);
                  long localSize = f.length();
                  if (localSize != size) System.out.println("Info " + infoFile + " has local (" + localSize + ") a different file size as on server (" + size + ')');
                  else path = null;
                  break;
                }
              }
              if (!found) System.out.println("Info " + infoFile + " could not be found on server");
            }
            if (found && path != null) {
              out.reset();
              FileUtilities.writeData(new FileInputStream(path), new GZIPOutputStream(out), true, true);
              ftp.put(new ByteArrayInputStream(out.toByteArray()), infoFile + ".gz", FTP.MODE_BINARY);
              ftp.put(path, infoFile, FTP.MODE_BINARY);
            }
          } catch (IOException ioe) {
            error = true;
            System.out.println("socket error (" + ioe.getMessage() + ") - retry actions for " + path);
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
            ftp.cd(languageId);
          }
        } while (error);
      }
      ftp.disconnect();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  // java -cp GPS.jar InfoUpload
  public static void main(String[] args) {
    File f = new File("../data");
    String[] files = f.list();
    for (int i = 0; i < files.length; ++i) {
      String parkId = files[i];
      if (!parkId.endsWith(".lproj")) {
        f = new File("../data/" + parkId);
        if (f.exists() && f.isDirectory()) {
          System.out.println("***** PARK: " + parkId);
          f = new File("../data/" + parkId + "/de.lproj");
          if (f.exists() && f.isDirectory()) upload(parkId, "de.lproj", f.list());
          f = new File("../data/" + parkId + "/en.lproj");
          if (f.exists() && f.isDirectory()) upload(parkId, "en.lproj", f.list());
        }
      }
    }
  }
}
