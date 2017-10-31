import java.io.*;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;

public class FileUtilities {
  public static String hashCode(String filename) throws IOException, NoSuchAlgorithmException {
    MessageDigest digest = MessageDigest.getInstance("MD5");
    byte[] buffer = new byte[8192];
    InputStream fin = null;
    try {
      fin = new FileInputStream(filename);
      while (true) {
        int n = fin.read(buffer);
        if (n < 0) break;
        digest.update(buffer, 0, n);
      }
      byte[] md5sum = digest.digest();
      BigInteger bigInt = new BigInteger(1, md5sum);
      String hCode = bigInt.toString(16);
      while (hCode.length() < 32) hCode = "0" + hCode;
      return hCode;
    } finally {
      if (fin != null) fin.close();
		}
  }

  public static boolean equals(InputStream in, String filename) throws IOException {
    File f = new File(filename);
    if (!f.exists()) return false;
    if (f.isDirectory()) throw new IOException("Directories cannot be compared (" + filename + ")!");
    InputStream fin = null;
    try {
      fin = new BufferedInputStream(new FileInputStream(filename));
      if (!(in instanceof BufferedInputStream)) in = new BufferedInputStream(in);
      int ch = in.read();
      while (ch != -1) {
        int ch2 = fin.read();
        if (ch != ch2) return false;
        ch = in.read();
      }
      return (fin.read() == -1);
    } finally {
      if (fin != null) fin.close();
    }
    /*DataInputStream din = null;
    try {
      byte[] buffer1 = new byte[64 *1024];
      byte[] buffer2 = new byte[64 *1024];
      din = new DataInputStream(new FileInputStream(filename));
      while (true) {
        int n = in.read(buffer1);
        if (n < 0) break;
        System.out.println(filename + ", n="+n);
        din.readFully(buffer2, 0, n);
        for (int i = 0; i < n; ++i)
          if (buffer1[i] != buffer2[i]) {
            System.out.println(filename + ", i="+i+", n="+n);
            System.out.println(buffer1[i-1] + ", "+buffer2[i-1]);
            System.out.println(buffer1[i] + ", "+buffer2[i]);
            System.out.println(buffer1[i+1] + ", "+buffer2[i+1]);
            System.exit(1);
            return false;
          }
      }
      return (din.read() < 0);
    } catch (EOFException ioe) {
      return false;
    } finally {
      if (din != null) din.close();
    }*/
  }
  
  /**
   *  Deletes the file or the whole directory denoted by this abstract pathname.
   *  @return <code>true</code> if and only if the file or directory is successfully deleted; false otherwise
   **/
  public static boolean delete(String pathname) {
    File file = new File(pathname);
    if (file.isDirectory()) {
      boolean result = true;
      File[] list = file.listFiles();
      if (list != null) {
        for (int i = 0; i < list.length; ++i) {
          result &= delete(list[i].getAbsolutePath());
        }
      }
      result &= file.delete();
      return result;
    } else {
      return file.delete();
    }
  }
  
  /**
   *  Move a file or a whole directory from a source path to a destination path.
   *  @param source source filename or directory
   *  @param source destination filename or directory
   *  @return <code>true</code> if and only if the file or directory is successfully moved; false otherwise
   **/
  public static boolean move(String source, String destination) {
    File file = new File(source);
    if (file.isDirectory()) {
      boolean result = new File(destination).mkdir();
      File[] list = file.listFiles();
      if (list != null) {
        for (int i = 0; i < list.length; ++i) {
          result &= list[i].renameTo(new File(destination + '/' + list[i].getName()));
        }
      }
      result &= new File(source).delete();
      return result;
    } else {
      return file.renameTo(new File(destination));
    }
  }

  /**
   *  Copy a file or a whole directory from a source path to a destination path.
   *  @param source source filename or directory
   *  @param source destination filename or directory
   *  @exception  IOException  if an I/O error occurs.
   **/
  public static void copy(String source, String destination) throws IOException {
    File file = new File(source);
    if (file.isDirectory()) {
      new File(destination).mkdir();
      File[] list = file.listFiles();
      if (list != null) {
        for (int i = 0; i < list.length; ++i) {
          copy(list[i].getAbsolutePath(), destination + '/' + list[i].getName());
        }
      }
    } else {
      writeData(new FileInputStream(file), new FileOutputStream(destination), true, true);
    }
  }
  
  /**
   *  Transfers the data from a specified input stream to an output stream.
   *  @param in   input stream
   *  @param out  output stream
   *  @param closeIn close input stream after the transfer if <code>true</code>.
   *  @param closeOut close output stream after the transfer if <code>true</code>.
   *  @return size of output stream.
   *  @exception  IOException  if an I/O error occurs.
   **/
  public static int writeData(InputStream in, OutputStream out, boolean closeIn, boolean closeOut) throws IOException {
    int size = 0;
    try {
      byte[] buffer = new byte[64 * 1024];
      while (true) {
        int n = in.read(buffer);
        if (n < 0) break;
        if (n > 0) {
          if (out != null) out.write(buffer, 0, n);
          size += n;
        }
      }
    } finally {
      if (closeIn) in.close();
      if (closeOut && out != null) out.close();
    }
    return size;
  }
  
  public static int writeData(Reader in, Writer out, boolean closeIn, boolean closeOut, int maxSize) throws IOException {
    int size = 0;
    try {
      char[] buffer = new char[64 * 1024];
      while (maxSize < 0 || size < maxSize) {
        /*if (!in.ready()) {
          try { Thread.sleep(100); } catch (InterruptedException ex) {}
          for (int i = 0; i < 3 && !in.ready(); ++i) try { Thread.sleep(100); } catch (InterruptedException ex) {}
        }*/
        int n = in.read(buffer);
        if (n < 0) break;
        if (maxSize >= 0 && size+n > maxSize) n = maxSize-size;
        if (n > 0) {
          if (out != null) out.write(buffer, 0, n);
          size += n;
        }
      }
    } catch (IOException ioe) {
      if (!ioe.getMessage().equals("Premature EOF")) throw ioe;
    } finally {
      if (closeIn) in.close();
      if (closeOut && out != null) out.close();
    }
    return size;
  }
  
}
