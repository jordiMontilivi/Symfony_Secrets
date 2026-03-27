#!/bin/bash

# ==============================================================================
# Script de Creació d'Infraestructura AWS per a Symfony (EC2 + RDS)
# ==============================================================================
# Requisits:
# - AWS CLI configurat amb credencials (aws configure)
# - jq instal·lat (sudo apt install jq)
# - Una clau SSH existent (Key Pair) a AWS.
# ==============================================================================

# CONFIGURACIÓ (Modifica aquestes variables segons necessitats)
REGION="us-east-1"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text --region $REGION)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text --region $REGION)
AMI_ID="ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS a us-east-1 (Verificar per altres regions!)
INSTANCE_TYPE="t2.micro"
KEY_NAME="vockey" # Nom de la clau SSH existent a AWS (AWS Academy sol usar vockey)
DB_INSTANCE_CLASS="db.t3.micro"
DB_NAME="symfony_app"
DB_USERNAME="admin"
DB_PASSWORD="Password123!" # CANVIAR PER UNA SEGURA!

echo "=== INICIANT CREACIÓ D'INFRAESTRUCTURA ==="
echo "Regió: $REGION"
echo "VPC: $VPC_ID"

# 1. Crear Security Group per a EC2 (Web)
echo "Creating EC2 Security Group..."
SG_WEB_ID=$(aws ec2 create-security-group --group-name symfony-web-sg-auto --description "Security group for Symfony Web Server" --vpc-id $VPC_ID --output text --region $REGION)
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION > /dev/null
echo "EC2 Security Group Created: $SG_WEB_ID"

# 2. Crear Security Group per a RDS (DB)
echo "Creating RDS Security Group..."
SG_DB_ID=$(aws ec2 create-security-group --group-name symfony-db-sg-auto --description "Security group for Symfony RDS" --vpc-id $VPC_ID --output text --region $REGION)
# Permetre accés NOMÉS des del Security Group de EC2
aws ec2 authorize-security-group-ingress --group-id $SG_DB_ID --protocol tcp --port 3306 --source-group $SG_WEB_ID --region $REGION > /dev/null
echo "RDS Security Group Created: $SG_DB_ID"

# 3. Crear Instància EC2
echo "Launching EC2 Instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_WEB_ID \
    --subnet-id $SUBNET_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Symfony-Web-Server-Auto}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

echo "EC2 Instance Launched: $INSTANCE_ID. Waiting for it to run..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text --region $REGION)
echo "EC2 Instance Running at Public IP: $PUBLIC_IP"

# 4. Crear Instància RDS
echo "Creating RDS Instance (This may take a few minutes)..."
aws rds create-db-instance \
    --db-instance-identifier symfony-db-auto \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine mysql \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --allocated-storage 20 \
    --db-name $DB_NAME \
    --vpc-security-group-ids $SG_DB_ID \
    --no-publicly-accessible \
    --tags Key=Name,Value=Symfony-DB-Auto \
    --region $REGION > /dev/null

echo "RDS creation initiated. Check AWS Console for status."

echo "=== RESUM ==="
echo "EC2 IP: $PUBLIC_IP"
echo "EC2 Security Group: $SG_WEB_ID"
echo "RDS Security Group: $SG_DB_ID"
echo "RDS Identifier: symfony-db-auto"
echo "Recorda configurar el .env.prod amb les dades de connexió quan la RDS estigui disponible."
