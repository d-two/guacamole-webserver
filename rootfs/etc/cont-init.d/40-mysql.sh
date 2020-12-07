#!/usr/bin/with-contenv sh

declare host
declare port
declare database
declare username
declare password

# Read config
while IFS=': ' read -ra line
do
	case "${line[0]}" in
        "mysql-hostname") 	host=${line[1]} ;;
		"mysql-port") 		port=${line[1]} ;;
		"mysql-database") 	database=${line[1]} ;;
		"mysql-username") 	username=${line[1]} ;;
		"mysql-password") 	password=${line[1]} ;;
    esac
done < ${GUACAMOLE_HOME}/guacamole.properties

#echo "${host}"
#echo "${port}"
#echo "${database}"
#echo "${username}"
#echo "${password}"

# Create database if not exists
echo "CREATE DATABASE IF NOT EXISTS ${database}2;" \
    | mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}"
