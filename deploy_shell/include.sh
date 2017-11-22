#!/bin/bash
download() {
	log "download >"
	echo -en "\033[1;32m"
	rsync -azrvc -e ssh --exclude-from "$EXLUDE_LIST" ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]} $PROJECT_DIRECTORY
	echo -en "\033[0m"
}

downloadClean() {
	log "clean >"
	echo -en "\033[1;32m"
	rsync -azrvc --delete-during -e ssh --exclude-from "$EXLUDE_LIST" ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]} $PROJECT_DIRECTORY
	echo -en "\033[0m"
}

downloadDryrun() {
	log "download dryrun >"
	echo -en "\033[1;33m"
	rsync -azrvc -e ssh --dry-run --exclude-from "$EXLUDE_LIST" ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]} $PROJECT_DIRECTORY
	echo -en "\033[0m"
}

downloadDb() {
	DB_DUMP_FILE_NAME=${SERVER[MYSQL_DBNAME]}'.sql'
	# DUMP
	ssh $SSH_OPTIONS 'mysqldump -u '${SERVER[MYSQL_USERNAME]}' -p'${SERVER[MYSQL_PASSWORD]}' '${SERVER[MYSQL_DBNAME]}' > '${SERVER[PROJECT_PATH]}$DB_DUMP_FILE_NAME
	info "Database dump was created successful from remote database \""${SERVER[MYSQL_DBNAME]}"\"."
	# DOWNLOAD
	scp ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]}$DB_DUMP_FILE_NAME $PROJECT_DIRECTORY
	info "Database dump was download successful to local server."
}

upload() {
	log "upload >"
	echo -en "\033[1;32m"
	rsync -azrvc -e ssh --exclude-from "$EXLUDE_LIST" $PROJECT_DIRECTORY ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]}
	echo -en "\033[0m"
}

uploadClean() {
	log "clean >"
	echo -en "\033[1;32m"
	rsync -azrvc --delete-during -e ssh --exclude-from "$EXLUDE_LIST" $PROJECT_DIRECTORY ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]}
	echo -en "\033[0m"
}

uploadDryrun() {
	log "upload dryrun >"
	echo -en "\033[1;33m"
	rsync -azrvc -e ssh --dry-run --exclude-from "$EXLUDE_LIST" $PROJECT_DIRECTORY ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]}
	echo -en "\033[0m"
}

uploadDb() {
	scp $DB_DUMP_FILE ${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}":"${SERVER[PROJECT_PATH]}
	info "Database dump was upload successful to remote server."

	# BACKUP
	ssh $SSH_OPTIONS 'mysqldump -u '${SERVER[MYSQL_USERNAME]}' -p'${SERVER[MYSQL_PASSWORD]}' '${SERVER[MYSQL_DBNAME]}' > '${SERVER[PROJECT_PATH]}'pre_update_'${SERVER[MYSQL_DBNAME]}'.sql'
	info "Database backup was created successful from remote database \""${SERVER[MYSQL_DBNAME]}"\"."

	# UPDATE
	ssh $SSH_OPTIONS 'mysql -u '${SERVER[MYSQL_USERNAME]}' -p'${SERVER[MYSQL_PASSWORD]}' '${SERVER[MYSQL_DBNAME]}' < '${SERVER[PROJECT_PATH]}''${SERVER[MYSQL_DBNAME]}'.sql'
	info "Remote database \""${SERVER[MYSQL_DBNAME]}"\" was updated successful."

	# MODIFY
	modify 'remote'
}

db() {
	log "db >"
	# DUMP
	DB_DUMP_FILE=$PROJECT_DIRECTORY${SERVER[MYSQL_DBNAME]}".sql"
	if [ -f $DB_DUMP_FILE ]; then
		uploadDb
	elif [ ${CONFIG[MYSQL_EXIST]} == 'yes' ];then
		if	[ -z ${CONFIG[MYSQL_PASSWORD]} ]; then
			mysqldump -u ${CONFIG[MYSQL_USERNAME]} ${CONFIG[MYSQL_DBNAME]} > $DB_DUMP_FILE
		else
			mysqldump -u ${CONFIG[MYSQL_USERNAME]} -p${CONFIG[MYSQL_PASSWORD]} ${CONFIG[MYSQL_DBNAME]} > $DB_DUMP_FILE
		fi
		info "Database dump was created successful from local database \"${CONFIG[MYSQL_DBNAME]}\"."
		uploadDb
	else
		error "Database dump does not exist, and can not be created."
	fi
}

dump() {
	log "dump >"
	downloadDb
	if [ ${CONFIG[MYSQL_EXIST]} == 'yes' ];then
		echo "Do you want to update your local database \"${CONFIG[MYSQL_DBNAME]}\"? [y|n]:"
		read -e -i 'y' UPDATE
		if [ $UPDATE == 'y' ]; then
			# UPDATE
			DB_DUMP_FILE=$PROJECT_DIRECTORY$DB_DUMP_FILE_NAME
			if [ -f $DB_DUMP_FILE ]; then
				if	[ -z ${CONFIG[MYSQL_PASSWORD]} ]; then
					mysql -u ${CONFIG[MYSQL_USERNAME]} -e'CREATE DATABASE IF NOT EXISTS '${CONFIG[MYSQL_DBNAME]}';'
					mysql -u ${CONFIG[MYSQL_USERNAME]} ${CONFIG[MYSQL_DBNAME]} < $DB_DUMP_FILE
				else
					mysql -u ${CONFIG[MYSQL_USERNAME]} -p${CONFIG[MYSQL_PASSWORD]} -e'CREATE DATABASE IF NOT EXISTS '${CONFIG[MYSQL_DBNAME]}';'
					mysql -u ${CONFIG[MYSQL_USERNAME]} -p${CONFIG[MYSQL_PASSWORD]} ${CONFIG[MYSQL_DBNAME]} < $DB_DUMP_FILE
				fi
				info "Local database \""${SERVER[MYSQL_DBNAME]}"\" was updated successful."
			else
				error "No database dump \""$DB_DUMP_FILE_NAME"\" detected."
			fi
			# MODIFY
			modify 'local'
		fi
	fi
}

checkServer() {
	log "checkServer >"
	# check server
	SSH_OPTIONS=${SERVER[SSH_USER]}"@"${SERVER[SSH_HOSTNAME]}
	SSH_STATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $SSH_OPTIONS echo ok 2>&1)
	if [ "$SSH_STATUS" != "ok" ]; then
		echo "SSH server not available or wrong user/port"
		echo "Error: $SSH_STATUS"
		echo "Used command: ssh $SSH_OPTIONS"
		exit
	fi

	# check project folder
	ssh $SSH_OPTIONS '[ -d '${SERVER[PROJECT_PATH]}' ]'
	if [[ $? != 0 ]]; then
		echo "Remote directory not exist: "${SERVER[PROJECT_PATH]}
		exit
	fi

	# check database
	if [ "$MODE" == "all" ] || [ "$MODE" == "db" ]; then
		ssh $SSH_OPTIONS 'mysql -h '${SERVER[MYSQL_HOST]}' -u '${SERVER[MYSQL_USERNAME]}' -p'${SERVER[MYSQL_PASSWORD]}' -e "SHOW DATABASES;"' | grep -q ${SERVER[MYSQL_DBNAME]}
		if [[ $? != 0 ]]; then
			error "Remote database not exist: "${SERVER[MYSQL_DBNAME]}
			exit
		fi
	fi
}

checkConfig() {
	log "checkConfig >"

	if	[ -z ${CONFIG[MYSQL_EXIST]} ] || 
		[ -z ${CONFIG[PROJECT_PATH]} ] || 
		[ -z ${CONFIG[PROJECT_TYPE]} ];	then
		error "Required variables: PROJECT_PATH, PROJECT_TYPE, MYSQL_EXIST."
		exitInfo
	fi
}

checkInputParam() {
	log "checkInputParam >"
	while [[ $# -gt 1 ]]
	do
		key="$1"
		case $key in
			-s|--server)
			SERVER_NAME="$2"
			shift 
			;;
			-m|--mode)
			MODE="$2"
			shift
			;;
			*)
			;;
		esac
		shift
	done
	
	PROJECT_DIRECTORY=${CONFIG[PROJECT_PATH]}
	if [ -z $PROJECT_DIRECTORY ]; then
		error "Please, enter PROJECT_DIRECTORY in config file."
		exitInfo
	fi
	if [ ! -d "$PROJECT_DIRECTORY" ]; then
		error "$PROJECT_DIRECTORY does not exist!"
		exitInfo
	fi
	
	PROJECT_TYPE=${CONFIG[PROJECT_TYPE]}
	if [ -z $PROJECT_TYPE ]; then
		error "Please, enter PROJECT_TYPE in config file."
		exitInfo
	fi
	if [ "$PROJECT_TYPE" != "prestashop1.6" ] && [ "$PROJECT_TYPE" != "prestashop1.7" ] && [ "$PROJECT_TYPE" != "magento1.9" ]; then
		error "Wrong project type '$PROJECT_TYPE'. Available list: prestashop1.6, prestashop1.7, magento1.9."
		exitInfo
	fi

	if	[ -z $SERVER_NAME ]; then
		error "Please, enter server name. Available list of servers look in config file."
		exitInfo
	fi
	SERVER_NAME=$(echo $SERVER_NAME | awk '{print toupper($0)}')

	getServerConfig $SERVER_NAME

	checkMode
}

function getServerConfig() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
	declare -p "$1" > /dev/null 2>&1
	[[ $? -eq 1 ]] && { echo "Variable [${1}] doesn't exist in config." 1>&2 ; return 1 ; }
	SERVER[SSH_HOSTNAME]=$(eval echo \${${1}[SSH_HOSTNAME]})
	SERVER[SSH_USER]=$(eval echo \${${1}[SSH_USER]})
	SERVER[PROJECT_PATH]=$(eval echo \${${1}[PROJECT_PATH]})
	SERVER[PROJECT_DOMAIN]=$(eval echo \${${1}[PROJECT_DOMAIN]})
	SERVER[MYSQL_HOST]=$(eval echo \${${1}[MYSQL_HOST]})
	SERVER[MYSQL_DBNAME]=$(eval echo \${${1}[MYSQL_DBNAME]})
	SERVER[MYSQL_USERNAME]=$(eval echo \${${1}[MYSQL_USERNAME]})
	SERVER[MYSQL_PASSWORD]=$(eval echo \${${1}[MYSQL_PASSWORD]})
}

# SIMPLE LOGER #################
error() {
	echo -en "\033[1;31m"
	echo $1
	echo -en "\033[0m"
}

success() {
	echo -en "\033[1;32m"
	echo $1
	echo -en "\033[0m"
}

warning() {
	echo -en "\033[1;33m"
	echo $1
	echo -en "\033[0m"
}

info() {
	echo -en "\033[1;34m"
	echo $1
	echo -en "\033[0m"
}

log() {
	echo -en "\033[43m"
	echo $1
	echo -en "\033[0m"
}