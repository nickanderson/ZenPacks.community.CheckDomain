#!/bin/bash

PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`

#. $PROGPATH/utils.sh

# Unknown original author
# http://exchange.nagios.org/directory/Plugins/Internet-Domains-and-WHOIS/check_domain/details
# 2010.7.12 - Nick Anderson  <nick@cmdln.org> 
#           Added performance data to output for easier integration into graphing systems

# Default values (days):
critical=7
warning=30

# Parse arguments
args=`getopt -o hd:w:c:P: --long help,domain:,warning:,critical:,path: -u -n $0 -- "$@"` 
[ $? != 0 ] && echo "$0: Could not parse arguments" && echo "Usage: $0 -h | -d <domain> [-c <critical>] [-w <warning>]" && exit
set -- $args

while true ; do
        case "$1" in
                -c|--critical) critical=$2;shift 2;;
                -w|--warning)  warning=$2;shift 2;;
		            -d|--domain)   domain=$2;shift 2;;
		            -P|--path)     whoispath=$2;shift 2;;
		            -h|--help)     echo "check_domain - v1.01"
                               echo "Copyright (c) 2005 Tom�s N��ez Lirola <tnunez@criptos.com> under GPL License"
                               echo "This plugin checks the expiration date of a domain name." 
                               echo ""
                               echo "Usage: $0 -h | -d <domain> [-c <critical>] [-w <warning>]"
                               echo "NOTE: -d must be specified"
                               echo ""
                               echo "Options:"
                               echo "-h"
                               echo "     Print detailed help"
                               echo "-d"
                               echo "     Domain name to check"
                               echo "-w"
                               echo "     Response time to result in warning status (days)"
                               echo "-c"
                               echo "     Response time to result in critical status (days)"
                               echo ""
                               echo "This plugin will use whois service to get the expiration date for the domain name. "
                               echo "Example:"
                               echo "     $0 -d domain.tld -w 30 -c 10"
                               echo ""
                               exit;;
	             	--) shift; break;;
                *)  echo "Internal error!" ; exit 1 ;;
        esac
done

[ -z $domain ] && echo "UNKNOWN - There is no domain name to check" && exit $STATE_UNKNOWN

# Looking for whois binary
if [ -z $whoispath ]; then
      type whois &> /dev/null || error="yes"
      [ ! -z $error ] && echo "UNKNOWN - Unable to find whois binary in your path. Is it installed? Please specify path." && exit $STATE_UNKNOWN
else
      [ ! -x "$whoispath/whois" ] && echo "UNKNOWN - Unable to find whois binary, you specified an incorrect path" && exit $STATE_UNKNOWN
fi

# Calculate days until expiration
expiration=`whois $domain |grep "Expiration Date:"| awk -F"Date:" '{print $2}'|cut -f 1`
expseconds=`date +%s --date="$expiration"`
nowseconds=`date +%s`
((diffseconds=expseconds-nowseconds))
expdays=$((diffseconds/86400))

# Trigger alarms if applicable
[ -z "$expiration" ] && echo "UNKNOWN - Domain doesn't exist or no WHOIS server available." && exit $STATE_UNKNOWN
[ $expdays -lt 0 ] && echo "CRITICAL - Domain expired on $expiration | expiredays=$expdays" && exit $STATE_CRITICAL
[ $expdays -lt $critical ] && echo "CRITICAL - Domain will expire in $expdays days | expiredays=$expdays" && exit $STATE_CRITICAL
[ $expdays -lt $warning ]&& echo "WARNING - Domain will expire in $expdays days | expiredays=$expdays" && exit $STATE_WARNING

# No alarms? Ok, everything is right.
echo "OK - Domain will expire in $expdays days | expiredays=$expdays"
exit $STATE_OK
