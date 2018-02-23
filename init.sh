#! /bin/bash

# Configure Docker-Compose file
# update init-db.sql
# start containers
# load database from init-db.sql

clear;
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd | rev | cut -d '/' -f1 | rev )";
DEFAULTMYSQLPASSWORD="$( openssl rand -base64 15 )";
DEFAULTMYSQLROOTPASSWORD="$( openssl rand -base64 15 )";
DEFAULTRDSENDPOINT="XXX..us-east-1.rds.amazonaws.com";
DEFAULTPUBLICDNS="ec2-XXX.compute-1.amazonaws.com";
DEFAULTREPO="git@gitlab.com:XXX/XXX";
WPUSER="wpadmin";
WPPASS="password123";


echo "Generating WordPress site."
echo "Answer the following questions or press enter to use the default settings."
echo ''

echo -n "Project Name (\"${WORKDIR//-/}\"): "
read PROJECTNAME
PROJECTNAME="${PROJECTNAME:="${WORKDIR//-/}"}"

DEFAULTDATABASENAME="${PROJECTNAME}_wordpress";
DEFAULTMYSQLUSER="${PROJECTNAME}_user";

echo -n "Local URL (http://localhost:8000): "
read LOCALURL
LOCALURL="${LOCALURL:="http://localhost:8000"}"

echo -n "Production URL (http://somesite.com): "
read PRODURL
PRODURL="${PRODURL:="http://somesite.com"}"

echo -n "RDS Endpoint (\"${DEFAULTRDSENDPOINT}\"): "
read RDSENDPOINT
RDSENDPOINT="${RDSENDPOINT:="${DEFAULTRDSENDPOINT}"}"

echo -n "EC2 Public DNS (\"${DEFAULTPUBLICDNS}\"): "
read PUBLICDNS
PUBLICDNS="${PUBLICDNS:="${DEFAULTPUBLICDNS}"}"

echo -n "Git Repo (\"${DEFAULTREPO}\"): "
read REPO
REPO="${REPO:="${DEFAULTREPO}"}"

echo -n "Site Title (\"${PROJECTNAME}\"): "
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

echo ""
echo "---------------------------------------------"
echo ""
echo "Project Settings:"
echo ""

echo "Project Name: ${PROJECTNAME}"
echo "Local URL: ${LOCALURL}"
echo "Production URL: ${PRODURL}"
echo "RDS Endpoint: ${RDSENDPOINT}"
echo "EC2 Public DNS: ${PUBLICDNS}"
echo "Git Repo: ${REPO}"
echo "Site title: ${SITETITLE}"
echo "Database Name: ${DATABASENAME}"
echo "MySQL User: ${MYSQLUSER}"
echo "MySQL Password: ${MYSQLPASSWORD}"
echo "MySQL root Password: ${MYSQLROOTPASSWORD}"
echo "WordPress User: ${WPUSER}"
echo "WordPress Password: ${WPPASS}"

read -p "Continue (y/n)?" choice
case "$choice" in
  y|Y )
  echo " creating project..."
  ;;
  n|N )
  clear && exit 0
  ;;
esac

cat > project.conf << EOF1
#! /bin/bash

PROJECTNAME=${PROJECTNAME}
LOCALURL=${LOCALURL}
PRODURL=${PRODURL}
RDSENDPOINT=${RDSENDPOINT}
PUBLICDNS=${PUBLICDNS}
REPO=${REPO}
SITETITLE=${SITETITLE}
DATABASENAME=${DATABASENAME}
MYSQLUSER=${MYSQLUSER}
MYSQLPASSWORD=${MYSQLPASSWORD}
MYSQLROOTPASSWORD=${MYSQLROOTPASSWORD}
WPUSER=${WPUSER}
WPPASS=${WPPASS}

EOF1


echo "project.conf Created."
echo "Launching Containers."
sed "s#MYSQLROOTPASSWORD#"${MYSQLROOTPASSWORD}"#g" ./docker-compose.yml.tmpl > docker-compose.yml
sed -i -e "s#MYSQLUSER#"${MYSQLUSER}"#g" ./docker-compose.yml
sed -i -e "s#MYSQLPASSWORD#"${MYSQLPASSWORD}"#g" ./docker-compose.yml
sed -i -e "s#DATABASENAME#"${DATABASENAME}"#g" ./docker-compose.yml
sed -i -e "s#PROJECTNAME#"${PROJECTNAME}"#g" ./docker-compose.yml
rm ./docker-compose.yml-e

sed "s#DATABASENAME#"${DATABASENAME}"#g" ./init_db.sql.tmpl > init_db.sql
sed -i -e "s#SITEURL#"${LOCALURL}"#g" ./init_db.sql
sed -i -e "s#SITETITLE#"${SITETITLE}"#g" ./init_db.sql
rm ./init_db.sql-e

docker-compose --project-name="${PROJECTNAME}" up -d
sleep 15s
# docker compose up, wait for them to come up
echo "Containers Launched."
echo "Loading Database."
mysql -u root "-p${MYSQLROOTPASSWORD}" --host="127.0.0.1" --port="3336" --database="${DATABASENAME}" < "./init_db.sql";
sleep 15s
echo "Database Loaded."
echo "Testing URL."
bash -c 'while [[ "$( curl -s -o /dev/null -w ''%{http_code}'' '${LOCALURL}' )" != "200" ]]; do sleep 5; done'
echo "Local URL responding."

clear
echo "Project ${PROJECTNAME} created! Visit your new WordPress site: ${LOCALURL}"
exit 0;
