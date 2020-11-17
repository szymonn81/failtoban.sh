#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin

# date ex. Nov
today=$(date "+%b")

# full date for mark auth.log
dt=$(date '+%d/%m/%Y %H:%M:%S')

# Day ex. 18
tday=$(date '+%d')

# Add white list ip address lists to skip
cat /root/white_list.txt>/root/iptables_list.txt

# get current iptables 
iptables -L -n | grep DROP | awk '{print $4}' | awk 'NF'>>/root/iptables_list.txt


# filters out invalid logins
cat /var/log/auth.log | grep "$today $tday" | grep "Invalid user" | awk '{print $10}'| sort | uniq >/root/ban_list.txt
cat /var/log/auth.log | grep "$today $tday" | grep "Failed password for root" | awk '{print $11}' | sort | uniq >>/root/ban_list.txt

# mark auth.log
echo "$dt" KILLSPAM >> /var/log/auth.log

# check ip script 
BANLIST="/root/ban_list.txt"
IPTABLES_LIST="/root/iptables_list.txt"


for i in $(awk '{ print $1 }' "$BANLIST")
    do
         IPTOBAN="$i"
         count=$(grep -o "$IPTOBAN" "$IPTABLES_LIST" | wc -l)
if [ $count != 0 ];then
   echo "SKIP IP ($count times) $IPTOBAN"
else
   echo "BAN IP $IPTOBAN"
iptables -A INPUT -s $IPTOBAN -j DROP
fi
done
exit 0
