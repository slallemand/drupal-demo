<?php

/**
 * Connexion lue au démarrage du conteneur.
 * Variables : DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_DRIVER.
 * Sans DB_NAME, l'installeur web reste utilisable.
 */
if (getenv('DB_NAME')) {
  $driver = getenv('DB_DRIVER') ?: 'mysql';
  $databases['default']['default'] = [
    'database' => getenv('DB_NAME'),
    'username' => getenv('DB_USER'),
    'password' => getenv('DB_PASSWORD'),
    'host' => getenv('DB_HOST') ?: 'localhost',
    'port' => getenv('DB_PORT') ?: '3306',
    'driver' => $driver,
    'prefix' => '',
    'namespace' => 'Drupal\\' . $driver . '\\Driver\\Database\\' . $driver,
    'autoload' => 'core/modules/' . $driver . '/src/Driver/Database/' . $driver . '/',
  ];
}
