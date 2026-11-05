<?php

// La route OpenShift termine TLS. Sans ceci, Drupal génère des URL http,
// le routeur redirige le POST AJAX de l'installeur, et le navigateur reçoit
// la page HTML avec un code 200.
$forwardedProto = $_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '';
if (str_contains($forwardedProto, 'https')) {
  $_SERVER['HTTPS'] = 'on';
  $_SERVER['REQUEST_SCHEME'] = 'https';
  $settings['reverse_proxy'] = TRUE;
  $settings['reverse_proxy_addresses'] = array_filter([$_SERVER['REMOTE_ADDR'] ?? NULL]);
  if (class_exists(\Symfony\Component\HttpFoundation\Request::class)) {
    $settings['reverse_proxy_trusted_headers'] = \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_FOR
      | \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_HOST
      | \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_PORT
      | \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_PROTO
      | \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_PREFIX;
  }
}

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

  // Sans ces deux valeurs, l'installeur réaffiche le formulaire base de
  // données et ignore le mot de passe déjà lu dans l'environnement.
  $settings['hash_salt'] = getenv('HASH_SALT') ?: 'drupal-demo-change-me';
  $settings['config_sync_directory'] = '/opt/app-root/src/config/sync';
}
