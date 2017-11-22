#!/bin/bash
LOCAL=$DEPLOY_PATH"/local.sh"
if [ ! -f $LOCAL ]; then
	LOCAL_TEMPLATE=$LOCAL".template"
	if [ ! -f $LOCAL_TEMPLATE ]; then
		error "$LOCAL_TEMPLATE DONT EXIST!"
		exit
	else
		echo "Do you want to create your local settings file (enter 'n' - if you have not installed mysql server)? [y|n]:"
		read -e -i 'y' DB_EXIST
		if [ $DB_EXIST == 'y' ]; then
			echo "Please, enter your local domain, and press enter:"
			read -e -i $LOCAL_DB_NAME".local" LOCAL_DOMAIN
			echo "Please, enter your local datebase hostname, and press enter:"
			read -e -i 'localhost' DB_HOST
			echo "Please, enter your local datebase name, and press enter:"
			read -e -i $LOCAL_DB_NAME DB_NAME
			echo "Please, enter your local datebase username, and press enter:"
			read -e -i 'root' DB_USERNAME
			echo "Please, enter your local datebase password, and press enter:"
			read -e -i '' DB_PASSWORD

			REPLACMENT=""
			REPLACMENT=$REPLACMENT"s/CONFIG\[PROJECT_DOMAIN\].*/CONFIG\[PROJECT_DOMAIN\]='$LOCAL_DOMAIN'/g; "
			REPLACMENT=$REPLACMENT"s/CONFIG\[MYSQL_EXIST\].*/CONFIG\[MYSQL_EXIST\]='yes'/g; "
			REPLACMENT=$REPLACMENT"s/CONFIG\[MYSQL_HOST\].*/CONFIG\[MYSQL_HOST\]='$DB_HOST'/g; "
			REPLACMENT=$REPLACMENT"s/CONFIG\[MYSQL_DBNAME\].*/CONFIG\[MYSQL_DBNAME\]='$DB_NAME'/g; "
			REPLACMENT=$REPLACMENT"s/CONFIG\[MYSQL_USERNAME\].*/CONFIG\[MYSQL_USERNAME\]='$DB_USERNAME'/g; "
			REPLACMENT=$REPLACMENT"s/CONFIG\[MYSQL_PASSWORD\].*/CONFIG\[MYSQL_PASSWORD\]='$DB_PASSWORD'/g; "
			eval 'sed "'$REPLACMENT'" '$LOCAL_TEMPLATE' > '$LOCAL
		else
			REPLACMENT=""
			REPLACMENT=$REPLACMENT"s/CONFIG\[MYSQL_EXIST\].*/CONFIG\[MYSQL_EXIST\]='no'/g; "
			eval 'sed "'$REPLACMENT'" '$LOCAL_TEMPLATE' > '$LOCAL
		fi
		echo "Local settings was created successfully."
	fi
fi
source $LOCAL