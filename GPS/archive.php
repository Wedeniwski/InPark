<?php
  // http://www.inpark.info/data/archive.php

  $link = mysql_connect('db370170346.db.1and1.com', 'dbo370170346', 'djumpinbaschi');
  if (!$link) die('Cannot connect to the DB');
  if (!mysql_select_db('db370170346', $link)) {
    mysql_close($link);
    die('Cannot select the DB');
  }
  // archiving old data
  $query = "SELECT CURRENT_TIMESTAMP FROM `archive_waiting_time` LIMIT 0,1";
  $result = mysql_query($query, $link);
  if (!$result) {
    $message  = 'error timestamp query:' . mysql_error();
    mysql_close($link);
    die($message);
  }
  if ($row = mysql_fetch_row($result)) {
    $now = $row[0];
    mysql_free_result($result);
    $query = "INSERT INTO `archive_waiting_time2` SELECT * FROM `archive_waiting_time` WHERE `created` <= '$now'";
    if (!mysql_query($query, $link)) {
      $message  = 'error move time query:' . mysql_error();
      mysql_close($link);
      die($message);
    }
    $query = "DELETE FROM `archive_waiting_time` WHERE `created` <= '$now'";
    if (!mysql_query($query, $link)) {
      $message  = 'error delete time query:' . mysql_error();
      mysql_close($link);
      die($message);
    }
  }
?>