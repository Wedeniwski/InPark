import java.io.*;
import java.util.*;

// Änderungen an types.plist
// 1) unter Root neues Dictionary "TYPES" mit TYPES_IDs
// 2) Ein Eintrag "TYPE_ID" besteht aus einem Array mit Eintrag
// 2.1) "Name" entweder String oder sprachabhängig Dictionary mit Einträge "de", "en" (nicht mehr "German.lproj" oder "English.lproj")
// 2.2) Optional "Icon" vom Type String
// 3) Eintrag CATEGORIES_ID ist Dictionary mit Einträge
// 3.1) "Name" entweder String oder sprachabhängig Dictionary mit Einträge "de", "en"
// 3.2) "Types" ist ein Array wo die TYPES_IDs aufgeführt werden
// 3.3) Optional "Icon" vom Type String

// Änderung an plist für Parkdaten unterhalb einer Attraktions-ID
// 1) Eintrag "Kategorie" müssen wir noch eine Zeit wie bisher pflegen (auch in den neuen Parkdaten); spätestens mitte nächsten Jahres sollten aber die meisten auf die neue App-Version dann umgestiegen sein; denke aber auch daran, die alte "categories.plist" entsprechend zu pflegen
// 2) Neuer Eintrag "Type" wo nun die TYPE_ID aufgeführt wird
// 3) "German.lproj" oder "English.lproj" belassen wir vorerst noch bei der Kurzbeschreibung als auch beim Name

public class CreateTypes {
  // java -cp GPS.jar CreateTypes <parkId>
  private static void addLanguageEntry(Map plist, String name, String eEntry, String dEntry) {
    Map m = new HashMap(2);
    m.put("en", eEntry);
    m.put("de", dEntry);
    plist.put(name, m);
  }

  public static void main(String[] args) {
    try {
      String parkId = args[0];
      System.out.println("PARK: " + parkId);
      //Map dCategories = PList.readPListFile("../data/de.lproj/categories.plist");
      Map eCategories = PList.readPListFile("../data/en.lproj/categories.plist");
      Map plist = PList.readPListFile("../data/" + parkId + '/' + parkId + ".plist");
      Map types = new HashMap(20);
      Map type = new HashMap(20);
      Map category = new HashMap(20);
      Map parkType = new HashMap(20);
      Map themePark = new HashMap(10);
      List themeParkCategories = new ArrayList(10);
      types.put("TYPES", type);
      types.put("CATEGORIES", category);
      types.put("PARK_TYPES", parkType);
      parkType.put("THEME_PARK", themePark);
      themePark.put("Categories", themeParkCategories);
      addLanguageEntry(parkType, "Name", "Theme Park", "Themenpark");
      Iterator<String> keys = eCategories.keySet().iterator();
      while (keys.hasNext()) {
        String cat = keys.next();
        if (cat == null) break;
        String catId = cat.toUpperCase().replace(' ', '_');
        themeParkCategories.add(catId);
        Map c = new HashMap(5);
        addLanguageEntry(c, "Name", cat, "");
        category.put(catId, c);
        List lst = (List)eCategories.get(cat);
        List<String> lTypes = new ArrayList(30);
        int l = lst.size();
        Object obj = lst.get(0);
        if (obj instanceof String) {
          c.put("Icon", obj);
          c.put("Types", lTypes);
          for (int i = 1; i < l; ++i) {
            String t = (String)lst.get(i);
            String tId = t.toUpperCase().replace(' ', '_');
            lTypes.add(tId);
            Map tp = new HashMap(4);
            addLanguageEntry(tp, "Name", t, "");
            type.put(tId, tp);
          }
        } else {
          c.put("Types", lTypes);
          for (int i = 0; i < l; ++i) {
            Map map = (Map)lst.get(i);
            String t = (String)map.get("Name");
            String tId = t.toUpperCase().replace(' ', '_');
            lTypes.add(tId);
            Map tp = new HashMap(4);
            addLanguageEntry(tp, "Name", t, "");
            tp.put("Icon", map.get("Icon"));
            type.put(tId, tp);
          }
        }
      }
      Map m = (Map)plist.get("IDs");
      keys = m.keySet().iterator();
      while (keys.hasNext()) {
        String attractionId = keys.next();
        if (attractionId == null) break;
        Map attraction = (Map)m.get(attractionId);
        String ken, kde;
        Object obj = attraction.get("Kategorie");
        if (obj instanceof Map) {
          Map name = (Map)obj;
          ken = (String)name.get("English.lproj");
          kde = (String)name.get("German.lproj");
        } else {
          ken = kde = (String)obj;
        }
        boolean tset = false;
        Iterator<String> typeIds = type.keySet().iterator();
        while (typeIds.hasNext()) {
          String typeId = typeIds.next();
          if (typeId == null) break;
          Map t = (Map)type.get(typeId);
          Map n = (Map)t.get("Name");
          String en = (String)n.get("en");
          if (ken.equals(en)) {
            n.put("de", kde);
            attraction.put("Type", typeId);
            tset = true;
            break;
          }
        }
        if (!tset) System.out.println("Category for " + ken + " at " + attractionId + " not found!");
      }
      PList.writePListFile("types.plist", types);
      PList.writePListFile(parkId + "2.plist", plist);
    } catch (IOException ioe) {
      ioe.printStackTrace();
    }
  }
}
