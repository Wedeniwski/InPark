import java.text.*;
import java.util.*;

public class WaitingTimesCrawler {
  static void trace(String text) {
    trace(text, true, true);
  }
  
  private static SimpleDateFormat formatter = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss ");
  static void trace(String text, boolean timestamp, boolean newLine) {
    text = text.replaceAll("[^\\x20-\\x7f]", "");
    if (timestamp) {
      if (newLine) {
        System.out.println(formatter.format(new Date()) + text);
      } else {
        System.out.print(formatter.format(new Date()) + text);
        System.out.flush();
      }
    } else {
      if (newLine) {
        System.out.println(text);
      } else {
        System.out.print(text);
        System.out.flush();
      }
    }
  }

  // java -Xmx500M -cp GPS.jar WaitingTimesCrawler
  public static void main(String args[]) {
    //final ParkDataParser[] parkDataParsers = { new UniversalHollywoodDataParser(), new UniversalDataParser("usuifl"), new UniversalDataParser("ususfl"), new DisneylandParisDataParser("fdlp"), new DisneylandParisDataParser("fdsp"), new EuropaParkDataParser(), new PhantasialandDataParser(), new HeideParkDataParser(), new MovieParkDataParser(), new EftelingDataParser(), new AltonTowersDataParser(), new DisneyCaliforniaDataParser("usdlca"), new DisneyCaliforniaDataParser("usdcaca"), new SeaWorldDataParser("usswofl"), new SeaWorldDataParser("usswsdca"), new WDWDataParser("usdmkfl"), new WDWDataParser("usdefl"), new WDWDataParser("usdakfl"), new WDWDataParser("usdhsfl") };
    final ParkDataParser[] parkDataParsers = { new UniversalHollywoodDataParser(), new UniversalDataParser("usuifl"), new UniversalDataParser("ususfl"), new DisneylandParisDataParser("fdlp"), new DisneylandParisDataParser("fdsp"), new EuropaParkDataParser(), new PhantasialandDataParser(), new HeideParkDataParser(), new MovieParkDataParser(), new EftelingDataParser(), new AltonTowersDataParser(), new SeaWorldDataParser("usswofl"), new SeaWorldDataParser("usswsdca") };
    //final ParkDataParser[] parkDataParsers = { new UniversalDataParser("ususfl"), new PhantasialandDataParser(), new HeideParkDataParser(), new MovieParkDataParser(), new EftelingDataParser(), new DisneyCaliforniaDataParser("usdlca"), new DisneyCaliforniaDataParser("usdcaca") };
    //final ParkDataParser[] parkDataParsers = { new WDWDataParser("usdmkfl"), new WDWDataParser("usdefl"), new WDWDataParser("usdakfl"), new WDWDataParser("usdhsfl") };
    //final ParkDataParser[] parkDataParsers = { new DisneyCaliforniaDataParser("usdlca"), new DisneyCaliforniaDataParser("usdcaca") };
    //final ParkDataParser[] parkDataParsers = { new DisneyCaliforniaDataParser("usdlca") };
    if (parkDataParsers.length == 1) {
      trace("start threat for 1 parser " + parkDataParsers[0].parserIdentifier());
      ParkDataThread parkDataThread = new ParkDataThread(parkDataParsers);
      parkDataThread.setArchiveURL("http://www.inpark.info/data/archive.php");
      parkDataThread.start();
      //addCheckIfActive(parkDataThread);
    } else {
      boolean firstThread = true;
      int i = 0;
      int j = 0;
      String lastParserIdentifier = null;
      while (i < parkDataParsers.length) {
        String s = parkDataParsers[i].parserIdentifier();
        if (lastParserIdentifier == null) {
          lastParserIdentifier = s;
        } else if (!lastParserIdentifier.equals(s)) {
          trace("start threat for " + (i-j) + " parsers " + lastParserIdentifier);
          ParkDataParser[] parsers = new ParkDataParser[i-j];
          for (int k = j; k < i; ++k) parsers[k-j] = parkDataParsers[k];
          ParkDataThread parkDataThread = new ParkDataThread(parsers);
          if (firstThread) parkDataThread.setArchiveURL("http://www.inpark.info/data/archive.php");
          firstThread = false;
          parkDataThread.start();
          //addCheckIfActive(parkDataThread);
          lastParserIdentifier = s;
          j = i;
        }
        ++i;
      }
      if (i > j) {
        trace("start threat for " + (i-j) + " parsers " + lastParserIdentifier);
        ParkDataParser[] parsers = new ParkDataParser[i-j];
        for (int k = j; k < i; ++k) parsers[k-j] = parkDataParsers[k];
        ParkDataThread parkDataThread = new ParkDataThread(parsers);
        if (firstThread) parkDataThread.setArchiveURL("http://www.inpark.info/data/archive.php");
        parkDataThread.start();
        //addCheckIfActive(parkDataThread);
      }
    }
    //http://m.touringplans.com/wdw/parks/1/reported#_recent
  }
}
