#!/bin/bash

# Script to set up local env really fast
# DB: mySQL DB
# Webserver: nginx

# Some variables
# Path to hostfile.
ETC_HOSTS=/etc/hosts

# Default Ip for hostname.
IP=127.0.0.1


echo "site folder name: (no underscores or hyphens)"
read SITE_FOLDER_NAME

echo "sitename: "
read SITE_NAME

if [ -d $SITE_FOLDER_NAME  ]; then
	echo "Folder $SITE_FOLDER_NAME already excist"
	exit 127
fi


# Fetching core using composer ofcourse.
echo "Fetching Drupal 8 core to $SITE_FOLDER_NAME"
composer create-project drupal-composer/drupal-project:8.x-dev $SITE_FOLDER_NAME --stability dev --no-interaction


# Installing Drupal and in the same time create DB.
if [ -d $SITE_FOLDER_NAME ]; then
	cd $SITE_FOLDER_NAME
	
	if [ -d web ]; then
		cd web
		echo "Installing Drupal8..."
		drush si --account-name="admin" --account-pass="admin" --site-name="$SITE_NAME" --db-url="mysql://root:password@localhost/$SITE_FOLDER_NAME" --notify -y
		cd ..
	fi
	cd ..
fi

addhost() {

	echo "Adding host"
	HOST_NAME=$SITE_FOLDER_NAME".loc"
	echo $HOST_NAME
	if [ -n "$(grep $HOST_NAME $ETC_HOSTS)" ]
		then
			echo "$HOST_NAME already exists : $(grep $HOST_NAME $ETC_HOSTS)"
		else
			echo "Adding $HOST_NAME to your $ETC_HOSTS";
			printf "%s\t%s\n" "$IP" "$HOST_NAME" | sudo tee -a $ETC_HOSTS > /dev/null

			if [ -n "$(grep $HOST_NAME $ETC_HOSTS)" ]
				then
                    			echo "$HOST_NAME was added succesfully \n $(grep $HOST_NAME $ETC_HOSTS)";
				else
                    			echo "Failed to Add $HOST_NAME, Try again!";
           		fi
	fi
}

addnginxvhost() {

	NGINX_CONFIG='/etc/nginx/sites-available'
	NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
	WEB_DIR='/var/www/html'
	SED=`which sed`

	# string escaped
	DRUPAL_WEB_FOLDER="\/var\/www\/html\/$SITE_FOLDER_NAME\/web"

	# Now we need to copy the virtual host template
	CONFIG=$NGINX_CONFIG/$HOST_NAME
	sudo cp $NGINX_CONFIG/nginx_template $CONFIG

	# Edit the new virtualhostfile.
	sudo $SED -i "s/DOMAIN/$HOST_NAME/g" $CONFIG
	sudo $SED -i "s/WEB_DIR/$DRUPAL_WEB_FOLDER/g" $CONFIG
	sudo $SED -i "s/SITE_NAME/$SITE_FOLDER_NAME/g" $CONFIG

	# create symlink to enable site
	sudo ln -s $CONFIG $NGINX_SITES_ENABLED/$HOST_NAME
 
	# reload Nginx to pull in new config
	sudo /etc/init.d/nginx reload
 
	echo "Nginx host Created for $HOST_NAME"
}

# Write to your local hostfile.
addhost

# Create a new nginx vhos file.
addnginxvhost

