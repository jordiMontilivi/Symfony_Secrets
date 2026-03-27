<?php
// petit script generat per a posar un secret a front o back
// setup_secrets_jwt.php
// Executar: php setup_secrets_jwt.php dev
// o php setup_secrets_jwt.php prod

$env = $argv[1] ?? 'dev';
echo "Configurant secrets per l'entorn: $env\n";

// 1️⃣ Generar JWT_PASSPHRASE aleatori (64 caràcters hexadecimal)
$jwt_passphrase = bin2hex(random_bytes(32));
echo "Generant JWT_PASSPHRASE: $jwt_passphrase\n";

// 2️⃣ Generar DATABASE_URL de prova
// Canvia-ho segons el teu setup real de dev/prod
$database_url = $env === 'prod'
  ? 'mysql://user_prod:password_prod@127.0.0.1:3306/db_prod'
  : 'mysql://user_dev:password_dev@127.0.0.1:3306/db_dev';

echo "Configurant DATABASE_URL: $database_url\n";

// 3️⃣ Guardar secrets amb Symfony Secrets
system("php bin/console secrets:set JWT_PASSPHRASE --env=$env --force <<< '$jwt_passphrase'");
system("php bin/console secrets:set DATABASE_URL --env=$env --force <<< '$database_url'");

// 4️⃣ Generar keypair LexikJWT amb la passphrase
// --overwrite per sobreescriure si ja existeix
echo "Generant keypair JWT...\n";
system("php bin/console lexik:jwt:generate-keypair --env=$env --overwrite --passphrase='$jwt_passphrase'");

echo "\n✅ Configuració completa per l'entorn $env!\n";