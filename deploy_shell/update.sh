#!/bin/bash

# SET DIRS #####################
SCRIPT='update'
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
	info "Update:"
	info "./update.sh --server [beta|prod|...] --mode [all|db|files|clean|dryrun]"
	info "./update.sh -s [beta|prod|...] -m [all|db|files|clean|dryrun]"
	echo ""
	info "Examples for update:"
	info "./update.sh -s beta -m all"
	info "./update.sh -s beta -m db"
	info "./update.sh -s beta -m files"
	info "./update.sh -s beta -m clean"
	info "./update.sh -s beta -m dryrun"
	echo ""
	info "More info is here: http://jira.prod.sea:8080/browse/OSHOP-64"
	exit
}
checkMode() {
	if	[ -z $MODE ]; then
		error "Please, enter mode. Available list: all, db, files, dryrun."
		exitInfo
	fi
	
	if [ "$MODE" != "all" ] && [ "$MODE" != "db" ] && [ "$MODE" != "files" ] && [ "$MODE" != "clean" ] && [ "$MODE" != "dryrun" ]; then
		error "Wrong mode '$MODE'. Available list: all, db, files, clean, dryrun."
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
		download
		dump
	;;
	db)
		dump
	;;
	files)
		download
	;;
	clean)
		downloadClean
	;;
	dryrun)
		downloadDryrun
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