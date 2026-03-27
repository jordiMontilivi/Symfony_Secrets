# Guia de Configuració Manual d'Infraestructura (AWS EC2 + RDS)

Aquesta guia descriu els passos per crear i configurar manualment la infraestructura necessària per desplegar una aplicació Symfony a AWS, utilitzant un servidor web Apache i una base de dades MySQL (RDS).

## 1. Crear el Grup de Seguretat (Security Group) per a EC2

Abans de crear la instància, crearem un grup de seguretat per permetre el trànsit web i SSH.

1.  A la consola d'AWS, ves a **EC2** > **Security Groups** > **Create security group**.
2.  **Name**: `symfony-web-sg`.
3.  **Description**: Permetre HTTP, HTTPS i SSH.
4.  **Inbound rules**:
    *   **Type**: SSH, **Source**: My IP (o Anywhere 0.0.0.0/0 si la IP canvia, però menys segur).
    *   **Type**: HTTP, **Source**: Anywhere-IPv4 (0.0.0.0/0).
    *   **Type**: HTTPS, **Source**: Anywhere-IPv4 (0.0.0.0/0).
5.  **Outbound rules**: Deixa-ho per defecte (Allow all).

## 2. Crear la Instància EC2 (Servidor Web)

1.  Ves a **EC2** > **Instances** > **Launch instances**.
2.  **Name**: `Symfony-Web-Server`.
3.  **OS Images**: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type.
4.  **Instance type**: `t2.micro` (o `t3.micro` si el pla d'Academy ho permet).
5.  **Key pair**: Crea una nova clau (`vockey` o similar si uses Academy, o crea'n una de nova `.pem`). **Guarda aquest fitxer, el necessitaràs!**
6.  **Network settings**:
    *   **Security group**: Selecciona `Select existing security group` i tria `symfony-web-sg`.
    *   **Auto-assign public IP**: Enable.
7.  **Launch instance**.

## 3. Crear el Grup de Seguretat per a RDS

Necessitem permetre que la EC2 es connecti a la base de dades.

1.  **EC2** > **Security Groups** > **Create security group**.
2.  **Name**: `symfony-db-sg`.
3.  **Description**: Permetre accés MySQL des del servidor web.
4.  **Inbound rules**:
    *   **Type**: MYSQL/Aurora (3306).
    *   **Source**: Custom. Comença a escriure `sg-` i selecciona el grup de seguretat de la EC2 (`symfony-web-sg`). Això és molt important: només la EC2 podrà accedir a la base de dades.

## 4. Crear la Base de Dades RDS

1.  Ves a **RDS** > **Databases** > **Create database**.
2.  **Choose a database creation method**: Standard create.
3.  **Engine type**: MySQL.
4.  **Templates**: Free tier (o Dev/Test).
5.  **Settings**:
    *   **DB instance identifier**: `symfony-db`.
    *   **Master username**: `admin` (o el que vulguis).
    *   **Master password**: Tria una contrasenya forta.
6.  **Instance configuration**: `db.t3.micro` (o similar disponible).
7.  **Connectivity**:
    *   **Public access**: **No** (per seguretat, només volem que hi accedeixi la EC2).
    *   **VPC security group**: Tria `symfony-db-sg` (i treu el `default`).
8.  **Additional configuration**:
    *   **Initial database name**: `symfony_app` (opcional, però recomanat).
9.  **Create database**.

## 5. Preparar el Servidor EC2 (Instal·lació de Software)

Connecta't a la teva instància EC2 via SSH:
```bash
ssh -i "teva-clau.pem" ubuntu@<IP-PUBLICA-EC2>
```

Un cop dins, executa les següents comandes per instal·lar Apache, PHP i les extensions necessàries:

```bash
# Actualitzar paquets
sudo apt update && sudo apt upgrade -y

# Instal·lar Apache
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2

# Instal·lar PHP i extensions comuns per Symfony
sudo apt install php libapache2-mod-php php-mysql php-xml php-mbstring php-curl php-intl php-zip php-gd php-bcmath php-soap -y

# Instal·lar Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Instal·lar Git i Unzip
sudo apt install git unzip -y

# Configurar Apache Document Root (ho farem després amb el VirtualHost, però per preparar permisos)
sudo mkdir -p /var/www/symfony
sudo chown -R ubuntu:www-data /var/www/symfony
sudo chmod -R 775 /var/www/symfony
```

## 6. Configuració Final

Ara tens:
1.  Un servidor EC2 amb Apache i PHP.
2.  Una base de dades RDS MySQL accessible des de la EC2.
3.  Grups de seguretat configurats correctament.

El següent pas serà configurar el VirtualHost d'Apache i automatitzar el desplegament amb GitHub Actions.
