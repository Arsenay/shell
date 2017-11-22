#!/bin/bash
# PRESTASHOP 1.6
modify() {
	log "modify >"

	SQL=""

	if [ $1 == "remote" ]; then
		SQL=$SQL'UPDATE ps_shop_url SET domain = \"'${SERVER[PROJECT_DOMAIN]}'\", domain_ssl = \"'${SERVER[PROJECT_DOMAIN]}'\" WHERE id_shop = 1; '
		SQL=$SQL'UPDATE ps_configuration SET value = 1 WHERE name IN (\"PS_SSL_ENABLED\", \"PS_SSL_ENABLED_EVERYWHERE\"); '
		ssh $SSH_OPTIONS 'mysql --user="'${SERVER[MYSQL_USERNAME]}'" --password="'${SERVER[MYSQL_PASSWORD]}'" --database="'${SERVER[MYSQL_DBNAME]}'" --execute="'$SQL'"'
		info "Remote database  \""${SERVER[MYSQL_DBNAME]}"\" was modified successful."
	fi

	if [ $1 == "local" ]; then
		SQL=$SQL'UPDATE ps_shop_url SET domain = \"'${CONFIG[PROJECT_DOMAIN]}'\", domain_ssl = \"'${CONFIG[PROJECT_DOMAIN]}'\" WHERE id_shop = 1; '
		SQL=$SQL'UPDATE ps_configuration SET value = 0 WHERE name IN (\"PS_SSL_ENABLED\", \"PS_SSL_ENABLED_EVERYWHERE\"); '

		if	[ -z ${CONFIG[MYSQL_PASSWORD]} ]; then
			eval 'mysql --user="'${CONFIG[MYSQL_USERNAME]}'" --database="'${CONFIG[MYSQL_DBNAME]}'" --execute="'$SQL'"'
		else
			eval 'mysql --user="'${CONFIG[MYSQL_USERNAME]}'" --password="'${CONFIG[MYSQL_PASSWORD]}'" --database="'${CONFIG[MYSQL_DBNAME]}'" --execute="'$SQL'"'
		fi
		info "Local database  \""${CONFIG[MYSQL_DBNAME]}"\" was modified successful."
	fi
}

configure() {
	log  "configure >"
	configureSite
}

configureSite() {
	CONFIG_FILE="config/settings.inc.php"
	CONFIG_FILE_TEMPLATE=$CONFIG_FILE".template"
	if ssh $SSH_OPTIONS "test -e '"${SERVER[PROJECT_PATH]}$CONFIG_FILE_TEMPLATE"'"; then
		ssh $SSH_OPTIONS " cp "${SERVER[PROJECT_PATH]}$CONFIG_FILE_TEMPLATE" "${SERVER[PROJECT_PATH]}$CONFIG_FILE
		REPLACMENT=" sed \""
		REPLACMENT=$REPLACMENT"s/'_DB_SERVER_.*/'_DB_SERVER_', '${SERVER[MYSQL_HOST]}');/g; "
		REPLACMENT=$REPLACMENT"s/'_DB_NAME_.*/'_DB_NAME_', '${SERVER[MYSQL_DBNAME]}');/g; "
		REPLACMENT=$REPLACMENT"s/'_DB_USER_.*/'_DB_USER_', '${SERVER[MYSQL_USERNAME]}');/g; "
		REPLACMENT=$REPLACMENT"s/'_DB_PASSWD_.*/'_DB_PASSWD_', '${SERVER[MYSQL_PASSWORD]}');/g; "
		REPLACMENT=$REPLACMENT"\""
		ssh $SSH_OPTIONS $REPLACMENT" "${SERVER[PROJECT_PATH]}$CONFIG_FILE_TEMPLATE" > "${SERVER[PROJECT_PATH]}$CONFIG_FILE
		info "File \""$CONFIG_FILE_TEMPLATE"\" was successful configured."
	else
		error "File \""$CONFIG_FILE_TEMPLATE"\" not detected at remote server."
	fi
}