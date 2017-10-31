<?php
  require_once('CFPropertyList/CFPropertyList.php');

  $parkId = "ep";
  $filename = $parkId . "/" . $parkId . ".plist";
  $plist = new CFPropertyList($filename, CFPropertyList::FORMAT_XML);

  echo '<pre>';
  var_dump( $plist->toArray() );
  echo '</pre>';
?>
