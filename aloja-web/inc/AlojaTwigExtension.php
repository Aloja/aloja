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
                'path' => new Twig_Function_Method($this, 'path')
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
}
