#!/bin/bash

# SET DIRS #####################
SCRIPT='deploy'
PROJECT_PATH="$( dirname "$DEPLOY_PATH" )""/"
PROJECTS_PATH="$( dirname "$PROJECT_PATH" )"
DEPLOY_SHELL_PATH=$PROJECTS_PATH"/deploy_shell"
LOCAL_DB_NAME=$(echo $( basename "$PROJECT_PATH" ) | sed 's/\.[a-z]*$//g')

# VARIABLE SERVER ##############
typeset -A SERVER=(
)

# CONFIG
typeset -A CONFIG=(
	[PROJECT_PATH]=$PROJECT_PATH
)

# PROJECT CONFIGURATOR INCLUDE #
CONFIGURATOR=$DEPLOY_SHELL_PATH"/configurator.sh"
if [ ! -f $CONFIGURATOR ]; then
	error "$CONFIGURATOR DONT EXIST!"
	exit
fi
source $CONFIGURATOR

# PROJECT CONFIG INCLUDE #######
CONFIG=$DEPLOY_PATH"/config.sh"
if [ ! -f $CONFIG ]; then
	error "$CONFIG DONT EXIST!"
	exit
fi
source $CONFIG

# LIB FUNCTIONS INCLUDE ########
exitInfo() {
	echo ""
	info "Deploy:"
	info "./deploy.sh --server [beta|prod|...] --mode [all|db|files|clean|config|dryrun]"
	info "./deploy.sh -s [beta|prod|...] -m [all|db|files|clean|dryrun]"
	echo ""
	info "How to use deploy script:"
	info " ./deploy.sh -s beta -m all"
	info " ./deploy.sh -s beta -m db"
	info " ./deploy.sh -s beta -m files"
	info " ./deploy.sh -s beta -m clean"
	info " ./deploy.sh -s beta -m config"
	info " ./deploy.sh -s beta -m dryrun"
	echo ""
	info "More info is here: http://jira.prod.sea:8080/browse/OSHOP-64"
	exit
}
checkMode() {
	if	[ -z $MODE ]; then
		error "Please, enter mode. Available list: all, db, files, config, dryrun."
		exitInfo
	fi
	
	if [ "$MODE" != "all" ] && [ "$MODE" != "db" ] && [ "$MODE" != "files" ] && [ "$MODE" != "clean" ] && [ "$MODE" != "config" ] && [ "$MODE" != "dryrun" ]; then
		error "Wrong mode '$MODE'. Available list: all, db, files, clean, config, dryrun."
		exitInfo
	fi
}
INCLUDE=$DEPLOY_SHELL_PATH"/include.sh"
if [ ! -f $INCLUDE ]; then
	error "$INCLUDE DONT EXIST!"
	exit
fi
source $INCLUDE

# EXCLUDE FILES LIST ###########
EXLUDE_LIST=$DEPLOY_PATH"/exclude_file_list"
if [ ! -f $EXLUDE_LIST ]; then
	error "$EXLUDE_LIST DONT EXIST!"
	exit
fi

# CHEACH #######################
checkConfig
checkInputParam $@
checkServer

# LIB PROJECT FUNCTIONS ########
FUNCTIONS=$DEPLOY_SHELL_PATH"/lib/"$PROJECT_TYPE".sh"
if [ ! -f $FUNCTIONS ]; then
	error "$FUNCTIONS DONT EXIST!"
	exit
fi
source $FUNCTIONS

case $MODE in
	all)
		upload
		configure
		db
	;;
	db)
		db
	;;
	files)
		upload
	;;
	clean)
		uploadClean
	;;
	config)
		configure
	;;
	dryrun)
		uploadDryrun
	;;
esac

# SUCCESS ######################
success "DONE"
echo ""

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