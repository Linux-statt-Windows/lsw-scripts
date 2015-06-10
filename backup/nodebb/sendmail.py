#!/bin/env python3
#
# coding: utf-8
#
# NodeBB-Backup
#
# send mail via mandrill
#
# use with ./sendmail.py -m 'MESSAGE'
# or with ./sendmail.py --message 'MESSAGE'

import os
import smtplib
import argparse

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-m','--message', type=str)
    args = parser.parse_args()
    msg = ''

    if args.message:
        msg = args.message

    print(msg)

    username = MANDRILL_USERNAME
    password = MANDRILL_PASSWORD

    s = smtplib.SMTP('smtp.mandrillapp.com', 587)
    s.login(username, password)


if __name__ == '__main__':
    main()
