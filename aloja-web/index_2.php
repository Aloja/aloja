<?php
  if($_GET['save_cookies'] == 'yes')
  	setcookie('rememberme', true, time() + 3600);
  
require_once 'datatable.php';
