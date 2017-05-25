#!/bin/bash
WHITELIST=$1

echo "<table border='1' style='border-collapse:collapse;' cellpadding='4'>"
echo "<tr>"
echo "<th>security-group-id</th>"
echo "<th>group-name</th>"
echo "<th>cidr</th>"
echo "<th>whitelist</th>"
echo "<th>whois</th>"
echo "</tr>"
for sg in ${@:2}
do
  cidrs=$(aws ec2 describe-security-groups --group-id $sg --query 'SecurityGroups[*].IpPermissions[*].IpRanges[*].[CidrIp]' --output text)
	name=$(aws ec2 describe-security-groups --group-id $sg --query 'SecurityGroups[*].GroupName' --output text)
  for cidr in $cidrs; do
		if grep -q $cidr "$1"; then
   		whitelist="YES"
		else
			whitelist="<b>NO</b>"
 	fi
    whois=$(whois $cidr | sed '/^#/d' | sed '/^\s*$/d' | sed 's/$/<br>/')
		echo "<tr>"
		echo "<td valign='top' halign='left'>$sg</td>"
		echo "<td valign='top' halign='left'>$name</td>"
		echo "<td valign='top' halign='left'>$cidr</td>"
		echo "<td valign='top' halign='left'>$whitelist</td>"
		echo "<td valign='top' halign='left'>$whois</td>"
		echo "</tr>"
  done
done
echo "</table>"
