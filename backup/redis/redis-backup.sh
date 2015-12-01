#!/bin/bash

# ~~~~~~~~~~~~ CONFIG ~~~~~~~~~~~~ #

## PATHS ######################
# Folder where backups will be stored.
BACKUP_DIR=/home/redis-backup
# Folder for temporary files.
BACKUP_TMP=/tmp/redis-backup

## DATABASE ###################
# Redis dump path, filename and port.
# These must match
#   'dir',
#   'dbfilename' and
#   'port'
# in your redis.conf
REDIS_DIR=/var/lib/redis
REDIS_DUMP_FILE=dump.rdb
REDIS_PORT=6379
# Number of dumps stored.
# Script deletes the (x - 10) oldest dumps, whenever (x) - 10 > 0
ARCHIVE_SHELVES=10

## EMAIL ######################
FROM="redis-backup@lsw.io"
TO="rbeerdev@gmail.com"
# TO="multiple@mail.com accounts@mail.com space_seperated@mail.com"

## HELPER ####################
REDIS="redis-cli -p $REDIS_PORT"
SENDMAIL=/usr/sbin/sendmail
GPG=/usr/bin/gpg
MUTT=/usr/bin/mutt

# ~~~~~~~~~~~~ GIFNOC ~~~~~~~~~~~~ #

DATE=$(date +%Y-%m-%d_%H-%M-%S)

function run {
  echo "[redis-backup] Starting backup with tag $DATE"
  echo "[redis-backup] Creating backup in $BACKUP_TMP"
  mkdir $BACKUP_TMP
  dumpDB
  packAndCrypt
  sendMail
  echo '[redis-backup] All done - Cleaning up...'
  cleanArchive
  echo "[redis-backup] Deleting temp folder."
  rm -Rf $BACKUP_TMP
  echo "[redis-backup] I'm out. Cya! :D."
}

function dumpDB {
  echo "[redis-backup] Dumping last state to file ($REDIS_DIR/$REDIS_DUMP_FILE):"
  REDIS_LASTSAVE=$( $REDIS LASTSAVE )
  if [ $? != 0 ]; then
    echo "[redis-backup] Error while executing redis command. Is your redis service running?"
    exit 1
  fi
  $REDIS BGSAVE && echo "[redis-backup] Waiting 3 seconds to finish..." && sleep 3;
  REDIS_NEWSAVE=$( $REDIS LASTSAVE );
  while [ $REDIS_NEWSAVE -le $REDIS_LASTSAVE ]; do
    echo "[redis-backup] Dumping not finished, yet. Waiting another 3 second..."
    sleep 3
    REDIS_NEWSAVE=$( $REDIS LASTSAVE )
  done
  cp $REDIS_DIR/$REDIS_DUMP_FILE $BACKUP_TMP/$DATE.rdb
  echo "[redis-backup] Dump created."
}

function packAndCrypt {
  echo "[redis-backup] Compressing | Encrypting backup dump $BACKUP_TMP/$DATE.rdb"
  # generate random password
  PASSWORD=$( head -c 256 /dev/urandom | sha256sum | base64 | tail -c +16 | head -c 32; echo )
  # pack and encrypt dump
  tar cz -C $BACKUP_TMP $DATE.rdb | \
  openssl enc -aes-256-cbc -salt -k $PASSWORD > $BACKUP_TMP/$DATE.bck
  mv $BACKUP_TMP/$DATE.bck $BACKUP_DIR/$DATE.bck
}

function sendMail {
  ENC=$( echo "$PASSWORD" | $GPG --batch --armor --recipient ${FROM} --encrypt )

  # failed to encrypt. send error message as content
  if [ $? -ne 0 ]; then
      ENC="Failed to encrypt contents: $ENC"
  fi

  echo "$ENC" | $MUTT -s ${DATE} ${TO}
}

function cleanArchive {
  FILES=( $(ls -Ctr $BACKUP_DIR/*.bck) )
  FILECOUNT=${#FILES[*]}
  if [ $FILECOUNT -gt $ARCHIVE_SHELVES ]; then
    echo "[redis-backup] More than 5 backups found."
    for i in `seq 4 $(expr $FILECOUNT - 1)`; do
      echo "[redis-backup] Deleting old backup ${FILES[$i]}"
      rm ${FILES[$i]%.bck}.txt
      rm ${FILES[$i]}
    done
  fi
}

run
