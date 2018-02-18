#! /bin/bash

# Configure Docker-Compose file
# update init-db.sql
# start containers
# load database from init-db.sql

clear;
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd | rev | cut -d '/' -f1 | rev )";
DEFAULTMYSQLPASSWORD="$( openssl rand -base64 15 )";
DEFAULTMYSQLROOTPASSWORD="$( openssl rand -base64 15 )";

echo "Generating WordPress site."
echo "Answer the following questions or press enter to use the default settings."
echo ''

echo -n "Project Name ("${WORKDIR//-/}"): "
read PROJECTNAME
PROJECTNAME="${PROJECTNAME:="${WORKDIR//-/}"}"

DEFAULTDATABASENAME="${PROJECTNAME}_wordpress";
DEFAULTMYSQLUSER="${PROJECTNAME}_user";

echo -n "Site URL (http://localhost:8000): "
read SITEURL
SITEURL="${SITEURL:="http://localhost:8000"}"

echo -n "SITE Title ("${PROJECTNAME}"): "
read SITETITLE
SITETITLE="${SITETITLE:="${PROJECTNAME}"}"

echo -n "Database Name ("${DEFAULTDATABASENAME}"): "
read DATABASENAME
DATABASENAME="${DATABASENAME:="${DEFAULTDATABASENAME}"}"

echo -n "MySQL User ("${DEFAULTMYSQLUSER}"): "
read MYSQLUSER
MYSQLUSER="${MYSQLUSER:="${DEFAULTMYSQLUSER}"}"

echo -n "MySQL Password ("${DEFAULTMYSQLPASSWORD}"): "
read MYSQLPASSWORD
MYSQLPASSWORD="${MYSQLPASSWORD:="${DEFAULTMYSQLPASSWORD}"}"

echo -n "MySQL root Password ("${DEFAULTMYSQLROOTPASSWORD}"): "
read MYSQLROOTPASSWORD
MYSQLROOTPASSWORD="${MYSQLROOTPASSWORD:="${DEFAULTMYSQLROOTPASSWORD}"}"

sed "s#MYSQLROOTPASSWORD#"${MYSQLROOTPASSWORD}"#g" ./docker-compose.yml.tmpl > docker-compose.yml
sed -i -e "s#MYSQLUSER#"${MYSQLUSER}"#g" ./docker-compose.yml
sed -i -e "s#MYSQLPASSWORD#"${MYSQLPASSWORD}"#g" ./docker-compose.yml
sed -i -e "s#DATABASENAME#"${DATABASENAME}"#g" ./docker-compose.yml
sed -i -e "s#PROJECTNAME#"${PROJECTNAME}"#g" ./docker-compose.yml
rm ./docker-compose.yml-e

sed "s#DATABASENAME#"${DATABASENAME}"#g" ./init_db.sql.tmpl > init_db.sql
sed -i -e "s#SITEURL#"${SITEURL}"#g" ./init_db.sql
sed -i -e "s#SITETITLE#"${SITETITLE}"#g" ./init_db.sql
rm ./init_db.sql-e

docker-compose --project-name="${PROJECTNAME}" up -d
sleep 15

mysql -u root "-p${MYSQLROOTPASSWORD}" --host="127.0.0.1" --port="3336" --database="${DATABASENAME}" < "./init_db.sql";

echo ''
echo ' ----------------------------------------------------------'
echo ''
echo "Your project has been configured, here are the site settings:"
echo WORKDIR: $WORKDIR
echo PROJECTNAME: $PROJECTNAME
echo SITEURL: $SITEURL
echo SITETITLE: $SITETITLE
echo DATABASENAME: $DATABASENAME
echo MYSQLUSER: $MYSQLUSER
echo MYSQLPASSWORD: $MYSQLPASSWORD
echo MYSQLROOTPASSWORD: $MYSQLROOTPASSWORD
echo WordPress Username: wpadmin
echo WordPress Password: password

exit 0
