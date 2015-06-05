<?php
require_once 'vendor/autoload.php';

spl_autoload_register(function ($file) {
	if(substr($file,0,9) === "alojaweb\\")
		$file = substr($file,9);

	$file = str_replace('\\','/',$file).'.php';
	require_once $file;
});

use Symfony\Component\Yaml\Yaml;

$usage = 'Usage: php clearcache.php dev|prod [--exclude=excoptions[,excoptions] [varnish]'."\n";
$usage .= 'excoptions: [db|twig]';

$excoptions = array('db','twig');
if($argc < 2) {
	exit($usage);
} else
	$env = $argv[1];

if($argc > 2) {
	if(preg_match('/--exclude/',$argv[2])) {
		if(!preg_match('/--exclude=[a-z,]+/',$argv[2]))
			exit($usage);
		$excludeOptions = explode(',',explode('=',$argv[2])[1]);
		if(!empty(array_diff($excludeOptions,$excoptions)))
			exit($usage);
	}
}

if($argc == 4 && $argv[3] != 'varnish')
	exit($usage);

$conf = array();
if($env == 'dev')
	$conf = Yaml::parse(file_get_contents('config/config.sample.yml'));
else
	$conf = Yaml::parse(file_get_contents('config/config.yml'));

if(!isset($excludeOptions) || !in_array('db',$excludeOptions))
	exec("rm ${conf['db_cache_path']}/*.sql");

if(!isset($excludeOptions) || !in_array('twig',$excludeOptions))
	exec("rm ${conf['twig_cache_path']}");

if(isset($argv[3]) && $argv[3] == 'varnish')

exec("service varnish restart");
