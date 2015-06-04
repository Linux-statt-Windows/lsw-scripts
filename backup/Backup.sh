#!/bin/bash
#
# coding: utf-8
#
# NodeBB-Backup
#
# Process:
# sync in folder
# encrypt redis-db
# git push

# Directorys
REDIS_SOURCE=/var/lib/redis/6379/dump.rdb
NODEBB_SOURCE=/home/nodebb/nodebb/public
BACKUP_DIR=/root/backup
REDIS_BACKUP=$BACKUP_DIR/db/dump.rdb

# Variables
DATE=$( date +"%Y-%M-%d %H:%m" ) # wrong time? time: YYYY-MM-DD HH:MM
MAIL_ADRESS="name@mail.com"

# Generate safe password for encryption
PASSWORD=$( head -c 256 /dev/urandom | sha256sum | base64 | tail -c +16 | head -c 32; echo )
echo $PASSWORD

# Copy everything to the backup-directory
#
# Directory:
# backup/
#     ../data   -> NODEBB_SOURCE
#     ../db     -> REDIS_SOURCE
rsync -a $NODEBB_SOURCE $BACKUP_DIR/data/nodebb
cp $REDIS_SOURCE $BACKUP_DIR/db/

# Encrypt files
openssl enc -aes-256-cbc -salt -in $REDIS_BACKUP -out $REDIS_BACKUP.enc -k $PASSWORD
rm $REDIS_BACKUP
mv $REDIS_BACKUP.enc $REDIS_BACKUP

# Send password via mail
mail -s "${DATE} - NodeBB-Backup" $MAIL_ADRESS <<< "${PASSWORD}"

# Sync to Github
cd $BACKUP_DIR
git add .
git commit -m "${DATE} - NodeBB-Backup" # time: YYYY-MM-DD HH:MM
git push origin master
