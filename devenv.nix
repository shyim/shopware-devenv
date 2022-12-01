{ pkgs, config, ... }:

let
  phpPackage = pkgs.php.buildEnv {
    extensions = { all, enabled }: with all; enabled ++ [ redis ];
    extraConfig = ''
      memory_limit = 512M
      pdo_mysql.default_socket=''${MYSQL_UNIX_PORT}
      mysqli.default_socket=''${MYSQL_UNIX_PORT}
      session.save_handler = redis
      session.save_path = "tcp://127.0.0.1:6379/0"
    '';
  };
in
{
  languages.javascript.enable = true;
  languages.javascript.package = pkgs.nodejs-16_x;

  languages.php.enable = true;
  languages.php.package = phpPackage;
  languages.php.fpm.pools.web = {
    settings = {
      "pm" = "dynamic";
      "pm.max_children" = 5;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 5;
      "clear_env" = false;
    };
  };

  caddy.enable = true;
  caddy.virtualHosts."http://localhost:8000" = {
    extraConfig = ''
      root * public
      php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}
      encode gzip
      file_server
    '';
  };

  caddy.virtualHosts."http://adminer.localhost:8000" = {
    extraConfig = ''
      root * ${pkgs.adminer}
      php_fastcgi unix/${config.languages.php.fpm.pools.web.socket} {
        index adminer.php
      }
      encode gzip
      file_server
    '';
  };

  mysql.enable = true;
  mysql.initialDatabases = [ { name = "shopware"; }];

  redis.enable = true;

  env.APP_URL = "http://localhost:8000";
  env.APP_SECRET = "devsecret";
  env.APP_ENV = "dev";

  env.DATABASE_URL = "mysql://root@localhost:3306/shopware";
}
