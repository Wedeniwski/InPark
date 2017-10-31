<html><head>
<title>Select park</title>
</head><body>
<form id="form" name="form" action="park.php">
<p>Park name
<select name="park">
<?php
  $home = $_SERVER['DOCUMENT_ROOT'] . "/editor/";
  require_once($home . "CFPropertyList/CFPropertyList.php");
  
  $parkIds = array();
  $d = dir($home . ".");
  while ($entry = $d->read()) {
    if ($entry != "." && $entry != ".." && is_dir($home . $entry)) {
      if (file_exists($home . $entry . "/" . $entry . ".plist")) $parkIds[] = $entry;
    }
  }
  $d->close();
  foreach ($parkIds as $parkId) {
    echo "<option value=\"";
    echo $parkId;
    echo "\">";
    $filename = $home . $parkId . "/" . $parkId . ".plist";
    $plist = new CFPropertyList($filename, CFPropertyList::FORMAT_XML);
    $array = $plist->toArray();
    echo $array["Parkname"];
    echo " (";
    echo $parkId;
    echo ")</option>";
  }
?>
</select></p><input type="submit" value="Next">
</form>
</bod></html>