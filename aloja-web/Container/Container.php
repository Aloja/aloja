<?php

namespace alojaweb\Container;

use Pimple\Container as PimpleContainer;
use Symfony\Component\Yaml\Yaml;
use Symfony\Component\HttpFoundation\Request;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Twig_Loader_Filesystem;
use Twig_Environment;
use Twig_Extension_Debug;
use alojaweb\inc\AlojaTwigExtension;
use alojaweb\inc\DBUtils;
use alojaweb\Router\Router;

class Container
{
    private $container;

    /**
	 * @return checks if we are in development environment
	 */
    public function in_dev()
    {
        if (is_dir('/vagrant')) return true;

        if (isset($_SERVER['HTTP_CLIENT_IP'])
                || isset($_SERVER['HTTP_X_FORWARDED_FOR'])
                || !in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', 'fe80::1', '::1', '10.0.2.2', '192.168.99.1'))) {
              return false;
        } else
              return true;
    }

    public function __construct()
    {
        $container = new PimpleContainer();
        if ($this->in_dev()) {
            ini_set('display_errors', 'On');
            error_reporting(E_ALL);
            //ini_set('memory_limit', '512M');
            $config_file='config/config.sample.yml';
            if (! file_get_contents($config_file)) {
                throw new \Exception("Cannot read configuration file: $config_file, check that it exists!");
            }
            $container['config'] = Yaml::parse(file_get_contents($config_file));
            $container['env'] = 'dev';
        } else {
            //ini_set('display_errors', 'On');
            //error_reporting(E_ALL);
            //ini_set('memory_limit', '1024M');
            $config_file='config/config.yml';
            if (! file_get_contents($config_file)) {
                throw new Exception("Cannot read configuration file: $config_file, check that it exists!");
            }
            $container['config'] = Yaml::parse(file_get_contents($config_file));
            $container['env'] = 'prod';
        }

        if(!$container['config']['show_warnings']) {
           error_reporting(E_ERROR | E_PARSE);
        }

        $container['log'] = function ($c) {
            $logLevel = ($c['env'] == 'dev') ? Logger::DEBUG : Logger::WARNING;
            // create a log channel
            $log = new Logger('aloja');
            $log->pushHandler(new StreamHandler("logs/aloja_{$c['env']}.log", $logLevel));

            return $log;
        };

        $container['db'] = function ($c) {
            $db = new DBUtils($c);

            return $db;
        };
        $container['request'] = Request::createFromGlobals();
        $container['router'] = function ($c) {
            $router = new Router($c['log'],$c['request']);

            return $router;
        };
        $container['twig'] = function ($c) {
            $loader = new Twig_Loader_Filesystem($c['config']['twig_views_path']);
            $twigOptions = array('debug' => $c['config']['enable_debug']);
            if($c['config']['in_cache'])
                $twigOptions['cache'] = $c['config']['twig_cache_path'];

            $twig = new Twig_Environment($loader, $twigOptions);
            $twig->addExtension(new AlojaTwigExtension($c['router']));
            if($c['config']['enable_debug'])
                $twig->addExtension(new Twig_Extension_Debug());

            //Twig globals initialization
            $twig->addGlobal('request',$c['request']);
            $twig->addGlobal('PROD',$c['env']==='prod');
            $twig->addGlobal('DEV',$c['env']==='dev');
//             $twig->addGlobal('message',null);
            return $twig;
        };

        $this->container = $container;
    }

    /**
	 * @return \Symfony\Component\HttpFoundation\Request
	 */
    public function getRequest()
    {
        return $this->container['request'];
    }

    /**
	 * @return \Monolog\Logger
	 */
    public function getLog()
    {
        return $this->container['log'];
    }

    /**
	 * @return \alojaweb\Router\Router
	 */
    public function getRouter()
    {
        return $this->container['router'];
    }

    /**
     * @return \Twig_Environment
     */
    public function getTwig()
    {
        return $this->container['twig'];
    }

    /**
     * @return \alojaweb\inc\DBUtils
     */
    public function getDBUtils()
    {
        return $this->container['db'];
    }

    /**
	 *
	 * @param string $parameter
	 * @return the requested $parameter service
	 * @throws \Exception
	 */
    public function get($parameter)
    {
        if(isset($this->container[$parameter]))

            return $this->container[$parameter];
        else
            throw new \Exception('This container hasn\'t this service');
    }

    public function displayServerError($message = 'We are sorry an internal error ocurred. Try it again later')
    {
        echo $this->container['twig']->render('server_error.html.twig', array(
        	'message' => $message
        ));
    }

    /**
     * @return string Current screen name
     */
    public function getScreenName() {
        if(isset($this->container['routeScreenName']))
            return $this->container['routeScreenName'];
        else {
            $this->container['routeScreenName'] = $this->container['router']->getRouteScreenName();
            return $this->container['routeScreenName'];
        }
    }
}
