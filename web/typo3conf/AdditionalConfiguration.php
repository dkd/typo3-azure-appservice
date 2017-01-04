<?php
// if (!defined ('TYPO3_MODE'))
//     die ('Access denied.');

if(!function_exists('parseConnectionString'))
{
    function parseConnectionString(string $connectionString, $splitter) {
        return array_merge(...array_map(function($part) {
            $splitted = explode('=', $part);
            $key = array_shift($splitted);
            $value = implode('=', $splitted);
            return [$key => $value];
        }, explode($splitter, $connectionString)));
    }
}

$redisString = getenv("APPSETTING_RedisConnection");
//$redisString = 'cache-c77c52qiizk6g.redis.cache.windows.net,abortConnect=false,ssl=true,password=eecYmSBI6b3QtyjQbjxsCwM6BDhzyeCEua+UfC+q44I=';
$redisString =  'Host=' . $redisString;
$redisConfig =  parseConnectionString($redisString, ',');

//print_r($redisConfig);

$sqlString = getenv("SQLCONNSTR_SqlServer");
//$sqlString = 'Data Source=tcp:sqlserver-c77c52qiizk6g.database.windows.net,1433;Initial Catalog=typo3;User Id=typo3@sqlserver-c77c52qiizk6g;Password=ThisIsSomeLongPassword1;';
$sqlConfig =  parseConnectionString($sqlString, ';');

//$sqlConfig['Host'] = $sqlConfig['Data Source'];
$sqlDatasource=explode(',', $sqlConfig['Data Source']);
//$sqlConfig['Host'] = substr($sqlDatasource[0],4);
$sqlConfig['Host'] = substr($sqlDatasource[0],4);
$sqlConfig['Port'] = $sqlDatasource[1];
$userSplit = explode('@', $sqlConfig['User Id']);
$sqlConfig['User'] = $userSplit[0];

//print_r($sqlConfig);

$GLOBALS['TYPO3_CONF_VARS']['EXTCONF']['dbal']['handlerCfg']['_DEFAULT']['config']['driver'] = 'sqlsrv';
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['driver'] = 'sqlsrv';
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['host'] = $sqlConfig['Host'];
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['port'] = $sqlConfig['Port'];
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['dbname'] = $sqlConfig['Initial Catalog'];
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['user'] = $sqlConfig['User'];
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['password'] = $sqlConfig['Password'];
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['charset'] = 'utf-8';
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['unix_socket'] = '';
$GLOBALS['TYPO3_CONF_VARS']['DB']['Connections']['Default']['socket'] = '';
$GLOBALS['TYPO3_CONF_VARS']['DB']['socket'] = '';

// //redis config
// $list = [
//     'cache_pages' => 86400,
//     'cache_pagesection' => 86400,
//     'cache_hash' => 86400,
//     'extbase_object' => 0,
//     'extbase_reflection' => 0,
//     'extbase_datamapfactory_datamap' => 0
// ];

// $counter = 3;
// foreach ($list as $key => $lifetime) {
//     $GLOBALS['TYPO3_CONF_VARS']['SYS']['caching']['cacheConfigurations'][$key]['backend'] = \TYPO3\CMS\Core\Cache\Backend\RedisBackend::class;
//     $GLOBALS['TYPO3_CONF_VARS']['SYS']['caching']['cacheConfigurations'][$key]['options'] = [
//         'database' => $counter++,
//         'hostname' => $redisConfig['Host'],
//         'defaultLifetime' => $lifetime,
//         'password' => $redisConfig['password']
//     ];
// }

$GLOBALS['TYPO3_CONF_VARS']['BE']['loginSecurityLevel'] = 'normal';

///we are in cli mode where wincache is not there for some unknown reason
if (php_sapi_name() == 'cli') {
    ini_set('session.save_handler', 'files');
    session_set_save_handler(new SessionHandler());
}