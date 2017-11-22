#!/bin/bash
DEPLOY_PATH="$( dirname "`readlink -e "$0"`" )"
DEPLOY_SHELL_SCRIPT="$(realpath $DEPLOY_PATH'/../../deploy_shell/update.sh')"
if [ ! -f $DEPLOY_SHELL_SCRIPT ]; then
	echo "$DEPLOY_SHELL_SCRIPT DONT EXIST!"
	exit
fi
source $DEPLOY_SHELL_SCRIPT