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
    $container = new Container();           // this loads config.yml

    // check whether the user is accessing a protected page and is authenticated

    // extract first portion
    $uri = explode('/', $_SERVER['REQUEST_URI'])[1];
    // remove arguments if any
    $uri = preg_replace('/\?.*/', '', $uri);

    if (array_key_exists($uri, $container->get('config')['protected_urls'] ) &&
        
       ( !isset($_SERVER['PHP_AUTH_USER']) || !isset($_SERVER['PHP_AUTH_PW']) ||
         $_SERVER['PHP_AUTH_USER'] != $container->get('config')['protected_user'] ||
         $_SERVER['PHP_AUTH_PW'] != $container->get('config')['protected_pass'] )) {

          // No credentials found - send an unauthorized challenge response
          header('WWW-Authenticate: Basic realm="Aloja"');
          header('HTTP/1.0 401 Unauthorized');
          // This is displayed if the user cancels the challenge
          echo('You need a username and password to access this page');
          exit;
    }

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
    if($container) {
        if ($container->get('config')['enable_debug'])
            exit('Unexpected error: '.$e->getMessage(). "\n".$e->getPrevious());
        else {
            $container->getLog()->addError('Internal server error: '.$e->getMessage(). "\n".$e->getPrevious());
            $container->displayServerError();
        }
    } else {
       echo 'Unexpected error: '.$e->getMessage(). "\n".$e->getPrevious();
    }

}
