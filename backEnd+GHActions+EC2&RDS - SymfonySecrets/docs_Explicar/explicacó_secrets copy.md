# Guia Completa: Gestió de Credencials amb Symfony Secrets i Lexik JWT

En qualsevol projecte professional, el codi font s'acaba pujant a un repositori compartit com GitHub. Si deixem contrasenyes de bases de dades o claus de seguretat en els arxius `.env`, qualsevol persona amb accés al repositori podrà veure-les.

A més, en desplegaments automatitzats (com GitHub Actions + AWS EC2), necessitem una manera robusta i encriptada de compartir aquestes credencials sense exposar-les en text pla.

Per resoldre-ho, combinarem dues solucions: **Symfony Secrets** (la "clau pública i clau privada") i l'encriptació nativa de **Lexik JWT** ("jwt_passphrase... tb amb clau pública i clau privada").

---

## 1. Conceptes Clau

### Què és Symfony Secrets?

Symfony Secrets actua com una **caixa forta** (vault) criptogràfica. A dins hi guardarem les variables més sensibles (com `DATABASE_URL` o contrasenyes, en el nostre cas també la de `JWT_PASSPHRASE`).

- L'aplicació utilitza un **parell de claus** (Pública i Privada).
- La **Clau Pública** xifra (tanca) les dades i es pot pujar al repositori, és _pública_ i la podem compartir amb tothom.
- La **Clau Privada** desxifra (obre) les dades i **MAI es pot pujar al repositori Github**, es _privada_ i la pujarem manualment al servidor backend.

### Com funcionen els `.env`

A Symfony, la jerarquia de prioritats està dissenyada per permetre que les configuracions locals o de producció modifiquen les genèriques.

Aquí tens l'ordre de preferència de **menys a més important**

### 1. El fitxer `.env`

És la base de tot el projecte. Defineix els valors per defecte que es pugen al repositori (Git). Té la **prioritat més baixa**.

### 2. El fitxer `.env.local`

Aquest fitxer s'utilitza per fer ajustos que només afecten la teva màquina local (i no es puja al Git). Qualsevol variable aquí **substitueix** la del `.env`.

### 3. Symfony Secrets (`secrets:set`)

Quan utilitzes el sistema de _secrets_ de Symfony, aquests tenen una prioritat superior a la dels fitxers `.env`.

- Si una variable està definida a `.env.local` i també a `secrets:set`, **guanya el Secret**.
- Això és ideal per a dades sensibles (com la `DATABASE_URL` de producció) que no vols tenir en text pla.

### 4. Variables d'entorn reals (SO)

Les variables definides directament en el sistema operatiu o en la configuració del servidor (per exemple, a través de `export VAR=val` a Linux, o la configuració d'un contenidor de Docker/Kubernetes) tenen la **prioritat absoluta**. Symfony ni tan sols mirarà els fitxers `.env` o els _secrets_ si la variable ja existeix en el sistema.

---

### Resum de jerarquia (de menor a major)

| Ordre | Origen de la Variable    | Descripció                                           |
| :---- | :----------------------- | :--------------------------------------------------- |
| 1     | `.env`                   | Valors per defecte (repositori).                     |
| 2     | `.env.local`             | Sobreescriptura local (fora de Git).                 |
| 3     | **Symfony Secrets**      | Dades xifrades (Vault). **Guanya als fitxers .env.** |
| 4     | **Variables Reals (OS)** | Definides al sistema/Docker. **Guanyen a tot.**      |

Symfony Secrets > .env.local > .env.dev/.env.prod > .env

---

## 2. Generar les Claus de la Caixa Forta (Symfony Secrets)

Primer, generarem els parells de claus criptogràfiques per la caixa forta als diferents entorns:

```bash
php bin/console secrets:generate-keys --env=dev
php bin/console secrets:generate-keys --env=prod
```

> **Atenció:** Això crearà arxius dins de `config/secrets/`. Fixa't que s'hauran creat arxius com `prod.encrypt.public.php` i `prod.decrypt.private.php`. Assegura't que els arxius privats `.private.php` estiguin al `.gitignore` o et robaran la clau!  

> -  config/secrets/prod/
>    -  prod.decrypt.private.php  
>    -  prod.encrypt.public.php  
> -  config/secrets/dev/
>    -  dev.decrypt.private.php
>    -  dev.encrypt.public.php

---

## 3. Generar les Claus de JWT (LexikJWT)

L'autenticació basada en Tokens a Symfony requereix crear tokens signats. Per generar els arxius criptogràfics de JWT executa:

```bash
php bin/console lexik:jwt:generate-keypair
```

> **Què fa internament?**
> Et crea la carpeta `config/jwt` amb la clau encriptada `private.pem` i la pública `public.pem`. A més, automàticament injecta una variable `JWT_PASSPHRASE=codi_llarg_random` al teu arxiu `.env` local. Aquesta variable (contrasenya) bloqueja l'accés al fitxer `private.pem`.

### ⚠️ Error típic a Windows: `error:80000003... No such process`

Com que Windows no ve amb OpenSSL configurat per defecte, la generació automàtica de PHP falla sovint perquè no troba l'arxiu `openssl.cnf`. Tens dues opcions per solucionar-ho desitjables per seguir la pràctica:

**Solució A (La més ràpida, via Git Bash/PowerShell):**

1. `openssl genpkey -out config/jwt/private.pem -aes256 -algorithm rsa -pkeyopt rsa_keygen_bits:4096` _(Escriu una contrasenya qualsevol, aquesta serà el teu Passphrase! Repeteix la contrasenya quan t'ho demani)._
2. `openssl pkey -in config/jwt/private.pem -out config/jwt/public.pem -pubout` _(Desbloqueja amb el teu Passphrase)._

**Solució B (Dir-li on és l'OpenSSL de XAMPP/Laragon abans d'executar):**

```powershell
$env:OPENSSL_CONF="C:\xampp\php\extras\ssl\openssl.cnf"
php bin/console lexik:jwt:generate-keypair
```

---

## 4. Portar les dades sensibles als Symfony Secrets

Ara tenim dades sensibles en text pla (la base de dades i el passphrase de JWT) que volem protegir dins del Vault de Symfony.

### A) El cas del `JWT_PASSPHRASE`

Copia en un bloc de notes el llarg string que està darrera de `JWT_PASSPHRASE=` que trobaràs al teu arxiu `.env` i executa:

```bash
php bin/console secrets:set JWT_PASSPHRASE --env=prod
```

Enganxa la contrasenya copiada quan t'ho demani el terminal. _(Opcionalment, repeteix la comanda afegint `--env=dev` per local)._

### B) El cas del `DATABASE_URL`

Per desar de manera segura l'enllaç a l'API de producció (El teu AWS RDS):

```bash
php bin/console secrets:set DATABASE_URL --env=prod
```

Enganxa-hi la teva URL sencera, per exemple:
`mysql://admin:contrasenya_admin@el-teu-rds.amazonaws.com:3306/symfony_app?serverVersion=...`

---

## 5. Netejar els fitxers `.env` (Molt Important!)

 Cal netejar els valors de les variables del `.env`, `.env.local` i `.env.prod` i **comentar** els valors d'aquelles variables que acabes de ficar al vault:

- **Al `.env` (Comentar el Passphrase completament perquè no sigui un String buit):**
    ```dotenv
    # Abans:
    JWT_PASSPHRASE=7a3b8c9d...
    # Després:
    # JWT_PASSPHRASE=
    ```
- **Al `.env.prod` (Comentar la base de dades):**
    ```dotenv
    # Abans:
    DATABASE_URL="mysql://admin:pass@...amazonaws.com..."
    # Després:
    # DATABASE_URL="mysql://admin:pass@...amazonaws.com..."
    ```

No has de modificar absolutament res a `config/packages/doctrine.yaml` ni a `lexik_jwt_authentication.yaml`. Gràcies a cridar a la instrucció `%env(...)%` en aquests YAML, Symfony està programat per adonar-se sol de la manca de la variable i buscar automàticament a l'opció dels Secrets des d'on s'injectaran de forma transparent.

---

## 6. Desplegar l'Aplicació a Producció (AWS EC2)

Pugem el codi a GitHub a través dels `.gitignore`. Evidentment, els mètodes segurs de contrasenyes s'han ignorat durant els commits:

- La clau privada del Vault (`config/secrets/prod/prod.decrypt.private.php`).
- La clau privada que encripta JWT (`config/jwt/private.pem`).

**Com s'ho farà la màquina virtual EC2 de Producció Sense Aquests Arxius?**

1. Quan executis els scripts a través de GHActions (`full-setup-pro.sh`), es descarregarà la capa pública.
2. Com a pas manual (o part d'un escriptura de CI/CD via Secret Variables al GH), l'administrador del sistema només s'ha de connectar 1 vegada per SFTP/SSH a la instància d'EC2 i copiar 3 arxius de les claus privades manuals al disc dur de producció:
    - Apuntant al directori `[projecte]/config/secrets/prod/prod.decrypt.private.php`
    - Apuntant al directori `[projecte]/config/jwt/private.pem`
    - Apuntant al directori `[projecte]/config/jwt/public.pem`

De manera transparent i instantània, en arrancar localment a AWS el servidor Symfony trobarà el fitxer privat `prod.decrypt.private.php`, desencriptarà la caixa forta al vol només a memòria, recuperarà el RDS i la contrasenya JWT en un tancar i obrir d'ulls. Felicitats, l'aplicació ja és de Producció Plenament Segura! 🎉
