<?php
require_once 'vendor/autoload.php';

spl_autoload_register(function ($file) {
	if(substr($file,0,9) === "alojaweb\\")
		$file = substr($file,9);

	$file = str_replace('\\','/',$file).'.php';
	require_once $file;
});

use Symfony\Component\Yaml\Yaml;

if(count($argv) < 2)
	exit('You must indicate either "dev" or "prod" parameters to select environment'."\n");
else
	$env = $argv[1];

$conf = array();
if($env == 'dev')
	$conf = Yaml::parse('config/config.sample.yml');
else
	$conf = Yaml::parse('config/config.yml');

exec("rm ${conf['db_cache_path']}/*.sql");
exec("rm ${conf['twig_cache_path']}");

if(isset($argv[2]) && $argv[2] == 'varnish')
	exec("service varnish restart");