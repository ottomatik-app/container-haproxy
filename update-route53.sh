#!/bin/bash

# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# args:
# zoneId, recordSet, recordType, ip, ttl, comment
function update_dns()
{
    local zoneId=$1
    local recordSet=$2
    local recordType=$3
    local ip=$4
    local ttl=$5
    local comment=$6

    echo -e "\n\nProcessing ${recordSet} => ${ip}"

    # Get current dir
    # (from http://stackoverflow.com/a/246128/920350)
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    IPFILE="${DIR}/${recordType}-${recordSet}.ip"

    if ! valid_ip $ip; then
        echo "Invalid IP address: $ip"
        exit 1
    fi

    # Check if the IP has changed
    if [ ! -f "$IPFILE" ]
        then
        touch "$IPFILE"
    fi

    if grep -Fxq "$ip" "$IPFILE"; then
        # code if found
        echo "IP is still $ip."
    else
        echo "IP has changed to $ip, updating..."
        # Fill a temp file with valid JSON
        TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
        cat > ${TMPFILE} << EOF
        {
          "Comment":"$comment",
          "Changes":[
            {
              "Action":"UPSERT",
              "ResourceRecordSet":{
                "ResourceRecords":[
                  {
                    "Value":"$ip"
                  }
                ],
                "Name":"$recordSet",
                "Type":"$recordType",
                "TTL":$ttl
              }
            }
          ]
        }
EOF

        # Update the Hosted Zone record
        aws route53 change-resource-record-sets \
            --hosted-zone-id $zoneId \
            --change-batch file://"$TMPFILE"

        # Clean up
        rm $TMPFILE
    fi

    # All Done - cache the IP address for next time
    echo "$ip" > "$IPFILE"
}


# # # #
#
# This script expects some environment variables to be set:
# ------------------------
#  AWS_ACCESS_KEY_ID
#  AWS_SECRET_ACCESS_KEY
#  AWS_DEFAULT_REGION
#  R53_ZONEID
# ------------------------
# Then for each DNS record you want to update add environment variables
# with an enumeration indicator in the variable as follows:
# ------------------------
#  R53_RS_NAME_1
#  R53_RS_TYPE_1
#  R53_RS_TTL_1
#
# # # #

# Get the external IP address from OpenDNS (more reliable than other providers)
IP=`dig +short myip.opendns.com @resolver1.opendns.com`

COMMENT="Auto updating @ `date`"

for i in {1..20}; do

  rs="R53_RS_NAME_${i}"
  tp="R53_RS_TYPE_${i}"
  tl="R53_RS_TTL_${i}"

  if [ ${!rs} ]; then

    # zoneId, recordSet, recordType, ip, ttl, comment
    update_dns $R53_ZONEID ${!rs} ${!tp} ${IP} ${!tl} ${COMMENT}

  fi

done