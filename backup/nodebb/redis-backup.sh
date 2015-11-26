#!/bin/bash

## PATHS ######################

# Folder where backups will be stored.
BACKUP_DIR=/home/redis-backup # /home/carebear/lsw.io/redis-dumping/production-backups

# Folder for temporary files.
# Make sure the script can delete in there! Otherwise you
# might end up with unencrypted dumps lying around.
BACKUP_TMP=/tmp/redis-backup

# Redis dump path and filename.
# These should match 'dir' and 'dbfilename' in your redis.conf.
REDIS_DIR=/var/lib/redis
REDIS_DUMP_FILE=dump.rdb
REDIS_PORT=6379
REDIS_CMD="redis-cli -p $REDIS_PORT"

## ENCRYPTION #################

# Dumps are encrypted with a one-time password, each.
# PUBLIC_KEY is used to encrypt those passwords, before they
# are sent via email.
PUBLIC_KEY='/var/wwn/lsw.io/redis-backup.pub'

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
  echo "Deleting temp folder."
  rm -Rf $BACKUP_TMP
  echo "[redis-backup] I'm out. Cya! :D."
}

function dumpDB {
  echo "[redis-backup] Dumping last state to file ($REDIS_DIR/$REDIS_DUMP_FILE):"
  REDIS_LASTSAVE=$( $REDIS_CMD LASTSAVE )
  if [ $? != 0 ]; then
    echo "[redis-backup] Error while executing redis command. Is your redis service running?"
    exit 1
  fi
  $REDIS_CMD BGSAVE && echo "[redis-backup] Waiting 3 seconds to finish..." && sleep 3;
  REDIS_NEWSAVE=$( $REDIS_CMD LASTSAVE );
  while [ $REDIS_NEWSAVE -le $REDIS_LASTSAVE ]; do
    echo "[redis-backup] Dumping not finished, yet. Waiting another 3 second..."
    sleep 3
    REDIS_NEWSAVE=$( $REDIS_CMD LASTSAVE )
  done
  cp $REDIS_DIR/$REDIS_DUMP_FILE $BACKUP_TMP/$DATE.rdb
  echo "[redis-backup] Dump created."
}

function packAndCrypt {
  echo "[redis-backup] Compressing | Encrypting backup dump $BACKUP_TMP/$DATE.rdb"
  # generate random password
  PASSWORD=$( head -c 256 /dev/urandom | sha256sum | base64 | tail -c +16 | head -c 32; echo )
  echo $PASSWORD > $BACKUP_TMP/$DATE.key
  # pack and encrypt dump
  tar cz -C $BACKUP_TMP $DATE.rdb | \
  openssl enc -aes-256-cbc -salt -k $PASSWORD > $BACKUP_TMP/$DATE.bck
  mv $BACKUP_TMP/$DATE.bck $BACKUP_DIR/$DATE.bck
}

function sendMail {
  TO="carebear@queen.beerhive"
  FROM="crypto@lsw.io"

  # read in the passed $1 parameter,
  # encrypt it for RECIPIENT. redirect stderr > stdout
  # for easier inspection of gpg error message
  ENC=$(gpg --batch --armor --recipient "$FROM" --encrypt < $BACKUP_TMP/$DATE.key 2>&1)

  # failed to encrypt. prepend error message to content and send clear text content
  if [ $? -ne 0 ]; then
      ENC="Failed to encrypt contents: $ENC"
      ENC+=$'\n\n'
      ENC+="redis-backup @ $DATE"
  fi

  cat <<EOF | sudo sendmail -t
From: ${FROM}
To: ${TO}
Subject: Testing
Content-type: text/plain
${ENC}
EOF
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

run
