<?php

require_once('inc/common.php');

echo $twig->render('welcome.html.twig', array(
		 'selected' => 'About',
		 'show_in_result' => null,
		 'table_fields' => null,
		 'message' => $message
		));