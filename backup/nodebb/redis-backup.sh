#!/bin/bash

## REMOTE ################

# Operate in remote or local mode.
# Remote mode uses ssh to issue DB dump commands
# and sftp to retrieve the file. Encryption is always done locally.
REMOTE=true
# Alias for ssh and sftp.
# Name of host alias from ~/.ssh/config.
REMOTE_ALIAS=worker

## PATHS #################

# Folder where backups will be stored.
BACKUP_DIR='/var/wwn/lsw.io/redis-dumping/production-backups'

# Folder for temporary files.
# Make sure the script can delete in there! Otherwise you
# might end up with unencrypted dumps lying around.
BACKUP_TMP=$BACKUP_DIR/tmp

# Redis dump path and filename.
# These should match 'dir' and 'dbfilename' in your redis.conf.
# Use the lines commented out to have the script determine
# the variables from redis.conf.
REDIS_DIR='/var/lib/redis'
REDIS_DUMP_FILE='dump.rdb'
# REDIS_DIR=$(grep ^dir /etc/redis/redis.conf | cut -f2 -d " ")
# REDIS_DUMP_FILE=$(grep ^dbfilename /etc/redis/redis.conf | cut -f2 -d " ")

## ENCRYPTION #################
PUBLIC_KEY='/var/wwn/lsw.io/redis-backup.pub'


function init {
  DATE=$(date +%Y-%m-%d_%H-%M-%S)
  echo "[redis-backup] Starting backup with tag $DATE"
  echo "[redis-backup] Creating backup in $BACKUP_TMP"
  mkdir $BACKUP_TMP
  dumpDB
  echo '[redis-backup] All done - Cleaning up...'
  cleanArchive
  echo "Deleting tmp folder."
  rm -Rf $BACKUP_TMP
  echo "[redis-backup] I'm out. Cya! :D."
}

function packAndCrypt {
  echo "[redis-backup] Compressing | Encrypting backup dump $BACKUP_TMP/$DATE.rdb"
  # generate random password
  PASSWORD=$( head -c 256 /dev/urandom | sha256sum | base64 | tail -c +16 | head -c 32; echo )

  # pack and encrypt dump
  tar cz -C $BACKUP_TMP $DATE.rdb | \
  openssl enc -aes-256-cbc -salt -k $PASSWORD > $BACKUP_TMP/$DATE.bck
  # encrypt password with cert
  
  cp $BACKUP_TMP/$DATE.bck $BACKUP_DIR/$DATE.bck
}

function dumpDB {
  echo "[redis-backup] Dumping last state to file ($REDIS_DIR/$REDIS_DUMP_FILE):"
  SCRIPT='REDIS_LASTSAVE=$( redis-cli LASTSAVE )
  if [ $? != 0 ]; then
    echo "[redis-backup] Error while executing redis command. Is your redis service started?"
    exit 1
  fi
  redis-cli BGSAVE && echo "[redis-backup] Waiting 3 seconds to finish..." && sleep 3;
  REDIS_NEWSAVE=$( redis-cli LASTSAVE );
  while [ $REDIS_NEWSAVE -le $REDIS_LASTSAVE ]; do
    echo "[redis-backup] Dumping not finished, yet. Waiting another second..."
    sleep 1
    REDIS_NEWSAVE=$( redis-cli LASTSAVE )
  done
  echo "[redis-backup] Dump created."
  '
  if [ $REMOTE == true ]; then
    ssh $REMOTE_ALIAS "$SCRIPT"
    echo "[redis-backup] Downloading dump file."
    echo "get $REDIS_DUMP_FILE $BACKUP_TMP/$DATE.rdb" | sftp $REMOTE_ALIAS:$REDIS_DIR/
  else
    eval "$SCRIPT"
    cp $REDIS_DIR/$REDIS_DUMP_FILE $BACKUP_TMP/$DATE.rdb
  fi
  packAndCrypt
}

function cleanArchive {
  FILES=( $(ls -Ctr $BACKUP_DIR/*.bck) )
  FILECOUNT=${#FILES[*]}
  if [ $FILECOUNT -gt 5 ]; then
    echo "[redis-backup] More than 5 backups found."
    for i in `seq 4 $(expr $FILECOUNT - 1)`; do
      echo "[redis-backup] Deleting old backup ${FILES[$i]}"
      rm ${FILES[$i]%.bck}.txt
      rm ${FILES[$i]}
    done
  fi
}

init
