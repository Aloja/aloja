<?php

require_once __DIR__.'/vendor/autoload.php';

spl_autoload_register(function ($file) {
    if(substr($file,0,9) === "alojaweb\\")
        $file = substr($file,9);

    $file = str_replace('\\','/',$file).'.php';

    // This has to be @include_once instead of require_once
    // http://stackoverflow.com/a/25891686/2948495
    @include_once $file;
});
