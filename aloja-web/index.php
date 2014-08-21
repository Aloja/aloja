<?php
require_once 'vendor/autoload.php';

spl_autoload_register(function ($file) {
    if(substr($file,0,9) === "alojaweb\\")
        $file = substr($file,9);

    $file = str_replace('\\','/',$file).'.php';
    require_once $file;
});

use alojaweb\Container\Container;

try {
    $container = new Container();
    $router = $container->getRouter();
    $router->loadRoutesFromFile('config/router.yml');
    $controllerMethod = $router->getControllerMethod();
    //TODO inject dependencies from a dependency description file or sth like that
    $controller = new $controllerMethod['class']($container);
    $controller->$controllerMethod['method']();
} catch (\Exception $e) {
    if($container->get('config')['enable_debug'])
      exit('FATAL ERROR '.$e->getMessage(). "\n".$e->getPrevious());
    else
      $container->displayServerError();
}
