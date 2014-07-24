<?php

require_once('inc/common.php');

echo $twig->render('videos.html.twig', array(
    'selected' => 'Videos',
    'show_in_result' => null,
    'table_fields' => null,
    'message' => $message
));