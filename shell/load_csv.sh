#!/bin/bash
#set -e

#MYSQL_ARGS="-u root --local-infile -f -b --show-warnings -B"
MYSQL_ARGS="-u npm -pquete -h gallactica --local-infile  -f -b  -B"  #--show-warnings

MYSQL_CREDENTIALS="-uvagrant -pvagrant -h127.0.0.1 -P4306"
MYSQL_ARGS="$MYSQL_CREDENTIALS --local-infile -f -b " #--show-warnings -B

if [[ ! -z $5 ]] ; then
  DB="$5"
else
  DB="aloja2"
fi

CSV="$1"
TABLE="$2"
DROP="$3"

if [[ ! -z $4 ]] ; then
  DELIM="$4"
else
  DELIM=","
fi

MYSQL="mysql $MYSQL_ARGS $DB -e "

[ "$CSV" = "" -o "$TABLE" = "" ] && echo "Syntax: $0 csvfile tablename [DROP TABLE]" && exit 1

FIELDS=$(head -1 "$CSV" | sed -e 's/'$DELIM'/` varchar(255),\n`/g' -e 's/\r//g')
FIELDS='`'"$FIELDS"'` varchar(255)'

#echo "$FIELDS" && exit


if [[ ! -z "$DROP" ]] ; then
  echo "DROPING TABLE $TABLE"
  $MYSQL "DROP TABLE IF EXISTS $TABLE;"
fi

if [[ -z $5 ]] ; then
  $MYSQL "CREATE TABLE IF NOT EXISTS $TABLE  ($FIELDS )  ENGINE InnoDB;"
fi

$MYSQL "
SET time_zone = '+00:00';
LOAD DATA LOCAL INFILE '$CSV' INTO TABLE $TABLE
FIELDS TERMINATED BY '$DELIM' OPTIONALLY ENCLOSED BY '\"'
IGNORE 1 LINES;"

echo "Loaded $CSV into $TABLE"