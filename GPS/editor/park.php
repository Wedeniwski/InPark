<script type="text/javascript" src="http://www.google.com/jsapi"></script>
<script type="text/javascript">google.load("jquery", "1");</script>
<script type="text/javascript" src="http://www.inpark.info/editor/tiny_mce/jquery.tinymce.js"></script>
<script type="text/javascript">$().ready(function(){
$('textarea.tinymce').tinymce({script_url: 'http://www.inpark.info/editor/tiny_mce/tiny_mce.js',
                              theme: "advanced",
                              plugins: "lists,table,iespell,inlinepopups,preview,searchreplace,contextmenu,paste,directionality,noneditable,visualchars,nonbreaking,xhtmlxtras",
                              theme_advanced_buttons1: "bold,italic,underline,strikethrough,sub,sup,|,justifyleft,justifycenter,justifyright,justifyfull,|,bullist,numlist,|,outdent,indent,|,forecolor,backcolor,|,cleanup,code",
                              theme_advanced_buttons2: "cut,copy,paste,pastetext,pasteword,|,search,replace,|,undo,redo,|,tablecontrols,|,hr,removeformat,visualaid,|,charmap,iespell",
                              theme_advanced_toolbar_location: "top",
                              theme_advanced_toolbar_align: "left",
                              theme_advanced_statusbar_location: "bottom",
                              theme_advanced_resizing: true,
                              });});</script>

<?php
  function getCategoryNamesForParkType($categoriesOfParkType, $allCategories, $language) {
    $categoryNames = array();
    foreach ($categoriesOfParkType as $category) {
      $a = $allCategories[$category];
      $name = $a['Name'];
      if (is_array($name)) $name = $name[$language];
      $categoryNames[] = $name;
    }
    return $categoryNames;
  }

  function getCategoryNamesForAttractionType($attractionTypeId, $allCategories, $language) {
    $categoryNames = array();
    foreach ($allCategories as $categoryId => $category) {
      if (in_array($attractionTypeId, $category['Types'])) {
        $name = $category['Name'];
        if (is_array($name)) $name = $name[$language];
        $categoryNames[] = $name;
      }
    }
    return $categoryNames;
  }

  $userId = 'tilman'; // ToDo!
  $home = $_SERVER['DOCUMENT_ROOT'] . '/editor/';
  $userHome = $_SERVER['DOCUMENT_ROOT'] . '/editor/user/' . $userId;
  if (!file_exists($userHome)) mkdir($userHome, 0777);

  $languages = array("en" => array("English", "English.lproj", "en.lproj"), "de" => array("German", "German.lproj", "de.lproj"));
  $language = "en";
  if (isset($_GET['lang'])) $language = $_GET['lang'];
  else if (isset($_POST['lang'])) $language = $_POST['lang'];
  echo '<input type="hidden" name="lang" id="lang" value="', $language , '" />';
  $languageProj = $languages[$language][1];
  $languagePath = $languages[$language][2];

  $KoolControlsFolder = '../../editor/KoolControls';
  require_once('CFPropertyList/CFPropertyList.php');
  echo '<form action="http://www.inpark.info/en/park/" method="post" id="form" name="form" enctype="multipart/form-data">';

  // read types.plist
  $allCategories = array();
  $allParkTypes = array();
  /*$plist = new CFPropertyList($home . "types.plist", CFPropertyList::FORMAT_XML);
  foreach ($plist->getValue() as $key => $value) {
    if ($key == "CATEGORIES") $allCategories = $value;
    else if ($key == "PARK_TYPES") $allParkTypes = $value;
  }*/

  // menu
  $parkIdExist = false;
  if (isset($_GET['park']) || isset($_POST['park'])) {
    $parkId = (isset($_GET['park']))? $_GET['park'] : $_POST['park'];
    $filename = $home . $parkId . '/' . $parkId . '.plist';
    $parkIdExist = file_exists($filename);
  } else if (isset($_POST['kcb_selectedValue'])) {
    $parkId = $_POST['kcb_selectedValue'];
    $filename = $home . $parkId . '/' . $parkId . '.plist';
    $parkIdExist = file_exists($filename);
  }
  if ($parkIdExist == false) {
    require_once('KoolControls/KoolForm/koolform.php');
    //require_once('KoolControls/KoolComboBox/koolcombobox.php');
    require_once('KoolControls/KoolListBox/koollistbox.php');

    $attractionForm = new KoolForm('attractionForm');
    $attractionForm->scriptFolder = $KoolControlsFolder . '/KoolForm';
    $attractionForm->DecorationEnabled = true;
    $attractionForm->styleFolder = 'web20';
    $attractionForm->Init();

    //$kcb = new KoolComboBox('kcb');
    //$kcb->scriptFolder = $KoolControlsFolder . '/KoolComboBox';
    //$kcb->width = '480px';
    //$kcb->styleFolder = 'default';
    //$kcb->headerTemplate = "<table style='width:470px'><tr><td style='background-color:lightgrey;width:185px'><small>Country/City</small></td><td style='background-color:lightgrey;width:280px'><small>Name</small></td></tr></table>";
    //$kcb->itemTemplate = "<table style='width:470px'><tr><td style='width:30px;height:20px'><img src='../../editor/flags/{image}' alt='{country}' title='{country}' /></td><td style='width:150px'>{city}</td><td style='width:290px'>{name}</td></tr></table>";
?>
<p><fieldset style="width:600px;margin-bottom:10px;padding:0px 10px 10px 5px"><legend>Select park</legend>
<table><tr><td>Park name</td><td>
<?php
  //<table cellspacing="5px"><tr><td>Park name</td><td>
  // <select name="park"><option value="dhep">Heide-Park (dhep)</option><option value="dmp">Movie Park Germany (dmp)</option><option value="dphl">Phantasialand (dphl)</option><option value="ep">Europa-Park (ep)</option><option value="fdlp">Disneyland Park Paris (fdlp)</option><option value="fdsp">Walt Disney Studios Park (fdsp)</option><option value="nlde">Efteling (nlde)</option><option value="usdakfl">Disney's Animal Kingdom (usdakfl)</option><option value="usdefl">Epcot (usdefl)</option><option value="usdhsfl">Disney's Hollywood Studios (usdhsfl)</option><option value="usdmkfl">Magic Kingdom (usdmkfl)</option><option value="usuifl">Universal's Islands of Adventure (usuifl)</option><option value="ususfl">Universal Studios Florida (ususfl)</option><option value="usdlca">Disneyland Park (usdlca)</option><option value="usdcaca">Disney California Adventure (usdcaca)</option></select>
  $parkIds = array();
  $d = dir($home . ".");
  while ($entry = $d->read()) {
    if ($entry != "." && $entry != ".." && is_dir($home . $entry)) {
      if (file_exists($home . $entry . "/" . $entry . ".plist")) $parkIds[] = $entry;
    }
  }
  $d->close();
  $sortedParkIds = array();
  $countryLb = $attractionForm->AddControl(new KoolListBox("countryLb"));
  $countryLb->Height = "100px";
  $countryLb->Width = "100px";
  $countryLb->styleFolder = "web20";
  $countryLb->ClientEvents["OnSelect"] = "HandleOnSelectCountry";
  $cityLb = $attractionForm->AddControl(new KoolListBox("cityLb"));
  $cityLb->Height = "100px";
  $cityLb->Width = "150px";
  $cityLb->styleFolder = "web20";
  $parkNameLb = $attractionForm->AddControl(new KoolListBox("parkNameLb"));
  $parkNameLb->Height = "100px";
  $parkNameLb->Width = "250px";
  $parkNameLb->styleFolder = "web20";
  foreach ($parkIds as $parkId) {
    $filename = $home . $parkId . '/' . $parkId . '.plist';
    $plist = new CFPropertyList($filename, CFPropertyList::FORMAT_XML);
    $array = $plist->toArray();
    $country = $array['Land'];
    if (is_array($country)) $country = $country[$language];
    $city = $array['Stadt'];
    if (is_array($city)) $city = $city[$languageProj];
    $parkName = $array['Parkname'];
    if (is_array($parkName)) $parkName = $parkName[$language];
    $key = $country . '.' . $city . '.' . $parkName;
    $imageName = '';
    if ($country == 'USA') $imageName = 'usa_flag.png';
    else if ($country == 'Germany') $imageName = 'germany_flag.png';
    else if ($country == 'France') $imageName = 'france_flag.png';
    else if ($country == 'Netherlands') $imageName = 'netherlands_flag.png';
    $sortedParkIds[$key] = array('image' => $imageName, 'country' => $country, 'city' => $city, 'name' => $parkName.' ('.$parkId.')', 'parkId' => $parkId);
  }
  ksort($sortedParkIds);
  $country = '';
  $city = '';
  foreach ($sortedParkIds as $key => $parkData) {
    if ($country != $parkData['country']) {
      $country = $parkData['country'];
      $item = $countryLb->AddItem(new ListBoxItem($country));
      $item->ImageUrl = "../../editor/flags/" . $parkData['image'];
    }
    if ($city != $parkData['city']) {
      $city = $parkData['city'];
      $cityLb->AddItem(new ListBoxItem(''));
    }
    //$kcb->addItem($parkData['name'], $parkData['parkId'], $parkData);
  }
  $countryLb->Init();
  $cityLb->Init();
  $parkNameLb->Init();
  echo $countryLb->Render(), $cityLb->Render(), $parkNameLb->Render();
  //echo $kcb->Render();
?>
<script type="text/javascript">
function HandleOnSelectCountry(item,arg) {
  var selectedItem = countryLb.get_selected_items()[0];
	var cityItem = cityLb.get_item(0);
  cityItem.set_text();
  cityItem.select();
}
</td><td><input type="submit" value="Next"></td></tr></table></fieldset></p>
<p><fieldset style="width:600px;margin-bottom:10px;padding:0px 10px 10px 5px"><legend>Create new park</legend>
<table cellspacing="5px"><tr><td>Park name</td><td><input id="new_park" name="new_park" type="text" size="80" value=""/></td><td><button disabled>Create</button></td></tr>
</table></fieldset></p>
<?php
    echo $attractionForm->Render();
  } else {
    require_once("KoolControls/KoolTabs/kooltabs.php");
    require_once("KoolControls/KoolUploader/kooluploader.php");

    echo '<input type="hidden" name="park" id="park" value="', $parkId , '" />';
    $selectedTab = "general";
    if (isset($_GET['id'])) $selectedTab = $_GET['id'];
    else if (isset($_POST['kts_selected'])) $selectedTab = $_POST['kts_selected'];

    $requestPath = "http://www.inpark.info/en/park/?park=" . $parkId;
    $kts = new KoolTabs("kts");
    $kts->scriptFolder = $KoolControlsFolder . "/KoolTabs";
    $kts->width = "800px";
    $kts->addTab("root", "general", "General Information", $requestPath . "&id=general", ($selectedTab == "general"));
    $kts->addTab("root", "info", "Park Information", $requestPath . "&id=info", ($selectedTab == "info"));
    $kts->addTab("root", "calendar", "Calendar", $requestPath . "&id=calendar", ($selectedTab == "calendar"));
    $kts->addTab("root", "attractions", "Attractions", $requestPath . "&id=attractions", ($selectedTab == "attractions"));
    $kts->addTab("root", "map", "Map", $requestPath . "&id=map", ($selectedTab == "map"));
    $kts->addTab("root", "news", "News", $requestPath . "&id=news", ($selectedTab == "news"));
    $kts->addTab("root", "templates", "Templates", $requestPath . "&id=templates", ($selectedTab == "templates"));
    $kts->addTab("root", "publish", "Publish", $requestPath . "&id=publish", ($selectedTab == "publish"));
    $kts->styleFolder = "silver";

    echo "<div style=\"padding:10px\">";
		echo $kts->Render();
    echo "</div>";

    if ($selectedTab == "general") {
      $filename = $home . $parkId . "/" . $parkId . ".plist";
      $plist = new CFPropertyList($filename, CFPropertyList::FORMAT_XML);
      $array = $plist->toArray();
      
      echo "<p><table><tr><td>Park name</td><td><input name=\"park_name\" type=\"text\" size=\"50\" value=\"";
      echo $array["Parkname"];
      echo "\"></td></tr><tr><td>Type of park</td><td><b>to be defined</b></td></tr><tr><td>Country</td><td>";
      $selectedCountry = $array['Land'][$language];
      $countryList = array("Afghanistan","Albania","Algeria","Andorra","Angola","Antigua and Barbuda","Argentina","Armenia","Australia","Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados","Belarus","Belgium","Belize","Benin","Bhutan","Bolivia","Bosnia and Herzegovina","Botswana","Brazil","Brunei","Bulgaria","Burkina Faso","Burundi","Cambodia","Cameroon","Canada","Cape Verde","Central African Republic","Chad","Chile","China","Colombi","Comoros","Congo (Brazzaville)","Congo","Costa Rica","Cote d'Ivoire","Croatia","Cuba","Cyprus","Czech Republic","Denmark","Djibouti","Dominica","Dominican Republic","East Timor (Timor Timur)","Ecuador","Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Ethiopia","Fiji","Finland","France","Gabon","Gambia, The","Georgia","Germany","Ghana","Greece","Grenada","Guatemala","Guinea","Guinea-Bissau","Guyana","Haiti","Honduras","Hungary","Iceland","India","Indonesia","Iran","Iraq","Ireland","Israel","Italy","Jamaica","Japan","Jordan","Kazakhstan","Kenya","Kiribati","Korea, North","Korea, South","Kuwait","Kyrgyzstan","Laos","Latvia","Lebanon","Lesotho","Liberia","Libya","Liechtenstein","Lithuania","Luxembourg","Macedonia","Madagascar","Malawi","Malaysia","Maldives","Mali","Malta","Marshall Islands","Mauritania","Mauritius","Mexico","Micronesia","Moldova","Monaco","Mongolia","Morocco","Mozambique","Myanmar","Namibia","Nauru","Nepa","Netherlands","New Zealand","Nicaragua","Niger","Nigeria","Norway","Oman","Pakistan","Palau","Panama","Papua New Guinea","Paraguay","Peru","Philippines","Poland","Portugal","Qatar","Romania","Russia","Rwanda","Saint Kitts and Nevis","Saint Lucia","Saint Vincent","Samoa","San Marino","Sao Tome and Principe","Saudi Arabia","Senegal","Serbia and Montenegro","Seychelles","Sierra Leone","Singapore","Slovakia","Slovenia","Solomon Islands","Somalia","South Africa","Spain","Sri Lanka","Sudan","Suriname","Swaziland","Sweden","Switzerland","Syria","Taiwan","Tajikistan","Tanzania","Thailand","Togo","Tonga","Trinidad and Tobago","Tunisia","Turkey","Turkmenistan","Tuvalu","Uganda","Ukraine","United Arab Emirates","United Kingdom","United States","Uruguay","Uzbekistan","Vanuatu","Vatican City","Venezuela","Vietnam","Yemen","Zambia","Zimbabwe");
      echo "<select name=\"country\" id=\"id_country\">";
      foreach ($countryList as $value) {
        if ($value != $selectedCountry) echo '<option>';
        else echo '<option selected>';
        echo $value, '</option>';
      }
      echo '</select><tr><td>City</td><td><input type="text" name="city" size="50" value="', $array['Stadt'],'"></td></tr>';
      $timezones = array('ADT' => 'America/Halifax','AKDT' => 'America/Juneau','AKST' => 'America/Juneau','ART' => 'America/Argentina/Buenos_Aires','AST' => 'America/Halifax','BDT' => 'Asia/Dhaka','BRST' => 'America/Sao_Paulo','BRT' => 'America/Sao_Paulo','BST' => 'Europe/London','CAT' => 'Africa/Harare','CDT' => 'America/Chicago','CEST' => 'Europe/Paris','CET' => 'Europe/Paris','CLST' => 'America/Santiago','CLT' => 'America/Santiago','COT' => 'America/Bogota','CST' => 'America/Chicago','EAT' => 'Africa/Addis_Ababa','EDT' => 'America/New_York','EEST' =>'Europe/Istanbul','EET' =>'Europe/Istanbul','EST' =>'America/New_York','GMT' => 'GMT','GST' =>'Asia/Dubai','HKT' =>'Asia/Hong_Kong','HST' =>'Pacific/Honolulu','ICT' =>'Asia/Bangkok','IRST' =>'Asia/Tehran','IST' =>'Asia/Calcutta','JST' =>'Asia/Tokyo','KST' =>'Asia/Seoul','MDT' =>'America/Denver','MSD' =>'Europe/Moscow','MSK' =>'Europe/Moscow','MST' =>'America/Denver','NZDT' =>'Pacific/Auckland','NZST' =>'Pacific/Auckland','PDT' =>'America/Los_Angeles','PET' => 'America/Lima','PHT' => 'Asia/Manila','PKT' => 'Asia/Karachi','PST' => 'America/Los_Angeles','SGT' =>'Asia/Singapore','UTC' => 'UTC','WAT' =>'Africa/Lagos','WEST' =>'Europe/Lisbon','WET' => 'Europe/Lisbon','WIT' => 'Asia/Jakarta');
      echo '</td></tr><tr><td>Timezone</td><td><select name="timezone" id="id_timezoyyy444www 1qw4rut9707775t633333333                                                    yaaaaa                    ne">';
      $timezone = $array['Time_zone'];
      foreach ($timezones as $t => $city) {
        if ($timezone == $t) echo '<option selected=selected value="', $t, '">', $city, ' (', $t, ')</option>';
        else echo '<option value="', $t, '">', $city, ' (', $t, ')</option>';
      }
      echo "</select></td></tr><tr><td>Homepage of the park</td><td><b>to be defined in plist</b></td></tr>";
      echo "<tr><td>Seasonal ??</td><td><input type=\"checkbox\" name=\"seasonal\" value=\"seasonal\"></td></tr>";
      echo "<tr><td>Winter opening</td><td><input type=\"checkbox\" name=\"winter_opening\" value=\"winter_opening\"";
      if ($array["Winterplan"]) echo " checked=\"checked\"";
      echo "></td></tr>";
      echo "<tr><td></td><td><input type=\"checkbox\" name=\"wait_times\" value=\"wait_times\"></td></tr>";
      echo "<tr><td>Wait times in min - low</td><td><input type=\"text\" name=\"wait_time_1\" size=\"50\" value=\"";
      echo $array["Wartezeiten"]["1"];
      echo "\"></td></tr>";
      echo "<tr><td>Wait times in min - med</td><td><input type=\"text\" name=\"wait_time_2\" size=\"50\" value=\"";
      echo $array["Wartezeiten"]["2"];
      echo "\"></td></tr>";
      echo "<tr><td>Wait times in min - high</td><td><input type=\"text\" name=\"wait_time_3\" size=\"50\" value=\"";
      echo $array["Wartezeiten"]["3"];
      echo "\"></td></tr>";
      echo "<tr><td>Fastlane</td><td><input type=\"text\" name=\"fast_lane\" size=\"50\" value=\"";
      echo $array["Fast_lane"];
      echo "\"></td></tr>";
      //Maßeinheit (bei Körpergrößen / Beschränkungen)
      //Logo (oder Bild einer typischen Attraktion)
      echo "<tr><td>Logo</td><td><img style=\"width:80px;height:80px\" alt=\"Logo\" src=\"http://www.inpark.info/editor/";
      echo $parkId . "/" . $array["Logo"];
      echo "\"></td>";

      $kul = new KoolUploader("kul");
      $kul->scriptFolder = $KoolControlsFolder . "/KoolUploader";
      $kul->handlePage = "handle.php";
      $kul->allowedExtension = "jpg";
      $kul->maxFileSize = 200*1024; //200kB
      $kul->progressTracking = true;
      $kul->styleFolder = "default";
      //echo $koolajax->Render();
      //echo "<div style=\"padding:10px\">";
      //echo $kul->Render();
      //echo "</div>";
      //<i>*Note:</i> Please test uploading with *.jpg ( dimensions 600x600, size &lt; 200kB )
      echo "</tr></table></p>";
      //</select><input type="submit" value="Update"></p>
    } else if ($selectedTab == "info") {
      require_once("KoolControls/KoolSlideMenu/koolslidemenu.php");

      $selectedFile = "opening";
      if (isset($_GET['info'])) $selectedFile = $_GET['info'];
      $requestPath .= "&id=" . $selectedTab;

      $ksm = new KoolSlideMenu("ksm");
      $ksm->scriptFolder = $KoolControlsFolder . "/KoolSlideMenu";
      $ksm->addParent("root", "english", "English", null, ($language == "en"));
      $ksm->addChild("english", "en_opening", "Opening times", $requestPath . "&lang=en&info=opening");
      $ksm->addChild("english", "en_prices", "Prices", $requestPath . "&lang=en&info=prices");
      $ksm->addChild("english", "en_directions", "Directions", $requestPath . "&lang=en&info=directions");
      $ksm->addChild("english", "en_information", "Information", $requestPath . "&lang=en&info=information");
      $ksm->addParent("root", "german", "German", null, ($language == "de"));
      $ksm->addChild("german", "de_opening", "Opening times", $requestPath . "&lang=de&info=opening");
      $ksm->addChild("german", "de_prices", "Prices", $requestPath . "&lang=de&info=prices");
      $ksm->addChild("german", "de_directions", "Directions", $requestPath . "&lang=de&info=directions");
      $ksm->addChild("german", "de_information", "Information", $requestPath . "&lang=de&info=information");
      $ksm->selectedId = $language . "_" . $selectedFile;
      $ksm->singleExpand = true;
      $ksm->width = "200px";
      $ksm->styleFolder = "bluearrow";
      echo "<table><tr><td valign=top>";
      echo $ksm->Render();
      echo "<p><input type=\"submit\" value=\"Publish\"></p>";
      echo "</td><td><textarea name=\"content\" cols=\"100\" rows=\"40\" class=\"tinymce\">";
      $filename = $home . "../data/" . $parkId . "/" . $languagePath . "/" . $selectedFile . ".txt";
      if (file_exists($filename)) {
        $data = file_get_contents($filename);
        $sEncoding = mb_detect_encoding($data, 'auto', true);
        if ($sEncoding != 'UTF-8') $data = mb_convert_encoding($data, 'UTF-8', $sEncoding);
        echo htmlentities($data);
      }
      echo "</textarea></td></tr></table>";
    } else if ($selectedTab == "calendar") {
      require_once('CalendarData.php');
      require_once("KoolControls/KoolCalendar/koolcalendar.php");
      require_once("KoolControls/KoolAjax/koolajax.php");
      $koolajax->scriptFolder = $KoolControlsFolder . "/KoolAjax";

      $cal = new KoolCalendar("cal");
      $cal->scriptFolder = $KoolControlsFolder . "/KoolCalendar";
      $cal->styleFolder = "default";
      $cal->AjaxEnabled = true;
      $cal->AjaxLoadingImage = $KoolControlsFolder . "/KoolAjax/loading/2.gif";
      $cal->MultiViewColumns = 4;
      $cal->MultiViewRows = 3;
      $cal->EnableMultiSelect = true; //Enable MultiSelection
      $cal->UseColumnHeadersAsSelectors = true; //Able to select multi date by clicking to column header
      $cal->UseRowHeadersAsSelectors = true; //Able to select multi date by clicking to row header
      $cal->ShowViewSelector = true;
      $cal->Init();
      echo "<div style=\"padding-top:20px;padding-bottom:40px;width:650px\">", $koolajax->Render(), $cal->Render(), "</div>";
    } else if ($selectedTab == "attractions") {
      require_once("KoolControls/KoolSlideMenu/koolslidemenu.php");
      require_once("KoolControls/KoolForm/koolform.php");
      require_once("KoolControls/KoolComboBox/koolcombobox.php");
      require_once("KoolControls/KoolListBox/koollistbox.php");

      $fields = array(
                      'Name' => array('id' => 'name', 'label' => 'Name', 'type' => 'text', 'mandatory' => true, 'language' => false),
                      'Themenbereich' => array('id' => 'theme_area', 'label' => 'Theme area', 'type' => 'text', 'mandatory' => true, 'language' => true),
                      // need anything better!
                      '' => array('id' => '', 'label' => 'Category', 'type' => 'label', 'mandatory' => true),
                      'Type' => array('id' => 'type', 'label' => 'Type', 'type' => 'select', 'mandatory' => true),
                      'Kurzbeschreibung' => array('id' => 'description', 'label' => 'Description', 'type' => 'textarea', 'mandatory' => true, 'language' => true),
                      // numeric fields duration, waiting
                      'Thrill-Faktor' => array('id' => 'thrill_factor', 'label' => 'Thrill factor', 'type' => 'select', 'values' => array(0, 1, 2, 3, 4, 5)),
                      'Familien-Faktor' => array('id' => 'water_factor', 'label' => 'Family factor', 'type' => 'select', 'values' => array(0, 1, 2, 3, 4, 5)),
                      'Wasser-Faktor' => array('id' => 'family_factor', 'label' => 'Water factor', 'type' => 'select', 'values' => array(0, 1, 2, 3, 4, 5)),
                      'Zusatzkosten' => array('id' => 'extra_charge', 'label' => 'Extra charge', 'type' => 'checkbox'),
                      //Accessible for wheel chairs respectively handicapped persons
                      'Indoor' => array('id' => 'indoor_attraction', 'label' => 'Indoor attraction', 'type' => 'checkbox'),
                      'Sommer' => array('id' => 'summer_opening', 'label' => 'Summer opening', 'type' => 'checkbox'),
                      'Winter' => array('id' => 'winter_opening', 'label' => 'Winter opening', 'type' => 'checkbox'),
                      'Tourpoint' => array('id' => 'tour_point', 'label' => 'Tour point', 'mandatory' => true, 'type' => 'checkbox'),
                      );
      $templates = array(
                         "name" => "Attraktion", "fields" => array("summer_opening", "winter_opening", "tour_point")
                         );

      $aId = "";
      if (isset($_GET['aid'])) $aId = $_GET['aid'];
      else if (isset($_POST['aid'])) {
        $aId = $_POST['aid'];
      }
      echo '<input type="hidden" name="aid" id="aid" value="', $aId , '" />';
      $selCategoryId = "";
      if (isset($_GET['c'])) $selCategoryId = $_GET['c'];
      else if (isset($_POST['c'])) {
        $selCategoryId = $_POST['c'];
      }
      echo '<input type="hidden" name="c" id="c" value="', $selCategoryId , '" />';
      $requestPath .= "&id=" . $selectedTab;
      $filename = $home . '../data/' . $parkId . '/' . $aId . '/' . $aId . '.txt';
      $fileContent = "";
      if (file_exists($filename)) {
        $fileContent = file_get_contents($filename);
        $files = explode("\n", $fileContent);
        if (isset($_GET['oImg']) && isset($_GET['nImg'])) {
          $i = $_GET['oImg'];
          $j = $_GET['nImg'];
          if ($i != $j) {
            $out = array_splice($files, $i, 1);
            array_splice($files, $j, 0, $out);
            $fileContent = implode("\n", $files);
            file_put_contents($filename, $fileContent);
          }
          return;
        }
      }
      $plist = new CFPropertyList($home . $parkId . "/" . $parkId . ".plist", CFPropertyList::FORMAT_XML);
      $array = $plist->toArray();
      $attractionList = $array["IDs"];
      $types = new CFPropertyList($home . "types.plist", CFPropertyList::FORMAT_XML);
      $types = $types->toArray();
      //$k = array_keys($categories);
      //$v = array_values($categories);
      //array_multisort($k, SORT_ASC, $v, SORT_DESC);
      //$categories = array_combine($k, $v);

      $attractionForm = new KoolForm("attractionForm");
      $attractionForm->scriptFolder = $KoolControlsFolder . "/KoolForm";
      $attractionForm->DecorationEnabled = true;
      $attractionForm->styleFolder = "web20";
      $attractionForm->Init();

      $ksm = new KoolSlideMenu("ksm");
      $ksm->scriptFolder = $KoolControlsFolder . "/KoolSlideMenu";
      $ksm->addParent("root", "new", "New");
      $selectedAId = $aId;
      foreach ($types['CATEGORIES'] as $categoryId => $categoryDetail) {
        $firstCategory = true;
        foreach ($categoryDetail['Types'] as $typeId) {
          $firstType = true;
          $containsAId = false;
          $attractionNames = array();
          foreach ($attractionList as $attractionId => $attraction) {
            $attractionTypeId = $attraction['Type'];
            if (strcmp($attractionTypeId, $typeId) == 0) {
              $name = $attraction['Name'];
              if (is_array($name)) $name = $name[$language];
              $attractionNames[$attractionId] = $name;
              if (!$containsAId && strcmp($attractionId, $aId) == 0) {
                $containsAId = true;
                $selectedAId = $aId.$categoryId;
              }
            }
          }
          asort($attractionNames);
          $categoryName = $categoryDetail['Name'];
          if (is_array($categoryName)) $categoryName = $categoryName[$language];
          foreach ($attractionNames as $attractionId => $attractionName) {
            if ($firstCategory) {
              $ksm->addParent("root", $categoryId, $categoryName, null, (strcmp($selCategoryId, $categoryId) == 0));
              $firstCategory = false;
            }
            if ($firstType) {
              $typeName = $types['TYPES'][$typeId]['Name'];
              if (is_array($typeName)) $typeName = $typeName[$language];
              $ksm->addParent($categoryId, $categoryId.$typeId, $typeName, null, $containsAId);
              $firstType = false;
            }
            $ksm->addChild($categoryId, $attractionId.$categoryId, $attractionName, $requestPath . "&c=" . urlencode($categoryId) . "&aid=" . $attractionId);
          }
        }
      }
      $ksm->selectedId = $selectedAId;
      $ksm->singleExpand = true;
      $ksm->width = "250px";
      $ksm->styleFolder = "bluearrow";
      echo '<table cellspacing="20px"><tr><td valign=top>';
      echo $ksm->Render();
      echo '</td><td valign=top>';
      if (file_exists($filename)) {
        $listbox = $attractionForm->AddControl(new KoolListBox("listbox"));
        $listbox->Height = "100px";
        $listbox->Width = "500px";
        $listbox->styleFolder = "web20";
        foreach ($files as $file) {
          $item = new ListBoxItem($file);
          $item->Value = $file;
          $listbox->AddItem($item);
        }
        //$listbox->AllowMultiSelect = true;
        $listbox->ButtonSettings->ShowDelete = true;
        //$listbox->ButtonSettings->ShowReorder = true;
        $listbox->ClientEvents["OnBeforeDelete"] = "Handle_OnBeforeDelete";
        $listbox->ClientEvents["OnDelete"] = "Handle_OnChange";
        //$listbox->ClientEvents["OnReorder"] = "Handle_OnChange";
        $listbox->Init();
        echo '<style type="text/css">.box{float:left;padding:5px;background:#DFF3FF;border:solid 1px #C6E1F2;min-height:85px;margin:5px}.clear{clear:both}</style>';
        //<div style="width:660px;margin-bottom:20px;">
        echo '<script src="http://code.jquery.com/ui/1.10.2/jquery-ui.js"></script>';
        echo '<style>#sortable{list-style-type:none;margin:0;padding:0;width:500px}#sortable li{margin:3px 3px 3px 0;padding:1px;float:left;width:100px;height:100px}</style>';
        //echo '<script>$(function() {$( "#sortable" ).sortable();$( "#sortable" ).disableSelection();});</script>';
        echo '<fieldset style="width:500px;margin-bottom:10px;padding:0px 10px 10px 5px"><legend>Images</legend><table><tr><td valign=top;width=100%>Add new image: <input type="file" name="images[]" onchange="Handle_OnChange()" multiple="multiple"></td></tr><tr><td>';
        $files2 = array();
        foreach ($listbox->Items as $item) $files2[] = $item->Text;
        $fileContent2 = implode("\n", $files2);
        if ($fileContent != $fileContent2) {
          file_put_contents($filename, $fileContent2);
          foreach ($files as $file) {
            if (!in_array($file, $files2)) unlink($home . '../data/' . $parkId . '/' . $aId . '/' . $file);
          }
          $files = $files2;
        }
        if (isset($_FILES['images'])) {
          $allowedExts = array('jpg', 'jpeg', 'gif', 'png');
          foreach ($_FILES['images']['name'] as $i => $file) {
            if ($_FILES['images']['error'][$i] > 0) {
              if ($_FILES['images']['error'][$i] != 4) echo 'Upload error: ', $file, '<br/>Return code: ', $_FILES['images']['error'][$i], '<br/>';
            } else if (count($listbox->Items) >= 15) {
              echo 'Upload error: ', $file, '<br/>Max 15 images per attraction allowed<br/>';
              break;
            } else {
              $extension = end(explode('.', $file));
              $fileType = $_FILES['images']['type'][$i];
              // ToDo: not more than 15 images per txt file
              if (($fileType == 'image/gif' || $fileType == 'image/jpeg' || $fileType == 'image/png' || $fileType == 'image/pjpeg') && $_FILES['images']['size'][$i] < 1000000 && in_array($extension, $allowedExts)) {
                $imageFilename = $home . '../data/' . $parkId . '/' . $aId . '/' . $file;
                if (file_exists($imageFilename)) {
                  echo 'Upload error: ', $file, ' already exists.<br/>';
                } else {
                  move_uploaded_file($_FILES['images']['tmp_name'][$i], $imageFilename);
                  $files[] = $file;
                  $item = new ListBoxItem($file);
                  $item->Value = $file;
                  $listbox->AddItem($item);
                  $fileContent = implode("\n", $files);
                  file_put_contents($filename, $fileContent);
                }
              } else if ($file != '') {
                echo 'Invalid file ', $file, ' or larger 1MB<br/>';
              }
            }
          }
        }
        echo '<ul id="sortable">';
        $base = '<li class="ui-state-default"><div class="box"><a href="http://www.inpark.info/data/' . $parkId . '/' . $aId . '/';
        foreach ($files as $file) {
          echo $base, $file, '"><img class="size-medium colorbox-32" title="', $file, '" src="http://www.inpark.info/data/', $parkId, '/', $aId, '/', $file, '" width="80" height="80"/></a></div></li>';
        }
        echo '</ul></td></tr><tr><td>';
        echo $listbox->Render(), '</td></tr></table></fieldset>';
        //echo $listbox->Render(), '</td></tr></table><hr/><p><input type="submit" value="Update"><div id="update_notification" style="color:red"></div></p></fieldset>';
        //echo '<script type="text/javascript">function Handle_OnBeforeDelete(item,args){if(listbox.get_items().length>1)return true;alert("At least one image must exist!");return false;}function Handle_OnChange(item,arg){document.getElementById("update_notification").innerHTML+="<b>needed!</b>";document.getElementById("update_notification").scrollTop=9999;}</script>';
        echo '<script type="text/javascript">function Handle_OnBeforeDelete(item,args){if(listbox.get_items().length>1)return true;alert("At least one image must exist!");return false;}function Handle_OnChange(item,arg){document.forms["form"].submit();}';
        // document.location.reload(true)
        echo '$(function(){$("#sortable").sortable({start:function(e,ui){$(this).attr("previdx",ui.item.index());},update:function(e,ui){var newIdx=ui.item.index();var oldIdx=$(this).attr("previdx");$(this).removeAttr("previdx");var xmlHttp=new XMLHttpRequest();xmlHttp.open("GET","', $_SERVER['REQUEST_URI'], '&oImg="+oldIdx+"&nImg="+newIdx,false);xmlHttp.send(null);listbox.mov_item(oldIdx,newIdx);}});$("#sortable").disableSelection();});</script>';
      }

      if (isset($attractionList[$aId])) {
        $attraction = $attractionList[$aId];
        echo '<fieldset style="width:500px;margin-bottom:10px;padding:0px 10px 10px 5px"><legend>Information</legend>';
        echo '<style type="text/css">.clear{clear:both}.columnLast{width:16px;float:left}.column{float:left;width:150px}.header.column{padding-left:5px}.header{border-bottom:solid 1px #BBBBBB;background:url(../../editor/background.png);height:20px;line-height:20px}</style>';
        echo '<table style="border-collapse:separate;border-spacing:4px">';

        $addButton = false;
        foreach ($fields as $pid => $field) {
          if ($pid == '' || isset($attraction[$pid])) {
            $type = $field['type'];
            if ($field['mandatory']) echo '<tr><td></td>';
            else echo '<tr><td><input type="image" src="../../editor/delete.png" width="15" height="15"></td>';
            //<button name=\"delete\" type=\"button\" value=\"Delete\" onclick=\"alert('Delete!');\"><img src=\"../../editor/delete.png\" width=\"15\" height=\"15\" alt=\"Delete\"></button></td>";
            // ToDo: REMOVE
            if ($type == "text") {
              $value = $attraction[$pid];
              if (is_array($value)) {
                echo '<td>', $field['label'], ':</td></tr>';
                foreach ($value as $valueId => $lValue) {
                  foreach ($languages as $languageId => $languageArray) {
                    if (strcmp($languageArray[1], $valueId) == 0) {
                      echo '<tr><td></td><td>&nbsp;&nbsp;', $languageArray[0], '</td><td><input id="', $languageId, '_', $field['id'], '" name="', $languageId, '_', $field['id'], '" type="text" style="width:350px;padding:2px;border:1px solid black" value="', $lValue, '"/></td></tr>';
                      break;
                    }
                  }
                }
              } else {
                echo '<td>', $field['label'], ':</td><td><input id="field_', $field['id'], '" name=field_"', $field['id'], '" type="text" style="width:350px;padding:2px;border:1px solid black" value="', $value, '"/></td></tr>';
              }
            } else if ($type == 'textarea') {
              $value = $attraction[$pid];
              if (is_array($value)) {
                echo '<td>', $field['label'], ':</td></tr>';
                foreach ($value as $valueId => $lValue) {
                  foreach ($languages as $languageId => $languageArray) {
                    if (strcmp($languageArray[1], $valueId) == 0) {
                      echo '<tr><td></td><td valign=top>&nbsp;&nbsp;', $languageArray[0], '</td><td><textarea name="', $languageId, '_', $field['id'], '" style="width:350px;height:50px">', $lValue, '</textarea></td></tr>';
                      break;
                    }
                  }
                }
              } else {
                echo '<td>', $field['label'], ':</td><td><textarea name="field_', $field['id'], '" style="width:350px;height:50px">', $value, '</textarea></td></tr>';
              }
            } else if ($type == 'label') {
              // ToDo: not fix $selCategory
              echo '<td>', $field['label'], ':</td><td>', $selCategoryId, '</td></tr>';
            } else if ($type == 'checkbox') {
              echo '<td><label for="', $field['id'], '">', $field['label'], ':</label></td><td><input id="', $field['id'], '" name="field_', $field['id'], '" type="checkbox"';
              if ($attraction[$pid] == true) echo ' checked';
              echo ' /></td></tr>';
            } else if ($type == 'select') {
              echo '<td>', $field['label'], ':</td><td>';
              // ToDo: alert if value not in list
              $value = $attraction[$pid];
              if (isset($field['values'])) {
                echo '<select id="', $field['id'], '" name=field_"', $field['id'], '">';
                $values = $field['values'];
                foreach ($values as $v) {
                  if ($v == $value) echo '<option selected>', $v, '</option>';
                  else echo '<option>', $v, '</option>';
                }
                echo '</select>';
              } else {
                $kcb = new KoolComboBox("kcb");
                $kcb->scriptFolder = $KoolControlsFolder . "/KoolComboBox";
                $kcb->width = "350px";
                $kcb->styleFolder = "default";
                $kcb->headerTemplate = "<div class='header'><div class='column'>Category</div><div class='column'>Type</div><div class='columnLast'>&nbsp;</div><div class='clear' /></div>";
                $kcb->itemTemplate = "<div class='column'>{category}</div><div class='column'>{type}</div>";
                if (is_array($value)) $value = $value[$language];
                foreach ($types['TYPES'] as $typeId => $typeDetails) {
                  $typeName = $typeDetails['Name'];
                  if (is_array($typeName)) $typeName = $typeName[$language];
                  $kcb->addItem($typeId, $typeId, array('category' => '', 'type' => $typeName), (strcmp($value, $typeId) == 0));
                  //$kcb->addItem($type, $type, array('category' => $category, 'type' => $type), (strcmp($value, $type) == 0));
                    //if (strcmp($value, $type) == 0) echo '<option selected>', $type, '</option>';
                    //else if (!strstr($type, '.png')) echo '<option>', $type, '</option>';  // ToDo. png filter not generic!
                }
                echo $kcb->Render();
              }
              echo '</td></tr>';
            }
          } else {
            $addButton = true;
          }
        }
        
        echo "</table>";

        if ($addButton) {
          echo '<hr/><table cellspacing="7px"><tr><td>Add new field</td><td><select id="add_field">';
          foreach ($fields as $pid => $field) {
            if ($pid != '' && !isset($attraction[$pid])) {
              echo '<option>', $field['label'], '</option>';
            }
          }
          echo '</select></td><td><input type="image" src="../../editor/add.png" width="15" height="15"></td></tr></table>';
          //<button name=\"add\" type=\"button\" value=\"Add\" onclick=\"alert('Add!');\"><img src=\"../../editor/add.png\" width=\"15\" height=\"15\" alt=\"Add\"></button></p>";
        }
        echo '<hr/><p><input type="submit" value="Update"></p>', $attractionForm->Render(), '</fieldset>';
      }
      /*require_once("KoolControls/KoolListBox/koollistbox.php");
      require_once("KoolControls/KoolAjax/koolajax.php");
      require_once("KoolControls/KoolGrid/koolgrid.php");
      $listbox = new KoolListBox("listbox");
      $listbox->Height = "500px";
      $listbox->Width = "250px";
      $listbox->styleFolder = "web20";
      $attractionNames = array();
      foreach ($attractionList as $attractionId => $attraction) {
        $name = $attraction["Name"];
        if (is_array($name)) $name = $name[$language];
        $attractionNames[$attractionId] = $name;
      }
      asort($attractionNames);
      foreach ($attractionNames as $attractionId => $attractionName) {
        $item = new ListBoxItem($attractionName);
        $item->Value = $attractionId;
        $listbox->AddItem($item);
      }*/
      //$stack = array("orange", "banana");
      //array_push($stack, "apple", "raspberry");
      // unset($arr[5]); // This removes the element from the array
      //$listbox->ButtonSettings->ShowDelete = true;
      //$listbox->Init();
      echo "</div></td></tr></table>";
    } else if ($selectedTab == "map") {
    } else if ($selectedTab == "templates") {

    } else if ($selectedTab == "publish") {
    }
  }
?>
</form>