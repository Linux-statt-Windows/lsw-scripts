#!/bin/bash
#
# coding: utf-8
#
# NodeBB-Backup decrypt
echo -n 'Bitte geben Sie das Passwort zum Entschlüsseln ein und bestätigen mit [ENTER]: '

# Get password input
read PASSWORD

# Decrypt files with openssl
mv test test.enc
openssl enc -aes-256-cbc -d -in test.enc -out test -k ${PASSWORD}
rm test.enc

# Status message
echo -e "\nDas Backup wurde entschlüsselt"
