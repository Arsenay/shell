#!/bin/bash
# MAGENTO 1.9
modify() {
	log "modify >"

	SQL=""

	if [ $1 == "remote" ]; then
		SQL=$SQL'USE '${SERVER[MYSQL_DBNAME]}'; '
		SQL=$SQL'UPDATE core_config_data SET value = \"//'${SERVER[PROJECT_DOMAIN]}'/\" WHERE path IN (\"web/unsecure/base_url\", \"web/secure/base_url\"); '

		ssh $SSH_OPTIONS 'mysql --user="'${SERVER[MYSQL_USERNAME]}'" --password="'${SERVER[MYSQL_PASSWORD]}'" --database="'${SERVER[MYSQL_DBNAME]}'" --execute="'$SQL'"'
		info "Remote database  \""${SERVER[MYSQL_DBNAME]}"\" was modified successful."
	fi

	if [ $1 == "local" ]; then
		SQL=$SQL'UPDATE core_config_data SET value = \"//'${CONFIG[PROJECT_DOMAIN]}'/\" WHERE path IN (\"web/unsecure/base_url\", \"web/secure/base_url\"); '

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
	CONFIG_FILE="app/etc/local.xml"
	CONFIG_FILE_TEMPLATE=$CONFIG_FILE".template"
	if ssh $SSH_OPTIONS "test -e '"${SERVER[PROJECT_PATH]}$CONFIG_FILE_TEMPLATE"'"; then
		ssh $SSH_OPTIONS " cp "${SERVER[PROJECT_PATH]}""$CONFIG_FILE_TEMPLATE" "${SERVER[PROJECT_PATH]}""$CONFIG_FILE
		REPLACMENT=" sed \""
		REPLACMENT=$REPLACMENT"s/<host>.*/<host><\![CDATA[${SERVER[MYSQL_HOST]}]]><\/host>/g; "
		REPLACMENT=$REPLACMENT"s/<dbname>.*/<dbname><\![CDATA[${SERVER[MYSQL_DBNAME]}]]><\/dbname>/g; "
		REPLACMENT=$REPLACMENT"s/<username>.*/<username><\![CDATA[${SERVER[MYSQL_USERNAME]}]]><\/username>/g; "
		REPLACMENT=$REPLACMENT"s/<password>.*/<password><\![CDATA[${SERVER[MYSQL_PASSWORD]}]]><\/password>/g; "
		REPLACMENT=$REPLACMENT"\""
		ssh $SSH_OPTIONS $REPLACMENT" "${SERVER[PROJECT_PATH]}""$CONFIG_FILE_TEMPLATE" > "${SERVER[PROJECT_PATH]}""$CONFIG_FILE
		info "File \""$CONFIG_FILE_TEMPLATE"\" was successful configured."
	else
		error "File \""$CONFIG_FILE_TEMPLATE"\" not detected at remote server."
	fi
}