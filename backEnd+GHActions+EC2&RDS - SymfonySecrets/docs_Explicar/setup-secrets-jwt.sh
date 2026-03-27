#!/bin/bash

# Ús:
# ./setup_secrets_jwt.sh dev
# ./setup_secrets_jwt.sh prod

ENV=${1:-dev}
echo "Configurant secrets per l'entorn: $ENV"

# 1️⃣ Generar JWT_PASSPHRASE aleatori (64 caràcters hexadecimal)
JWT_PASSPHRASE=$(openssl rand -hex 32)
echo "Generant JWT_PASSPHRASE: $JWT_PASSPHRASE"

# 2️⃣ Generar DATABASE_URL de prova
if [ "$ENV" == "prod" ]; then
    DATABASE_URL="mysql://user_prod:password_prod@127.0.0.1:3306/db_prod"
else
    DATABASE_URL="mysql://user_dev:password_dev@127.0.0.1:3306/db_dev"
fi
echo "Configurant DATABASE_URL: $DATABASE_URL"

# 3️⃣ Guardar secrets amb Symfony Secrets
echo "$JWT_PASSPHRASE" | php bin/console secrets:set JWT_PASSPHRASE --env=$ENV --force
echo "$DATABASE_URL" | php bin/console secrets:set DATABASE_URL --env=$ENV --force

# 4️⃣ Generar keypair LexikJWT amb la passphrase
php bin/console lexik:jwt:generate-keypair --env=$ENV --overwrite --passphrase="$JWT_PASSPHRASE"

echo ""
echo "✅ Configuració completa per l'entorn $ENV!"