#!/bin/bash

DBNAME=""
EXPIRATION="30"
Green='\033[0;32m'
EC='\033[0m' 
FILENAME=`date +%H_%M_%d%m%Y`

# terminate script on any fails
set -e

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -exp|--expiration)
    EXPIRATION="$2"
    shift
    ;;
    -db|--dbname)
    DBNAME="$2"
    shift
    ;;
esac
shift
done

if [[ -z "$DBNAME" ]]; then
  echo "Missing DBNAME variable"
  exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  if [[ ! -z "$S3_ACCESS_KEY" ]]; then
    export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY
  else
    echo "Missing AWS_ACCESS_KEY_ID variable"
    exit 1
  fi
fi

if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  if [[ ! -z "$S3_SECRET" ]]; then
    export AWS_SECRET_ACCESS_KEY=$S3_SECRET
  else
    echo "Missing AWS_SECRET_ACCESS_KEY variable"
    exit 1
  fi
fi
if [[ -z "$AWS_DEFAULT_REGION" ]]; then
  echo "Missing AWS_DEFAULT_REGION variable"
  exit 1
fi
if [[ -z "$S3_DB_BACKUP_BUCKET_PATH" ]]; then
  echo "Missing S3_DB_BACKUP_BUCKET_PATH variable"
  exit 1
fi

if [[ -z "$DATABASE_URL" ]]; then
  echo "Missing DATABASE_URL variable"
  exit 1
fi

if [[ -z "$GPG_SECRET" ]]; then
  echo "Missing GPG_SECRET variable"
  exit 1
fi

printf "${Green}Start dump${EC}"
# Maybe in next 'version' use heroku-toolbelt
# /app/vendor/heroku-toolbelt/bin/heroku pg:backups capture $DATABASE --app $HEROKU_TOOLBELT_APP
# BACKUP_URL=`/app/vendor/heroku-toolbelt/bin/heroku pg:backups:public-url --app $HEROKU_TOOLBELT_APP | cat`
# curl --progress-bar -o /tmp/"${DBNAME}_${FILENAME}" $BACKUP_URL
# gzip /tmp/"${DBNAME}_${FILENAME}"

GZIP_DUMP_FILE=/tmp/"${DBNAME}_${FILENAME}".gz
GPG_DUMP_FILE=$GZIP_DUMP_FILE.gpg

time pg_dump $DATABASE_URL | gzip >  $GZIP_DUMP_FILE
#EXPIRATION_DATE=$(date -v +"2d" +"%Y-%m-%dT%H:%M:%SZ") #for MAC
EXPIRATION_DATE=$(date -d "$EXPIRATION days" +"%Y-%m-%dT%H:%M:%SZ")

printf "${Green}Move dump to AWS${EC}"

time gpg --cipher-algo aes256 --output $GPG_DUMP_FILE --passphrase $GPG_SECRET --batch --yes --no-use-agent --symmetric $GZIP_DUMP_FILE

time /app/vendor/awscli/bin/aws s3 cp $GPG_DUMP_FILE s3://$S3_DB_BACKUP_BUCKET_PATH/$DBNAME/"${GPG_DUMP_FILE}" --expires $EXPIRATION_DATE

# cleaning after all
rm $GZIP_DUMP_FILE
rm $GPG_DUMP_FILE
