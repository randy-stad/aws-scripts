#!/bin/bash

usage() { echo "Usage: $0 [-m] -w <whitelist> -v <vpc>" 1>&2; exit 1; }

while getopts "mw:v:" arg; do
  case $arg in
    m)
      markdownFormat="M"
      ;;
    w)
      whitelist=$OPTARG
      if [ ! -f "$whitelist" ]; then
        echo "Whitelist file $whitelist does not exist or is not accessable"
        exit 1
      fi
      ;;
    v)
      vpc=$OPTARG
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${whitelist}" ] || [ -z "${vpc}" ]; then
  usage
fi

securityGroups=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$vpc --query "SecurityGroups[*].GroupId" --output text)

if [ ! -z "${markdownFormat}" ]; then
  echo "| security-group  | group-name  | from-port  | to-port  | cidr  | whitelist  | whois  |"
  echo "|:----------------|:------------|-----------:|---------:|:------|:-----------|:-------|"
else
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
fi
for sg in $securityGroups
do
  name=$(aws ec2 describe-security-groups --group-id $sg --query 'SecurityGroups[*].GroupName' --output text)
  while IFS=$'\t' read -r -a entry
  do
    toPort=${entry[0]}
    fromPort=${entry[1]}
    cidr=${entry[2]}
    if grep -q $cidr "$whitelist"; then
   		present="YES"
		else
			present="NO"
 	  fi
    ip=${cidr%/*}

    unset whois
    if [ "YES" == "${present}" ]; then
      whois=$(whois $ip | grep OrgName)
    fi
    if [ -z "${whois}" ]; then
      whois=$(whois $ip | sed '/^[#%]/d' | sed '/^[Comment]/d' | sed '/^\s*$/d' | sed 's/$/<br>/')
    fi

    if [ ! -z "${markdownFormat}" ]; then
      echo "| $sg | $name | $fromPort | $toPort | $cidr | $present | <pre><code>$whois</code></pre> |"
    else
  		echo "<tr>"
  		echo "<td valign='top' halign='left'>$sg</td>"
  		echo "<td valign='top' halign='left'>$name</td>"
      echo "<td valign='top' halign='left'>$fromPort</td>"
      echo "<td valign='top' halign='left'>$toPort</td>"
  		echo "<td valign='top' halign='left'>$cidr</td>"
  		echo "<td valign='top' halign='left'>$present</td>"
  		echo "<td valign='top' halign='left'>$whois</td>"
  		echo "</tr>"
    fi
  done < <(aws ec2 describe-security-groups --filter Name=group-id,Values=$sg --query "SecurityGroups[*].IpPermissions[*].{FromPort:FromPort,ToPort:ToPort,CidrIp:IpRanges[*].CidrIp}" | jq -r '.[0] | .[] | .ToPort //= -1 | .FromPort //= -1 | {ToPort: .ToPort, FromPort: .FromPort, CidrIp: .CidrIp[]} | [.ToPort, .FromPort, .CidrIp] | @tsv')
done
echo "</table>"
