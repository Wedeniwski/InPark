<?php
  // http://www.inpark.info/data/news.php
  function parse($filename, &$keys, &$dates, &$titles, &$pages) {
    if (file_exists($filename)) {
      $handle = fopen($filename, "r");
      $data = fread($handle, filesize($filename));
      fclose($handle);
      // parse content
      $sections = explode("<h1><a name=\"", $data);
      foreach ($sections as $pgs) {
        $a = explode("</a></h1>", $pgs);
        if (count($a) == 2) {
          $b = explode("\">", $a[0]);
          if (count($b) == 2) {
            $key = $b[0];
            $keys[] = $key;
            $titles[$key] = $b[1];
            $text = $a[1];
            $pos = strpos($text, "</p>");
            if ($pos !== false) {
              $dates[$key] = substr($text, 4, $pos-4);
              $text = substr($text, $pos+4);
              $pos = strpos($text, "<p>");
              if ($pos !== false) {
                $text = substr($text, $pos+3);
                $pos = strpos($text, "</p>");
                if ($pos !== false) $text = substr($text, 0, $pos);
              }
            }
            $pages[$key] = $text;
          }
        }
      }
    }
  }

  function parkGroups($parkIds) {
    foreach ($parkIds as $parkId) {
      $filename = $parkId . "/" . $parkId . ".plist";
      echo "!!";
      if (file_exists($filename)) {
        $handle = fopen($filename, "r");
        $data = fread($handle, filesize($filename));
        fclose($handle);
        $data = strstr($data, "<key>Parkgruppe</key>");
        if ($data) {
          $data = strstr($data, "<string>");
          if ($data) {
            $pos = strpos($data, "</string>");
            if ($pos !== false) {
              $group = substr($data+8, $data+$pos);
              echo "<br/>" . $parkId . " - " . $group;
            }
          }
        }
      }
    }
  }

  if (isset($_GET['parks_no'])) {
    $parks_no = $_GET['parks_no'];
    $park_id = array();
    for ($i = 0; $i < $parks_no; ++$i) {
      $park_id[$i] = $_GET['park'.$i];
    }
  } else $parks_no = 1;
  if (isset($_GET['key'])) $news_key = $_GET['key'];
  $parkIds = array();
  $d = dir(".");
  while ($entry = $d->read()) {
    if ($entry != "." && $entry != ".." && is_dir("./".$entry)) $parkIds[] = $entry;
  }
  $d->close();

  //echo "<html><body><script type=\"text/javascript\">var x;function showValue(str){alert(\"X!\";x=GetXmlHttpObject();if(x==null){alert(\"Your browser does not support AJAX!\");return;}var url=\"http://www.inpark.info/data/news.php?q=\"+str;x.onreadystatechange=stateChanged;x.open(\"GET\",url,true);x.send(null);}function stateChanged(){if (xmlHttp.readyState==4){document.getElementById(\"txtHint\").innerHTML=xmlHttp.responseText;}}function GetXmlHttpObject(){var x=null;try{x=new XMLHttpRequest();}catch(e){try{x=new ActiveXObject(\"Msxml2.XMLHTTP\");}catch(e){x=new ActiveXObject(\"Microsoft.XMLHTTP\");}}return x;}</script><form action=\"news.php\">Park ID:<p><select name=\"park\" onChange=\"showValue(this.value)\">";
  echo "<html><head><link href=\"../calendar/calendar.css\" rel=\"stylesheet\" type=\"text/css\"/><script language=\"javascript\" src=\"../calendar/calendar.js\"></script></head><body><h1><b>Eingabemaske InPark News</b></h1><form action=\"news.php\"><p><table><tr><td>Erstellungsdatum:</td><td>";
  parkGroups($parkIds);

  // $date4_default = "2012-08-05";
  // strtotime($date4_default)
  require_once('../calendar/classes/tc_calendar.php');
  $myCalendar = new tc_calendar("date1", true);
  $myCalendar->setIcon("../calendar/images/iconCalendar.gif");
  $myCalendar->setDate(date('d'), date('m'), date('Y'));
  $myCalendar->setDateFormat('j F Y');
  $myCalendar->setPath("../calendar/");
  $myCalendar->setYearInterval(2011, 2015);
  $myCalendar->dateAllow('2011-01-01', '2015-03-01');
  //$myCalendar->setSpecificDate(array("2011-04-01", "2011-04-13", "2011-04-25"), 0, 'month');
  //$myCalendar->setOnChange("myChanged('test')");
  $myCalendar->writeScript();
  echo("</td></tr></table></p><p><table><tr><td><input type=\"checkbox\" name=\"from\" value=\"from\">&nbsp; Datum:</td><td>");

  $myCalendar = new tc_calendar("date3", true, false);
  $myCalendar->setIcon("../calendar/images/iconCalendar.gif");
  $myCalendar->setDate(date('d'), date('m'), date('Y'));
  $myCalendar->setDateFormat('j F Y');
  $myCalendar->setPath("../calendar/");
  $myCalendar->setYearInterval(2011, 2015);
  $myCalendar->dateAllow('2011-01-01', '2015-03-01');
  $myCalendar->setAlignment('left', 'bottom');
  $myCalendar->setDatePair('date3', 'date4', "2012-08-05");
  $myCalendar->writeScript();
  echo "</td><td>&nbsp;&nbsp;<input type=\"checkbox\" name=\"to\" value=\"to\">&nbsp; bis &nbsp;</td><td>";
  $myCalendar = new tc_calendar("date4", true, false);
  $myCalendar->setIcon("../calendar/images/iconCalendar.gif");
  $myCalendar->setDate(date('d'), date('m'), date('Y'));
  $myCalendar->setDateFormat('j F Y');
  $myCalendar->setPath("../calendar/");
  $myCalendar->setYearInterval(2011, 2015);
  $myCalendar->dateAllow('2011-01-01', '2015-03-01');
  $myCalendar->setAlignment('left', 'bottom');
  $myCalendar->setDatePair('date3', 'date4', "2012-08-05");
  $myCalendar->writeScript();
  
  echo "</td></tr></table></p><br/>\n<p><table><tr><td>Park:</td>";
  for ($i = 0; $i < $parks_no; ++$i) {
    echo "<td><select name=\"park";
    echo $i;
    echo "\">";
    if ($i == 0) {
      if (isset($park_id)) echo "<option>ALLE</option>";
      else echo "<option selected>ALLE</option>";
    }
    foreach ($parkIds as $entry) {
      if ($entry == $park_id[$i]) echo "<option selected>";
      else echo "<option>";
      echo $entry;
      echo "</option>";
    }
    echo "</select></td>";
  }
  echo "<td><select name=\"parks_no\">";
  for ($i = 1; $i <= 5; ++$i) {
    if ($i == $parks_no) echo "<option selected>";
    else echo "<option>";
    echo $i;
    echo "</option>";
  }
  echo "</select></td></tr>";
  $de_keys = array();
  $de_dates = array();
  $de_titles = array();
  $de_pages = array();
  $en_keys = array();
  $en_dates = array();
  $en_titles = array();
  $en_pages = array();
  if ($parks_no == 1 && isset($park_id) && $park_id[0] != "ALLE") {
    $de_filename = $park_id[0] . "/de.lproj/news.txt";
    $en_filename = $park_id[0] . "/en.lproj/news.txt";
    parse($de_filename, $de_keys, $de_dates, $de_titles, $de_pages);
    parse($en_filename, $en_keys, $en_dates, $en_titles, $en_pages);
    $new_news = !isset($news_key);
  } else $new_news = true;
  echo "<tr><td>Neu / News ID:</td><td><select name=\"key\">";
  if ($new_news) echo "<option selected>NEU</option>";
  else echo "<option>NEU</option>";
  foreach ($de_keys as $key) {
    if (!$new_news && $key == $news_key) echo "<option selected>";
    else echo "<option>";
    echo $key;
    echo "</option>";
  }
  echo "</select></td></tr></table></p><input type=\"submit\" value=\"Aktualisieren\">";
  echo "&nbsp;<br/><p><table><tr><td><b>&Uuml;berschrift</b></td></tr><tr><td>Deutsch</td><td><input name=\"de_title\" type=\"text\" size=\"100\" value=\"";
  if (!$new_news) echo utf8_decode($de_titles[$news_key]);
  echo "\"></td></tr><tr><td>Englisch</td><td><input name=\"en_title\" type=\"text\" size=\"100\" value=\"";
  if (!$new_news) echo utf8_decode($en_titles[$news_key]);
  echo "\"></td></tr></table></p>&nbsp;<br/><p><table><tr><td><b>Text</b></td></tr><tr><td>Deutsch</td><td><textarea name=\"de_text\" cols=\"100\" rows=\"5\">";
  if (!$new_news) echo utf8_decode($de_pages[$news_key]);
  echo "</textarea></td></tr><tr><td>Englisch</td><td><textarea name=\"en_text\" cols=\"100\" rows=\"5\">";
  if (!$new_news) echo utf8_decode($en_pages[$news_key]);
  echo "</textarea>";
  echo "</td></tr></table></p>";
  //<input type=\"submit\" value=";
  //if ($new_news) echo "\"Hinzuf&uuml;gen\">";
  //else echo "\"Aktualisieren\">";
  echo "</form></body></html>";
?>