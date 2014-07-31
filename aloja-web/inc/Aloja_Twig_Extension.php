<?php
class Aloja_Twig_Extension extends Twig_Extension
{
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
	
	public static function makeTooltip($tooltip) {
		return '<img class="tooltip2" src="img/info_small.png" style="width: 10px; height: 10px; margin-bottom: 1px; margin-left: 2px;" data-toggle="tooltip" data-placement="top" data-title="'.$tooltip.'"></img>';
	}
	
	public function modifyUrl($mod) {
			$url = $this->full_url($_SERVER);
	
			$query = explode("&", $_SERVER['QUERY_STRING']);
			if (!$_SERVER['QUERY_STRING']) {$queryStart = "?";} else {$queryStart = "&";}
			// modify/delete data
			foreach($query as $q)
			{
				if ($q) {
					list($key, $value) = explode("=", $q);
					if(array_key_exists($key, $mod))
					{
						if($mod[$key])
						{
							$url = preg_replace('/'.$key.'='.$value.'/', $key.'='.$mod[$key], $url);
						}
						else
						{
							$url = preg_replace('/&?'.$key.'='.$value.'/', '', $url);
						}
					}
				}
			}
			// add new data
			foreach($mod as $key => $value)
			{
				if($value && !preg_match('/'.$key.'=/', $url))
				{
					$url .= $queryStart.$key.'='.$value;
				}
			}
	
			//remove first directory to fix "redirection" in hadoop.bsc.es
			if (strpos($url, '.php')) {
				$url = substr($url, strpos($url, basename($url)));
			}
	
			return $url;
	}
	

	public function makeExecs(array $execs) {
		$return = '';
		foreach ($execs as $exec) {
			$return .= '&execs[]='.$exec;
		}
		return $return;
	}
}