<?php

if(!$_COOKIE['rememberme']) {
   require_once('inc/common.php');
?>

<?=make_HTML_header()?>

<?=make_header('Welcome to HiBench Executions on Hadoop', $message)?>
 
<p>This site use cookies to improve user experience. Do you allow us to store them?</p>
<a href="index_2.php?save_cookies=true">Yes</a><a href="index_2.php">No, proceed to main page</a>
    
<?=$footer?>

<?php 
  } else {
  	require_once('datatable.php');
  	
  }
?>
