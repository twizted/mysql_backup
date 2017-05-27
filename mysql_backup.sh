#!/bin/bash

#  MySQL backup script with auto-removal of old backups
#  Copyright (C) 2016 Armando Vega
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


# set up parameters
user="u_name"
db_name="db_name"
defaults_file="/root/.my_conf.cnf"
backup_path="/var/backups"
copy_to="/mnt/smbshare"
date=$(date +"%Y-%m-%d")


# locking mechanism
LOCKFILE=/var/lock/mysql_backup.lock
if [ -f $LOCKFILE ]; then
    msg="Previous instance still running?"
    echo $msg
    logger -p local7.err $msg
    exit 1
fi
trap "{ rm -f $LOCKFILE ; exit 0; }" EXIT
touch $LOCKFILE

# set permissions to 600
umask 177

# dump database
nice -19 mysqldump --defaults-file=$defaults_file $db_name > $backup_path/$db_name-$date.sql

# dump failed?
if [ $? -eq 0 ]; then
    msg="Succesfully dumped database $db_name, compressing.."
    echo $msg
    logger -p local7.info $msg
    nice -19 gzip $backup_path/$db_name-$date.sql
    # dump compression failed?
    if [ $? -eq 0 ]; then
        msg="Database dump compressed, copying to $copy_to.."
        echo $msg
        logger -p local7.info $msg
        cp $backup_path/$db_name-$date.sql.gz $copy_to
        # copy to another destination failed?
        if [ $? -eq 0 ]; then
            msg="Removing backup files older than 30 days.."
            echo $msg
            logger -p local7.info $msg
            find $backup_path/ -type f -name *.sql.gz -mtime +30 -delete;
            msg="Backup complete!"
            echo $msg
            logger -p local7.info $msg
        else
            msg="ERROR: Unable to copy dump file to $copy_to, leaving file and aborting!"
            echo $msg
            logger -p local7.err $msg
            exit 1
        fi
    else
        msg="ERROR: Unable to compress database dump! Aborting."
        echo $msg
        logger -p local7.err $msg
        exit 1
    fi
else
    msg="ERROR: Unable to dump database! Aborting."
    echo $msg
    logger -p local7.err $msg
    exit 1
fi

