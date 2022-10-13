#!/bin/bash
# Filename: rebalance.sh
# Run: './rebalance.sh'

# This script is made for Linux Platform only

# Owner: IssTech AB
# Contributor:
# - Christian Petersson

### What is your Spectrum Protect Instance User
USER="tsminst1"
WHOAMI="$(whoami)"

# Will check who you are login as, if it not match it will quit the script
if [ "$WHOAMI" != "$USER" ]; 
 then 
  echo You need to run this script as "$USER"
  exit 1
else
 echo Welcome "$USER"
fi

TABLE="SYSCATSPACE USERSPACE1 IDXSPACE1 LARGEIDXSPACE1 LARGESPACE1 REPLTBLSPACE1 REPLIDXSPACE1 ARCHOBJDATASPACE ARCHOBJIDXSPACE BACKOBJDATASPACE BACKOBJIDXSPACE BFABFDATASPACE BFABFIDXSPACE BFBFEXTDATASPACE BFBFEXTIDXSPACE DEDUPTBLSPACE1 DEDUPIDXSPACE1 DEDUPTBLSPACE2 DEDUPIDXSPACE2 DEDUPTBLSPACE3 DEDUPIDXSPACE3 DEDUPTBLSPACE4 DEDUPIDXSPACE4 DEDUPTBLSPACE5 DEDUPIDXSPACE5 SYSTOOLSPACE"

rebalance_status () {
    # This function search if there is any rebalance ongoing.
    # The function will start a While loop and run until the select command returns 1
     STATUS=1
     while [ $STATUS -gt 0 ];
      do
        echo Checking Status of Rebalance of "$1"
        db2 "select varchar(tbsp_name, 30) as tbsp_name, dbpartitionnum, member, rebalancer_mode, rebalancer_status, rebalancer_extents_remaining, rebalancer_extents_processed, rebalancer_start_time from table(mon_get_rebalance_status(NULL,-2)) as t"	
        if [[ $? -gt 0 ]];
        then
         db2 alter tablespace $1 reduce max
         STATUS=0
        else
         echo Rebalance is not done yet, wait 60 seconds
         sleep 60
        fi
     done
}

rebalance_table () {
    # This function will start a rebalance of one tablespace at the time
    # and run the rebalance_status function, when that returns true
    # it will start rebalance the next tablespace

    echo Check status if any process already running.
    rebalance_status $1

    echo Running Rebalance on DB2 Table $1
    db2 alter tablespace $1 rebalance
    rebalance_status $1
}

# Main Program
# Connect to TSMDB1
db2 connect to TSMDB1

# Running a for loop of the list TABLE above 
for t in $TABLE
 do
  rebalance_table $t
done