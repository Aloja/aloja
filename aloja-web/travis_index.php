<?php
if (preg_match('/\.(?:png|jpg|jpeg|gif|js|css)$/', $_SERVER["REQUEST_URI"])) {
    return false;
}
else if (preg_match('/\.php$/',$_SERVER['REQUEST_URI'])  && file_exists(ltrim($_SERVER['REQUEST_URI'],'/'))) {
  return false;
}
$explode = explode('/',$_SERVER['REQUEST_URI']);
if(isset($explode[1])) {
   $exp = explode('?',$explode[1]);
   $_GET['q'] = $exp[0];
}
include __DIR__ . '/index.php';
