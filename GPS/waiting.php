<?php
  ob_start("ob_gzhandler");

  // http://www.inpark.info/data/waiting.php?pid=ep

  if (!isset($_GET['pid'])) die();
  $park_id = $_GET['pid'];

  if (isset($_GET['eid'])) {
    $attraction_id = $_GET['aid'];
    $entry_id = $_GET['eid'];
    $exit_id = $_GET['xid'];
    $entry = $_GET['e']; // \'2011-06-03 23:00:10\'
    $entry_latitude = doubleval($_GET['ela']);
    $entry_longitude = doubleval($_GET['elo']);
    $entry_accuracy = doubleval($_GET['eac']);
    $closed = $_GET['c'];
    $attraction_duration = intval($_GET['d']);
    $app_version = $_GET['v'];
    $user_id = $_GET['uid'];
    $gash = $attraction_id . $entry . $entry_id . $user_id . $exit_id . $app_version . $park_id . sprintf("%.5f", doubleval($closed)+3*doubleval($attraction_duration)-3.1415927) . sprintf("%.5f", $entry_latitude + 2*$entry_longitude - 3*$entry_accuracy);
  }
  if (isset($_GET['x'])) {
    $exit = $_GET['x']; // \'2011-06-03 23:04:10\'
    $exit_latitude = doubleval($_GET['xla']);
    $exit_longitude = doubleval($_GET['xlo']);
    $exit_accuracy = doubleval($_GET['xac']);
    $gash .= $exit . sprintf("%.5f", 2.7182818 + $exit_latitude + 5*$exit_longitude - 7*$exit_accuracy);
  }
  if (isset($_GET['un'])) {
    $user_name = $_GET['un'];
    $gash .= $user_name;
  }
  if (isset($_GET['cm'])) {
    $comment = $_GET['cm'];
    $gash .= md5($comment);
  }
  if (isset($_GET['f'])) { // fast_lane
    $fast_lane_available = $_GET['f'];
    $gash .= $fast_lane_available;
    if (isset($_GET['ff']) && strlen($_GET['ff']) == 4) {
      $fast_lane_time_from = $_GET['ff'];
      $gash .= $fast_lane_time_from;
      if (isset($_GET['ft']) && strlen($_GET['ft']) == 4) {
        $fast_lane_time_to = $_GET['ft'];
        $gash .= $fast_lane_time_to;
      }
    }
  }

  //echo $gash;
  if (isset($gash)) {
    if (!isset($_GET['h'])) die();
    $hash = md5($gash);
    if ($hash != $_GET['h']) die();
  }

  $link = mysql_connect('db370170346.db.1and1.com', 'dbo370170346', 'djumpinbaschi');
  if (!$link) die('Cannot connect to the DB');
  if (!mysql_select_db('db370170346', $link)) {
    mysql_close($link);
    die('Cannot select the DB');
  }
  // archiving old data
  if (!isset($_GET['b'])) {  // no batch, i.e. another call will follow shortly
    if (isset($attraction_id)) {
      $query = "SELECT CURRENT_TIMESTAMP FROM `waiting_time` WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, `created`)) >= 28800 AND `park_id`='$park_id' OR `exit` IS NULL AND `park_id`='$park_id' AND `attraction_id`='$attraction_id' AND `user_id`='$user_id' LIMIT 0,1";
    } else {
      $query = "SELECT CURRENT_TIMESTAMP FROM `waiting_time` WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, `created`)) >= 28800 AND `park_id`='$park_id' LIMIT 0,1";
    }
    $result = mysql_query($query, $link);
    if (!$result) {
      $message  = 'error timestamp query:' . mysql_error();
      mysql_close($link);
      die($message);
    }
    if ($row = mysql_fetch_row($result)) {
      $now = $row[0];
      $content_changed = 1;
      mysql_free_result($result);
      if (isset($attraction_id)) {
        $query = "INSERT INTO `archive_waiting_time` SELECT * FROM `waiting_time` WHERE TIME_TO_SEC(TIMEDIFF('$now', `created`)) >= 28800 AND `park_id`='$park_id' OR `exit` IS NULL AND `park_id`='$park_id' AND `attraction_id`='$attraction_id' AND `user_id`='$user_id'";
        if (!mysql_query($query, $link)) {
          $message  = 'error move time query:' . mysql_error();
          mysql_close($link);
          die($message);
        }
        $query = "DELETE FROM `waiting_time` WHERE TIME_TO_SEC(TIMEDIFF('$now', `created`)) >= 28800 AND `park_id`='$park_id' OR `exit` IS NULL AND `park_id`='$park_id' AND `attraction_id`='$attraction_id' AND `user_id`='$user_id'";
        if (!mysql_query($query, $link)) {
          $message  = 'error delete time query:' . mysql_error();
          mysql_close($link);
          die($message);
        }
      } else {
        $query = "INSERT INTO `archive_waiting_time` SELECT * FROM `waiting_time` WHERE TIME_TO_SEC(TIMEDIFF('$now', `created`)) >= 28800 AND `park_id`='$park_id'";
        if (!mysql_query($query, $link)) {
          $message  = 'error move time query:' . mysql_error();
          mysql_close($link);
          die($message);
        }
        $query = "DELETE FROM `waiting_time` WHERE TIME_TO_SEC(TIMEDIFF('$now', `created`)) >= 28800 AND `park_id`='$park_id'";
        if (!mysql_query($query, $link)) {
          $message  = 'error delete time query:' . mysql_error();
          mysql_close($link);
          die($message);
        }
      }
    } else {
      mysql_free_result($result);
    }
  }

  if (isset($user_id)) {
    // verify query
    $query = "SELECT `hash`,`user_id` FROM `waiting_time` WHERE `hash`='$hash' AND `user_id`='$user_id' AND `park_id`='$park_id'";
    $result = mysql_query($query, $link);
    if (!$result) {
      $message  = 'error query verification:' . mysql_error();
      mysql_close($link);
      die($message);
    }
    if ($row = mysql_fetch_row($result)) {
      mysql_close($link);
      die('already known');
    }
    
    // updating waiting table
    if (isset($exit)) {
      $content_changed = 1;
      $query1 = "INSERT INTO `waiting_time` (`park_id`, `attraction_id`, `entry_id`, `exit_id`, `entry`, `exit`, `closed`";
      $query2 = ", `attraction_duration`, `app_version`, `entry_latitude`, `entry_longitude`, `entry_accuracy`, `exit_latitude`, `exit_longitude`, `exit_accuracy`";
      $query3 = ", `user_id`, `hash`) VALUES ('$park_id', '$attraction_id', '$entry_id', '$exit_id', '$entry', '$exit', $closed";
      $query4 = ", $attraction_duration, '$app_version', $entry_latitude, $entry_longitude, $entry_accuracy, $exit_latitude, $exit_longitude, $exit_accuracy";
      $query5 = ", '$user_id', '$hash')";
      if (isset($user_name)) {
        $query2 .= ", `user_name`";
        $query4 .= sprintf(", '%s')", mysql_real_escape_string($user_name));
      }
      if (isset($comment)) {
        $query2 .= ", `comment`";
        $query4 .= sprintf(", '%s')", mysql_real_escape_string($comment));
      }
      if (isset($fast_lane_available)) {
        $query1 .= ", `fast_lane_available`";
        $query3 .= ", $fast_lane_available";
        if (isset($fast_lane_time_from)) {
          $query1 .= ", `fast_lane_time_from`";
          $query3 .= ", '$fast_lane_time_from'";
          if (isset($fast_lane_time_to)) {
            $query1 .= ", `fast_lane_time_to`";
            $query3 .= ", '$fast_lane_time_to'";
          }
        }
      }
    } else if (isset($attraction_id)) {
      $content_changed = 1;
      $query1 = "INSERT INTO `waiting_time` (`park_id`, `attraction_id`, `entry_id`, `exit_id`, `entry`, `closed`";
      $query2 = ", `attraction_duration`, `app_version`, `entry_latitude`, `entry_longitude`, `entry_accuracy`";
      $query3 = ", `user_id`, `hash`) VALUES ('$park_id', '$attraction_id', '$entry_id', '$exit_id', '$entry', $closed";
      $query4 = ", $attraction_duration, '$app_version', $entry_latitude, $entry_longitude, $entry_accuracy";
      $query5 = ", '$user_id', '$hash')";
      if (isset($user_name)) {
        $query2 .= ", `user_name`";
        $query4 .= sprintf(", '%s')", mysql_real_escape_string($user_name));
      }
      if (isset($comment)) {
        $query2 .= ", `comment`";
        $query4 .= sprintf(", '%s')", mysql_real_escape_string($comment));
      }
      if (isset($fast_lane_available)) {
        $query1 .= ", `fast_lane_available`";
        $query3 .= ", $fast_lane_available";
        if (isset($fast_lane_time_from)) {
          $query1 .= ", `fast_lane_time_from`";
          $query3 .= ", '$fast_lane_time_from'";
          if (isset($fast_lane_time_to)) {
            $query1 .= ", `fast_lane_time_to`";
            $query3 .= ", '$fast_lane_time_to'";
          }
        }
      }
    }
  }

  // creating waiting table
  if (isset($content_changed)) {
    if (isset($query1)) {
      $query = $query1 . $query2 . $query3 . $query4 . $query5;
      if (!mysql_query($query, $link)) {
        $message  = 'error insert query:' . mysql_error();
        mysql_close($link);
        die($message);
      }
    }
    if (!isset($_GET['b'])) {  // batch, i.e. another call will follow shortly
      if (!isset($now)) {
        $query = "SELECT CURRENT_TIMESTAMP FROM `waiting_time` LIMIT 0,1";
        $result = mysql_query($query, $link);
        if (!$result) {
          $message  = 'error timestamp query:' . mysql_error();
          mysql_close($link);
          die($message);
        }
        if ($row = mysql_fetch_row($result)) $now = $row[0];
        mysql_free_result($result);
      }
      // remove data from users which are on temporary black list, i.e. submitted more than 3 waiting times >= 120 minutes in the last hour
      $black_list = array();
      $query = "SELECT `user_id` FROM `waiting_time` WHERE `park_id`='$park_id' AND `exit` IS NULL AND `app_version`!='1.2020569' AND `attraction_duration`>=120 GROUP BY `user_id` HAVING COUNT(*)>=3";
      $result = mysql_query($query, $link);
      if (!$result) {
        $message  = 'error black list query:' . mysql_error();
        mysql_close($link);
        die($message);
      }
      while ($row = mysql_fetch_row($result)) array_push($black_list, $row[0]);
      mysql_free_result($result);

      /* ToDo:
       http://rickosborne.org/blog/2008/01/sql-getting-top-n-rows-for-a-grouped-query/
       SELECT c.*, d.ranknum FROM `waiting_time` AS c
      INNER JOIN (
                  SELECT a.id, COUNT(*) AS ranknum FROM `waiting_time` AS a
                  INNER JOIN `waiting_time` AS b ON (`a.attraction_id` = `b.attraction_id`) AND (`a.created` <= `b.created`)
                  GROUP BY `a.attraction_id` HAVING COUNT(*) <= 3
                  ) AS d ON (`c.attraction_id` = `d.attraction_id`)
      ORDER BY `c.attraction_id`, `c.created` ASC, d.ranknum*/

      $sql = "SELECT `attraction_id`,`closed`,`attraction_duration`,TIME_TO_SEC(TIMEDIFF(`exit`, `entry`)),`created`,`user_name`,`comment`,TIME_TO_SEC(TIMEDIFF('$now', `created`)),`user_id`,`fast_lane_available`,`fast_lane_time_from`,`fast_lane_time_to`,`app_version` FROM `waiting_time` WHERE `park_id`='$park_id' ORDER BY `attraction_id`, `created` ASC";
      $result = mysql_query($sql, $link);
      if (!$result) {
        $message  = 'error select query:' . mysql_error();
        mysql_close($link);
        die($message);
      }
      $str = "- " . $park_id . "\n\n," . strtotime($now) . "\n";
      $str2 = "";
      $previous_attraction_id = "";
      $total_weight = 0;
      $minutes = 0;
      $base_seconds = 0;
      $closed = 0;
      $number_of_entries = 0;
      $last_time = 0;
      $last_user_id = "";
      $fast_lane_available = NULL;
      $fast_lane_time_from = NULL;
      $fast_lane_time_to = NULL;
      while ($row = mysql_fetch_row($result)) {
        if ($row[2] > 60 && in_array($row[8], $black_list)) continue;
        if ($row[0] != $previous_attraction_id && strcmp($previous_attraction_id, "") != 0) {
          if ($closed >= 3) {
            $str .= $previous_attraction_id . ":-1\n";
            if (strlen($str2) > 0) $str .= $str2;
          } else if ($total_weight == 0) {
            if (strcmp($previous_attraction_id, "000") != 0) $str .= $previous_attraction_id . "\n";
            if (strlen($str2) > 0) $str .= $str2;
          } else {
            // ignore if only one manually submitted entry >= 100 minutes exist
            if ($number_of_entries > 1 || strcmp($row[12], "1.2020569") == 0 || $minutes == 0 || $minutes > 0 && $total_weight > 0 && $minutes/$total_weight < 100) {
              if ($minutes < 0) $minutes = -1;
              else if ($minutes != 0) $minutes = $minutes / $total_weight;
              if (is_null($fast_lane_available)) $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "\n";
              else {
                if ($fast_lane_available > 0) $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "F+";
                else if ($fast_lane_available < 0) $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "F-";
                else $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "F0";
                if (!is_null($fast_lane_time_from)) $str .= $fast_lane_time_from;
                if (!is_null($fast_lane_time_to)) $str .= ':' . $fast_lane_time_to;
                $str .= "\n";
              }
              if (strlen($str2) > 0) $str .= $str2;
            }
          }
          $str2 = "";
          $minutes = 0;
          $base_seconds = 0;
          $m = 0;
          $total_weight = 0;
          $closed = 0;
          $number_of_entries = 0;
          $last_time = 0;
          $last_user_id = "";
        }
        if ($row[1] == 0) {
          $closed = 0;
          if (is_null($row[3])) {
            $m = $row[2];
          } else {
            $m = round(($row[3]/60) - $row[2]);
            if ($m < 0) $m = 0;
          }
        } else {
          $closed += $row[1];
          $m = -1;
        }
        // falls min 2 Wartezeiten in den letzten 15 Minuten vorhanden sind: neue manuell eingegebene Wartezeit wird nur dann eingereicht, wenn die Zeit zu den vorhandenen Wartezeiten kleiner 60 Minuten ist
        if ($m > 0 && $number_of_entries >= 2 && strcmp($row[12], "1.2020569") != 0 && $minutes > 0 && $total_weight > 0 && abs($m-60) >= $minutes/$total_weight) continue;
        $previous_attraction_id = $row[0];
        $fast_lane_available = $row[9];
        $fast_lane_time_from = $row[10];
        $fast_lane_time_to = $row[11];
        if (strcmp($previous_attraction_id, "000") == 0) {
          if ($row[7] < 480) {
            $minutes = $m;
            $total_weight = 1;
          }
        } else if ($m <= 180) {
          $time_of_row = strtotime($row[4]);
          if ($m >= 0 && $row[7] < 3600 && ($base_seconds == 0 || $base_seconds > $time_of_row)) {
            if ($base_seconds == 0) $base_seconds = 3640.0+$time_of_row;
            if (is_null($row[3])) $weight = 3650.0/($base_seconds-$time_of_row);
            else $weight = 7300.0/($base_seconds-$time_of_row); // higher weight for indirect wait time submission through tour
            $total_weight += $weight;
            $minutes += $m*$weight;
          }
          $user_id_of_row = $row[8];
          if ($time_of_row-$last_time >= 600 || strcmp($user_id_of_row, $last_user_id) != 0) {
            $str3 = $m . "," . round($row[7] / 60);
            if (!is_null($row[5])) $str3 .= "," . $row[5];
            if (!is_null($row[6])) $str3 .= ";" . $row[6];
            $str3 .= "\n";
            if ($number_of_entries < 3) $str2 = $str3 . $str2;
            else $str2 = $str3 . substr($str2, 0, strrpos($str2, "\n", -2)+1);
            $number_of_entries += 1;
            $last_time = $time_of_row;
            $last_user_id = $user_id_of_row;
          }
        }
      }
      mysql_free_result($result);
      mysql_close($link);
      
      if (strcmp($previous_attraction_id, "") != 0) {
        if ($closed >= 3) {
          $str .= $previous_attraction_id . ":-1\n";
          if (strlen($str2) > 0) $str .= $str2;
        } else if ($total_weight == 0) {
          if (strcmp($previous_attraction_id, "000") != 0) $str .= $previous_attraction_id . "\n";
          if (strlen($str2) > 0) $str .= $str2;
        } else {
          if ($number_of_entries > 1 || strcmp($row[12], "1.2020569") == 0 || $minutes == 0 || $minutes > 0 && $total_weight > 0 && $minutes/$total_weight < 100) {
            if ($minutes < 0) $minutes = -1;
            else if ($minutes != 0) $minutes = $minutes / $total_weight;
            if (is_null($fast_lane_available)) $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "\n";
            else {
              if ($fast_lane_available > 0) $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "F+";
              else if ($fast_lane_available < 0) $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "F-";
              else $str .= $previous_attraction_id . ':' . strval(round($minutes)) . "F0";
              if (!is_null($fast_lane_time_from)) $str .= $fast_lane_time_from;
              if (!is_null($fast_lane_time_to)) $str .= ':' . $fast_lane_time_to;
              $str .= "\n";
            }
            if (strlen($str2) > 0) $str .= $str2;
          }
        }
      }
      $str .= "c:" . filectime($park_id . "/calendar.txt") . "\n";
      $str .= md5($str);
      
      // writing waiting file
      $tmp_filename = $park_id . "/waiting.tmp.txt";
      $filename = $park_id . "/waiting.txt";
      file_put_contents($tmp_filename, $str);
      //$handle = fopen($tmp_filename, "w");
      //fwrite($handle, $str);
      //fclose($handle);
      if (file_exists($filename)) unlink($filename);
      rename($tmp_filename, $filename);

      // filename of compressed file (in same directory) 
      $tmp_filename = $park_id . "/waiting.tmp.txt.gz";
      $gz_filename = $park_id . "/waiting.txt.gz";
      $handle = gzopen($tmp_filename, 'w9'); 
      gzwrite($handle, $str);
      gzclose($handle);
      if (file_exists($gz_filename)) unlink($gz_filename);
      rename($tmp_filename, $gz_filename);

      echo $str;
    }
  } else {
    mysql_close($link);
   
    $filename = $park_id . "/waiting.txt";
    if (file_exists($filename)) {
      $contents = file_get_contents($filename);
      //$handle = fopen($filename, "r");
      //$contents = fread($handle, filesize($filename));
      //fclose($handle);
      
      echo $contents;
    } else {
      $str = "- " . $park_id . "\n\n";
      $str .= md5($str);

      $tmp_filename = $park_id . "/waiting.tmp.txt";
      $filename = $park_id . "/waiting.txt";
      file_put_contents($tmp_filename, $str);
      //$handle = fopen($tmp_filename, "w");
      //fwrite($handle, $str);
      //fclose($handle);
      if (file_exists($filename)) unlink($filename);
      rename($tmp_filename, $filename);
      
      $tmp_filename = $park_id . "/waiting.tmp.txt.gz";
      $gz_filename = $park_id . "/waiting.txt.gz";
      $handle = gzopen($tmp_filename, 'w9'); 
      gzwrite($handle, $str);
      gzclose($handle);
      if (file_exists($gz_filename)) unlink($gz_filename);
      rename($tmp_filename, $gz_filename);

      echo $str;
    }
  }
?>