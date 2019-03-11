## Heroku Buildpack: heroku-db-backup-s3
Capture Postgress DB in Heroku and copy it to s3 bucket. Buildpack contains AWS CLI.

### Installation
Add buildpack to your Heroku app
```
heroku buildpacks:add https://github.com/devsenexx/heroku-db-backup-s3 --app <your_app>
```
> Buildpacks are scripts that are run when your app is deployed.

### Configure environment variables
```


heroku config:add AWS_ACCESS_KEY_ID=someaccesskey --app <your_app>
heroku config:add AWS_SECRET_ACCESS_KEY=supermegasecret --app <your_app>
heroku config:add S3_DB_BACKUP_BUCKET_PATH=your-bucket --app <your_app>
heroku config:add AWS_DEFAULT_REGION=your-default-region --app <your_app>


S3_ACCESS_KEY can be used instead of AWS_ACCESS_KEY_ID
S3_SECRET can be used instead of AWS_SECRET_ACCESS_KEY
```

Go to settings page of your Heroku application and add Config Var `DBURL_FOR_BACKUP` with the same value as var `DATABASE_URL`. This is our DB connection string.

### Scheduler
Add addon scheduler to your app. 
```
heroku addons:create scheduler --app <your_app>
```
Create scheduler.
```
heroku addons:open scheduler --app <your_app>
```
Now in browser `Add new Job`.
Paste next line:
`bash /app/vendor/backup.sh -db <somedbname>`
and configure FREQUENCY. Paramenter `db` is used for naming convention when we create backups. We don't use it for dumping  database with the same name.

### Doesn't work?
In case if scheduler doesn't run your task, check logs using this e.g.:
```
heroku logs -t  --app <your_app> | grep 'backup.sh'
heroku logs --ps scheduler.x --app <you_app>
```
