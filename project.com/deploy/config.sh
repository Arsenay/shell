#!/bin/bash
typeset -A BETA=(
#	SSH
	[SSH_HOSTNAME]="100.100.100.100"
	[SSH_USER]="username"
#	PATH FOR DEPLOY
	[PROJECT_PATH]="/var/www/domain.folder/"
#	DOMAIN
	[PROJECT_DOMAIN]="domain.com"
#	MYSQL
	[MYSQL_HOST]="localhost"
	[MYSQL_DBNAME]="db_name"
	[MYSQL_USERNAME]="db_user"
	[MYSQL_PASSWORD]="db_password"
)