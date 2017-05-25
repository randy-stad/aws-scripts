#!/bin/bash
WHITELIST=$1
VPC=$2

securityGroups=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC --query "SecurityGroups[*].GroupId" --output text)

echo "<table border='1' style='border-collapse:collapse;' cellpadding='4'>"
echo "<tr>"
echo "<th>security-group-id</th>"
echo "<th>group-name</th>"
echo "<th>from-port</th>"
echo "<th>to-port</th>"
echo "<th>cidr</th>"
echo "<th>whitelist</th>"
echo "<th>whois</th>"
echo "</tr>"
for sg in $securityGroups
do
  name=$(aws ec2 describe-security-groups --group-id $sg --query 'SecurityGroups[*].GroupName' --output text)
  while IFS=$'\t' read -r -a entry
  do
    toPort=${entry[0]}
    fromPort=${entry[1]}
    cidr=${entry[2]}
    if grep -q $cidr "$1"; then
   		whitelist="YES"
		else
			whitelist="<b>NO</b>"
 	  fi
    ip=${cidr%/*}
    whois=$(whois $ip | sed '/^#/d' | sed '/^\s*$/d' | sed 's/$/<br>/')
		echo "<tr>"
		echo "<td valign='top' halign='left'>$sg</td>"
		echo "<td valign='top' halign='left'>$name</td>"
    echo "<td valign='top' halign='left'>$fromPort</td>"
    echo "<td valign='top' halign='left'>$toPort</td>"
		echo "<td valign='top' halign='left'>$cidr</td>"
		echo "<td valign='top' halign='left'>$whitelist</td>"
		echo "<td valign='top' halign='left'>$whois</td>"
		echo "</tr>"
  done < <(aws ec2 describe-security-groups --filter Name=group-id,Values=$sg --query "SecurityGroups[*].IpPermissions[*].{FromPort:FromPort,ToPort:ToPort,CidrIp:IpRanges[*].CidrIp}" | jq -r '.[0] | .[] | .ToPort //= -1 | .FromPort //= -1 | {ToPort: .ToPort, FromPort: .FromPort, CidrIp: .CidrIp[]} | [.ToPort, .FromPort, .CidrIp] | @tsv')
done
echo "</table>"
