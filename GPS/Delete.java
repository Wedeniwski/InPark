import java.io.*;
import java.util.*;

public class Delete {
  public static void main(String[] args) {
    // java -cp GPS.jar Delete 1301465378
    try {
      // FTP
      FTP ftp = new FTP();
      ftp.connect(FTPCredentials.connect);
      ftp.login(FTPCredentials.user, FTPCredentials.password);
      ftp.cd(FTPCredentials.path);
      ftp.cd("data");
      ftp.setMode(FTP.MODE_BINARY);
      List<String> packages = new ArrayList<String>(10);
      String oldestPackage = null;
      if (args == null || args.length == 0) {
        List<String> files = ftp.dir();
        for (String file : files) {
          if (file.startsWith("inpark_") && file.endsWith(".info")) {
            int idx = file.indexOf('.');
            if (idx > 7) packages.add(file.substring(7, idx));
          }
        }
        if (packages.size() > 0) {
          Collections.sort(packages);
          oldestPackage = packages.get(packages.size()-1);
        }
      } else {
        oldestPackage = args[0];
      }
      if (oldestPackage != null) {
        List<String> currentEntries = CreateDownloads.parseCurrentUpdateFile("../data/inpark_" + oldestPackage + ".info");
        if (packages.size() > 1) currentEntries.addAll(CreateDownloads.parseCurrentUpdateFile("../data/inpark_" + packages.get(packages.size()-2) + ".info"));
        for (String pckg : packages) {
          boolean contains = false;
          for (String entry : currentEntries) {
            if (entry.indexOf(pckg) >= 0) {
              contains = true;
              break;
            }
          }
          if (!contains) {
            System.out.println("Delete package " + pckg + " on server");
            List<String> files = ftp.dir();
            for (String file : files) {
              if (file.indexOf(pckg) >= 0) {
                try {
                  ftp.deleteFile(file);
                } catch (IOException ioe) {
                  ioe.printStackTrace();
                  Thread.currentThread().sleep(500);
                  ftp.disconnect();
                  ftp.connect(FTPCredentials.connect);
                  ftp.login(FTPCredentials.user, FTPCredentials.password);
                  ftp.cd(FTPCredentials.path);
                  ftp.cd("data");
                  ftp.setMode(FTP.MODE_BINARY);
                }
              }
            }
            System.out.println("Delete local package " + pckg);
            File localFile = new File("../data");
            File[] localFiles = localFile.listFiles();
            for (int i = 0; i < localFiles.length; ++i) {
              if (localFiles[i].getName().indexOf(pckg) >= 0) {
                localFiles[i].delete();
              }
            }
          }
        }
      }
      ftp.disconnect();
    } catch (Throwable t) {
      t.printStackTrace();
    }
  }
}
