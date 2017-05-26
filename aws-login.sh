#!/bin/bash
PROFILE=$1
OKTA_HOME=~/src/okta-aws-cli-assume-role
CONFIG_HOME=~/.okta

if [ -z $PROFILE ]; then
	echo error - you mush specify a profile: awslogin.sh profilename
else
	FILENAME=$CONFIG_HOME/config.properties.$PROFILE
	if [ -f $FILENAME ]; then
		#echo $FILENAME
		rm -f $OKTA_HOME/out/config.properties
		ln -s $FILENAME $OKTA_HOME/out/config.properties
		java -classpath $OKTA_HOME/out/:$OKTA_HOME/out/oktaawscli.jar:$OKTA_HOME/lib/aws-java-sdk-1.11.132.jar com.okta.tools.awscli
	else
		echo "Error no file name $FILENAME exists.  Are you sure thats the right account name?"
	fi
fi
