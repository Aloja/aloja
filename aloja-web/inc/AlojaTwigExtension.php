<?php

namespace alojaweb\inc;

use Twig_Extension;
use Twig_Function_Method;
use Twig_Error_Runtime;
use alojaweb\Router\Router;

class AlojaTwigExtension extends Twig_Extension
{
    /**
	 * @var \alojaweb\Router\Router
	 */
    private $router;

    public function __construct(\alojaweb\Router\Router $router)
    {
        $this->router = $router;
    }

    public function getName()
    {
        return 'aloja';
    }

    public function getFunctions()
    {
        return array(
                'modifyUrl' => new Twig_Function_Method($this, 'modifyUrl'),
                'makeTooltip' => new Twig_Function_Method($this, 'makeTooltip'),
                'makeExecs' => new Twig_Function_Method($this, 'makeExecs'),
                'path' => new Twig_Function_Method($this, 'path'),
        		'getArrayIndex' => new Twig_Function_Method($this, 'getArrayIndex'),
        		'getParamevalTitleName' => new Twig_Function_Method($this, 'getParamevalTitleName'),
        		'getDisksName' => new Twig_Function_Method($this, 'getDisksName'),
        );
    }

    private function url_origin($s, $use_forwarded_host=false)
    {
        $ssl = (!empty($s['HTTPS']) && $s['HTTPS'] == 'on') ? true:false;
        $sp = strtolower($s['SERVER_PROTOCOL']);
        $protocol = substr($sp, 0, strpos($sp, '/')) . (($ssl) ? 's' : '');
        $port = $s['SERVER_PORT'];
        //$port = ((!$ssl && $port=='80') || ($ssl && $port=='443')) ? '' : ':'.$port;
        $host = ($use_forwarded_host && isset($s['HTTP_X_FORWARDED_HOST'])) ? $s['HTTP_X_FORWARDED_HOST'] : (isset($s['HTTP_HOST']) ? $s['HTTP_HOST'] : $s['SERVER_NAME']);

        return $protocol . '://' . $host ;//. $port;
    }

    private function full_url($s, $use_forwarded_host=false)
    {
        return $this->url_origin($s, $use_forwarded_host) . $s['REQUEST_URI'];
    }

    public static function makeTooltip($tooltip)
    {
        return '<img class="tooltip2" src="img/info_small.png" style="width: 10px; height: 10px; margin-bottom: 1px; margin-left: 2px;" data-toggle="tooltip" data-placement="top" data-title="'.$tooltip.'"></img>';
    }

    public function modifyUrl($mod)
    {
            $url = $this->full_url($_SERVER);

            $query = explode("&", $_SERVER['QUERY_STRING']);
            if(isset($_GET['q']) && $_GET['q'] == '/'.explode('/',$url)[3])
                $queryStart = '?';
            else if (!$_SERVER['QUERY_STRING']) {
                $queryStart = "?";
            } else {
                $queryStart = "&";
            }

            // modify/delete data
            foreach ($query as $q) {
                if ($q) {
                    list($key, $value) = explode("=", $q);
                    if (array_key_exists($key, $mod)) {
                        if ($mod[$key]) {
                            $url = preg_replace('/'.$key.'='.$value.'/', $key.'='.$mod[$key], $url);
                        } else {
                            $url = preg_replace('/&?'.$key.'='.$value.'/', '', $url);
                        }
                    }
                }
            }
            // add new data
            foreach ($mod as $key => $value) {
                if ($value && !preg_match('/'.$key.'=/', $url)) {
                    $url .= $queryStart.$key.'='.$value;
                }
            }

            //remove first directory to fix "redirection" in hadoop.bsc.es
            if (strpos($url, '.php')) {
                $url = substr($url, strpos($url, basename($url)));
            }

            return $url;
    }

    public function makeExecs(array $execs)
    {
        $return = '';
        foreach ($execs as $exec) {
            $return .= '&execs[]='.$exec;
        }

        return $return;
    }

    public function path($routeName, $options = null)
    {
        $route = $this->router->getRouteName($routeName);
        if ($route != null) {
            $url = $route['pattern'];
            if ($options != null && is_array($options)) {
                $first = true;
                foreach ($options as $name => $value) {
                  if (is_string($value)) {
                    if ($first) {
                        $url.='?';
                        $first = false;
                    } else $url.='&';

                    $url .= "$name=$value";
                  }
                }
            }

            return $url;
        } else
            throw new Twig_Error_Runtime('There\'s no route with this name');
    }
    
    public function getArrayIndex($array, $valueToFind)
    {
    	if(!is_array($array))
    		throw new \Exception('Expected array in first argument');
    	
    	if(!in_array($valueToFind,$array))
    		throw new \Exception('Value doesn\'t exists in the given array');
    	
    	$count = 0;
    	foreach($array as $value)
    	{
    		if($value == $valueToFind)
    			return $count;
    		
    		$count++;
    	}
    	
    	return 0;
    }
    
    public function getParamevalTitleName($paramEval)
    {
    	$title = '';
    	if($paramEval == 'maps')
			$title = 'Number of maps';
		else if($paramEval == 'comp')
			$title = 'Compression';
		else if($paramEval == 'net')
			$title = 'Network';
		else if($paramEval == 'disk')
			$title = 'Disks';
		else if($paramEval == 'replication')
			$title = 'Replication level';
		else if($paramEval == 'iofilebuf')
			$title = 'I/O File Buffer size';
		else if($paramEval == 'blk_size')
			$title = 'HDFS block size';
		else if($paramEval == 'iosf')
			$title = 'I/O Sort Factor';
		else if($paramEval == 'vm_ram')
			$title = 'RAM GB';
		else if($paramEval == 'vm_cores')
			$title = 'Number of cores';
		else if($paramEval == 'datanodes')
			$title = 'Number of datanodes';
		else if($paramEval == 'vm_size')
			$title = 'VM size';
		else if($paramEval == 'hadoop_version')
			$title = 'Hadoop version';
		else if($paramEval == 'type')
			$title = 'Cluster type';
		else if($paramEval == 'id_cluster')
			$title = 'Cluster';
		else
			$title = $paramEval;
		
		return $title;
    }
    
    public function getDisksName($diskName)
    {
    	return Utils::getDisksName($diskName);
    }
}
