<?php

namespace alojaweb\Router;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Yaml\Yaml;

class Router
{
    /**
	 * @var \Monolog\Logger
	 */
    private $logger;

    /**
	 * @var \Symfony\Component\HttpFoundation\Request
	 */
    private $request;

    /**
	 * @var array
	 */
    private $routesCollection;

    public function __construct(\Monolog\Logger $logger, \Symfony\Component\HttpFoundation\Request $request)
    {
        $this->logger = $logger;
        $this->request = $request;
    }

    public function loadRoutesFromFile($file)
    {
        if (!$this->validateRouteFileSyntax($file)) {
            $this->logger->addError('The router YAML isn\'t correct');
            throw new \Exception('The router YAML file isn\'t correct');
        }
        $this->routesCollection = Yaml::parse($file);
    }

    /**
	 * @throws \Exception
	 * @return array:
	 */
    public function getControllerMethod($uri = null)
    {
        try {
            $result = false;
            $givenRoute = ($uri == null ) ? $this->request->getPathInfo() : $uri;
            foreach ($this->routesCollection as $route) {
                if (!$result && $route['pattern'] == $givenRoute) {
                    $controller = $route['controller'];
                    $class = explode('::',$controller)[0];
                    $method = explode('::',$controller)[1];
                    if (!class_exists($class)) {
                        throw new \Exception('The route class doesn\'t exist!');
                    } else if(!method_exists($class,$method))
                        throw new \Exception('The route class\'s method doesn\'t exist!');

                    $this->logger->addInfo("Route controller method found: $class -> $method");

                    $result = array('class' => $class, 'method' => $method);
                }
            }
            if(!$result)
              throw new \Exception('Route not found');
            else
              return $result;
        } catch (\Exception $e) {
            $this->logger->addError('Error handling route: '.$e->getMessage());
            throw new \Exception($e->getMessage(),$e->getCode(),$e->getPrevious());
        }
    }

    public function validateRouteFileSyntax($file)
    {
        $routesCollection = Yaml::parse($file);
        if (!is_array($routesCollection)) {
            $this->logger->addError('The router file doesn\'t have an aproppiate syntax. ');

            return false;
        }

        foreach ($routesCollection as $name => $route) {
            if (!isset($route['pattern']) || !isset($route['controller'])) {
                $this->logger->addError('The router file doesn\'t have an aproppiate syntax. '
                        . 'Check that both pattern and controller are defined for routes');

                return false;
            }

            $controller = $route['controller'];
            if (!preg_match('~([a-zA-Z0-9]+\\\\)*[a-zA-Z0-9]+::[a-zA-Z0-9]+Action$~',$controller)) {
                $this->logger->addError('The controller name for route '.$name.' isn\'t correct, check your syntax');

                return false;
            }
        }

        return true;
    }

    public function getRouteName($route)
    {
        if(isset($this->routesCollection[$route]))

            return $this->routesCollection[$route];
        else {
            $this->logger->addError('The requested route doesn\'t exist');

            return null;
        }
    }
    
    public function getLegacyRoute($givenRoute) {
    	try {
    		$result = false;
    		foreach ($this->routesCollection as $route) {
    			if (!$result && (isset($route['legacy']) && $route['legacy'] == $givenRoute)) {
    				$result = true;
    				$controller = $route['controller'];
    				$class = explode('::',$controller)[0];
    				$method = explode('::',$controller)[1];
    				if (!class_exists($class)) {
    					throw new \Exception('Legacy The route class doesn\'t exist!');
    				} else if(!method_exists($class,$method))
    					throw new \Exception('Legacy The route class\'s method doesn\'t exist!');
    				
    				$this->logger->addInfo("Legacy Route controller method found: $class -> $method");
    				
    				$result = array('pattern' => $route['pattern'], 'class' => $class, 'method' => $method);
    			}
    		}
    		if(!$result)
    			return null;
    		else
    			return $result;
    	} catch (\Exception $e) {
    		$this->logger->addError('Error handling route: '.$e->getMessage());
    		throw new \Exception($e->getMessage(),$e->getCode(),$e->getPrevious());
    	}
    }

}
