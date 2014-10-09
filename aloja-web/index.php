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
    if(isset($_GET['c']) && $_GET['c'] == '404') {
    	unset($_GET['c']);
    	$controllerMethod = (isset($_GET['q'])) ? $router->getLegacyRoute($_GET['q']) : null;
    	if($controllerMethod != null) {
    		header("Location: http://${_SERVER['HTTP_HOST']}${controllerMethod['pattern']}",true,303);
    		die();
    		$container->getLog()->addDebug('Legacy route detected');
    		$container->getTwig()->addGlobal('message',
    				"You accessed this page through an old link, new link is at: "
    				.$controllerMethod['pattern']."\n");
    	} else  {
    		$container->getLog()->addError('404 page not found');
    		$container->displayServerError('Page not found');
    		exit;
    	}
    } else
   		 $controllerMethod = $router->getControllerMethod();
    
    //TODO inject dependencies from a dependency description file or sth like that
    $controller = new $controllerMethod['class']($container);
    $controller->$controllerMethod['method']();
} catch (\Exception $e) {
    if($container->get('config')['enable_debug'])
      exit('Unexpected error: '.$e->getMessage(). "\n".$e->getPrevious());
    else {
      $container->getLog()->addError('Internal server error: '.$e->getMessage(). "\n".$e->getPrevious());
      $container->displayServerError();
    }
}
