<?php

/**
 * @file
 * Container deployment configuration override.
 */


/**
 * Disable CSS and JS aggregation.
 * 
 * Disabled in production?!? Yes, because it's not 2014 anymore. HTTP/2 exists.
 */
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

/**
 * Enable access to rebuild.php.
 *
 * This setting can be enabled to allow Drupal's php and database cached
 * storage to be cleared via the rebuild.php page. Access to this page can also
 * be gained by generating a query string from rebuild_token_calculator.sh and
 * using these parameters in a request to rebuild.php.
 */
$settings['rebuild_access'] = FALSE;

/**
 * Skip file system permissions hardening.
 *
 * The system module will periodically check the permissions of your site's
 * site directory to ensure that it is not writable by the website user. For
 * sites that are managed with a version control system, this can cause problems
 * when files in that directory such as settings.php are updated, because the
 * user pulling in the changes won't have permissions to modify files in the
 * directory.
 */
$settings['skip_permissions_hardening'] = TRUE;

/**
 * Database configuration.
 *
 * If you are using a database service like MySQL, PostgreSQL or MariaDB, you
 * can copy the respective lines below to your settings.local.php file to
 * override the default database configuration.
 *
 * You may also simply rename the file to settings.php and fill in the values.
 *
 * On a standard Drupal installation, you'll need to set the 'host' to '
 */
$databases['default']['default'] = [
  'driver' => 'mysql',
  'database' => '{{MYSQL_DATABASE}}',
  'username' => '{{MYSQL_USER}}',
  'password' => '{{MYSQL_PASSWORD}}',
  'host' => '{{MYSQL_HOST}}',
  'port' => '{{MYSQL_TCP_PORT}}',
  'prefix' => '',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'driver' => 'mysql',
];

/**
 * Setup Redis as the default cache.
 */
$settings['container_yamls'][]             = 'modules/contrib/redis/redis.services.yml';
$settings['container_yamls'][]             = 'modules/contrib/redis/example.services.yml';
$settings['redis.connection']['interface'] = 'PhpRedis';
$settings['redis.connection']['host']      = '{{REDIS_HOST}}';
$settings['redis.connection']['password']  = '{{REDIS_AUTH}}';
$settings['cache']['default']              = 'cache.backend.redis';

/**
 * Hash salt should be consistent across all containers in an environment.
 */
$settings['hash_salt'] = '{{HASH_SALT}}';
