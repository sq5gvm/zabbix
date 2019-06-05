#!/bin/bash
### Make sure yum-plugin-security package is installed ###
### Make sure zabbix-sender package is installed ###

### Set Some Variables ###
ZBX_DATA=/tmp/zabbix-sender-yum.data
HOSTNAME=$(egrep ^Hostname= /etc/zabbix/zabbix_agentd.conf | cut -d = -f 2)
ZBX_SERVER_IP=$(egrep ^ServerActive /etc/zabbix/zabbix_agentd.conf | cut -d = -f 2)

if [ ! -e /etc/redhat-release ]
then
  echo "You are not running any redhat"
  exit 1
fi

RELEASE=$(cat "/etc/redhat-release")
ENFORCING=$(getenforce)
egrep -qw ^RHEL /etc/redhat-release
NOTRHEL=$?


### Check if Zabbix-Sender is Installed ###
if [ $NOTRHEL -eq 0 ]
then
        if ! rpm -qa | grep -qw zabbix-sender; then
    echo "zabbix-sender NOT installed"
    exit 1;
  fi
else
  if ! command -v zabbix_sender > /dev/null
  then
    echo "zabbix_sender NOT installed"
    exit 1
  fi
fi

### Check if SELinux is active ###
if [[ "$ENFORCING" == "Enforcing" ]]
then
  SELINUX=1
else
  SELINUX=0
fi

SECURITY=0
LOW=0
MODERATE=0
IMPORTANT=0
CRITICAL=0
UNKNOWN=0
BUGFIX=0
ENHANCEMENT=0
ALL=0

summ=`mktemp`
yum updateinfo summary > $summ
SECURITY=`grep "Security notice" $summ | awk '{ print $1 }'`
LOW=`grep "Low Security notice" $summ | awk '{ print $1 }'`
MODERATE=`grep "Moderate Security notice" $summ | awk '{ print $1 }'`
IMPORTANT=`grep "Important Security notice" $summ | awk '{ print $1 }'`
CRITICAL=`grep "Critical Security notice" $summ | awk '{ print $1 }'`
#UNKNOWN=`grep "? Security notice" $summ | awk '{ print $1 }'`
BUGFIX=`grep "Bugfix notice" $summ | awk '{ print $1 }'`
ENHANCEMENT=`grep "Enhancement notice" $summ | awk '{ print $1 }'`
rm -f $summ

ALL=`yum check-update -q | wc -l | awk '{ print $1 - 1 }'`


#echo "Critical $CRITICAL foo"

### Add data to file and send it to Zabbix Server ###
echo -n > $ZBX_DATA
if [ "$SECURITY" != "" ]
then
  echo "$HOSTNAME yum.security $SECURITY" >> $ZBX_DATA
fi
if [ "$BUGFIX" != "" ]
then
  echo "$HOSTNAME yum.bugfixes $BUGFIX" >> $ZBX_DATA
fi
if [ "$UNKNOWN" != "" ]
then
  echo "$HOSTNAME yum.unknown $UNKNOWN" >> $ZBX_DATA
fi
if [ "$ENHANCEMENT" != "" ]
then
  echo "$HOSTNAME yum.enhancement $ENHANCEMENT" >> $ZBX_DATA
fi
if [ "$MODERATE" != "" ]
then
  echo "$HOSTNAME yum.moderate $MODERATE" >> $ZBX_DATA
fi
if [ "$IMPORTANT" != "" ]
then
  echo "$HOSTNAME yum.important $IMPORTANT" >> $ZBX_DATA
fi
if [ "$LOW" != "" ]
then
  echo "$HOSTNAME yum.low $LOW" >> $ZBX_DATA
fi
if [ "$CRITICAL" != "" ]
then
  echo "$HOSTNAME yum.critical $CRITICAL" >> $ZBX_DATA
fi
if [ "$ALL" != "" ]
then
  echo "$HOSTNAME yum.all $ALL" >> $ZBX_DATA
fi
echo "$HOSTNAME yum.release $RELEASE" >> $ZBX_DATA
echo "$HOSTNAME yum.selinux $SELINUX" >> $ZBX_DATA



zabbix_sender -z $ZBX_SERVER_IP -i $ZBX_DATA &> /dev/null



