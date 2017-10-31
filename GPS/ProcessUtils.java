import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintStream;

/**
 *  Provides process utilities.
 *
 *  @version 1.8.6, July 4, 2003
**/
public class ProcessUtils {
  /**
   *  Executes the specified string command in a separate process and
   *  causes the current thread to wait, if necessary, until the process represented by this Process object has terminated.
   *  @param command a specified system command
   *  @return the exit value of the process. By convention, 0 indicates normal termination and -1 indicates an exception
  **/
  public static int exec(String command) {
    return exec(command, null, null, false, 0);
  }

  /**
   *  Executes the specified string command in a separate process and
   *  causes the current thread to wait, if necessary, until the process represented by this Process object has terminated.
   *  @param command a specified system command
   *  @param out the standard output of the running process will be transferred to the specified writer
   *  @param autoFlush if <code>true</code>, the output buffer will be flushed whenever a byte array is written, one of the
   *                   println methods is invoked, or a newline character or byte ('\n') is written
   *  @return the exit value of the process. By convention, 0 indicates normal termination and -1 indicates an exception
  **/
  public static int exec(String command, OutputStream out, boolean autoFlush) {
    return exec(command, out, null, autoFlush, 0);
  }

  /**
   *  Executes the specified string command in a separate process and
   *  causes the current thread to wait, if necessary, until the process represented by this Process object has terminated.
   *  @param command a specified system command
   *  @param out the standard output of the running process will be transferred to the specified writer
   *  @param autoFlush if <code>true</code>, the output buffer will be flushed whenever a byte array is written, one of the
   *                   println methods is invoked, or a newline character or byte ('\n') is written
   *  @param timeout the process will be destroyed if the process runs longer than the specified time (in milliseconds) 
   *  @return the exit value of the process. By convention, 0 indicates normal termination and -1 indicates an exception
  **/
  public static int exec(String command, OutputStream out, boolean autoFlush, int timeout) {
    return exec(command, out, null, autoFlush, timeout);
  }

  /**
   *  Executes the specified string command in a separate process and
   *  causes the current thread to wait, if necessary, until the process represented by this Process object has terminated.
   *  @param command a specified system command
   *  @param out the standard output of the running process will be transferred to the specified writer
   *  @param error the error output of the running process will be transferred to the specified writer
   *  @param autoFlush if <code>true</code>, the output buffer will be flushed whenever a byte array is written, one of the
   *                   println methods is invoked, or a newline character or byte ('\n') is written
   *  @param timeout the process will be destroyed if the process runs longer than the specified time (in milliseconds) 
   *  @return the exit value of the process. By convention, 0 indicates normal termination and -1 indicates an exception
  **/
  public static int exec(String command, OutputStream out, final OutputStream error, final boolean autoFlush, final int timeout) {
    int result = -1;
    BufferedReader reader = null;
    try {
      final Process process = Runtime.getRuntime().exec(command);
      if (timeout > 0) {
        Thread destroyProcess = new Thread() {
          public void run() {
            try {
              sleep(timeout);
            } catch (InterruptedException ie) {
            } finally {
              process.destroy();
            }
          }
        };
        destroyProcess.start();
      }
      if (error != null) {
        Thread t = new Thread() {
          public void run() {
            BufferedReader errorReader = null;
            try {
              errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
              PrintStream pout = (error == null)? null : new PrintStream(error, autoFlush);
              while (true) {
                String line = errorReader.readLine();
                if (line == null) {
                  break;
                }
                if (pout != null) {
                  pout.println(line);
                }
              }
            } catch (IOException ioe) {
            } finally {
              try {
                if (errorReader != null) errorReader.close();
              } catch (IOException ioe) {}
            }
          }
        };
        t.start();
      }
      reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
      PrintStream pout = (out == null)? null : new PrintStream(out, autoFlush);
      while (true) {
        String line = reader.readLine();
        if (line == null) {
          break;
        }
        if (pout != null) {
          pout.println(line);
        }
      }
      result = process.waitFor();
    } catch (InterruptedException ie) {
    } catch (IOException ioe) {
    } finally {
      try {
        if (reader != null) reader.close();
      } catch (IOException ioe) {}
    }
    return result;
  }
}
