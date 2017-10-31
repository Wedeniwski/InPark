import java.io.*;
import java.util.*;

public class PListDownload {

  private static void download(FTP ftp, String source, String target, String[] ftpPath) {
    boolean error = false;
    do {
      try {
        error = false;
        ftp.get(source, target, FTP.MODE_BINARY);
        System.out.println("File " + source + " downloaded from server");
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
  }

  static void download(String parkId) {
    try {
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("editor");
      ftp.setMode(FTP.MODE_BINARY);
      if (parkId.equals("types.plist")) {
        String[] ftpPath = new String[]{"editor"};
        download(ftp, "types.plist", "../data/types.plist", ftpPath);
      } else {
        ftp.cd(parkId);
        String[] ftpPath = new String[]{"editor", parkId};
        download(ftp, parkId + ".plist", "../data/" + parkId + '/' + parkId + ".plist", ftpPath);
      }
      ftp.disconnect();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public static void downloadNewData() {
    File f = new File("../data");
    String[] files = f.list();
    download("types.plist");
    for (int i = 0; i < files.length; ++i) {
      String parkId = files[i];
      if (!parkId.endsWith(".lproj")) {
        f = new File("../data/" + parkId);
        if (f.exists() && f.isDirectory()) {
          f = new File("../data/" + parkId + '/' + parkId + ".plist");
          if (f.exists()) download(parkId);
        }
      }
    }
  }

  // java -cp GPS.jar PListDownload
  public static void main(String[] args) {
    downloadNewData();
  }
}
