# Nextcloud-Lucene stack

This repository aims to provide configuration to build a custom docker image for nextcloud and run it in a more advanced structure.
It features:

- **Nextcloud** 
  - **Based on the [apache/full example](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles/full/apache)** containing smbclient, imap and ffmpeg
  - **plus php_soap** for usage of Apps like [user_ispconfig](https://apps.nextcloud.com/apps/user_ispconfig)
    We use it for authentication of users against mailboxes created on our ISPConfig managed multiserver stack
  - **plus control script for [fulltext search](https://apps.nextcloud.com/apps/fulltextsearch)**
    auto-installs and configures required apps and starts indexing process for fulltext search index with elastic search
    The script is added to supervisord to be run as process inside the nextcloud container
    It will check for the required nextcloud apps, install and configure them, perform a one-time searchindex update and then start the live-indexing service
- **Redis** configured as session store
- **MariaDB** as database backend
- **Elasticsearch** as searchindex service
  Extends the original image with the required ingest-attachment plugin



## Get it up and running

1. Clone this repository and edit the environment variables in docker-compose.yml for your needs. Especially make sure to set save usernames and passwords.
2. Set base image in Dockerfile to your desired Nextcloud image version from docker hub
   Current default: **nextcloud:19.0.3-apache**
3. (optional)
   Pre-Build nextcloud image by running `docker-compose build`
   Will be built upon compose up if it does not exist
4. Run the stack with `docker-compose up -d`
   This will start redis, mysql and elasticsearch, install a new nextcloud instance, add and configure fulltextsearch to the nextcloud and run the indexing service



## Troubleshooting

1. **A service complains about not writable folders**
   In the setup of this compose file, nextcloud mounts local volumes.
   Make sure they are owned by user and group 33 so it is writable for the executing www-data user in the container: `chmod -R 33:33 ./nextcloud/*`
   If you use a bind-mount for database, ensure to give it to the mysql user: `chmod -R 999:999 ./your-db-folder`
   If you use a bind-mount for elasticsearch, ensure to give it to the executing user, too: `chmod -R 1000:0 ./your-index-folder`
2. **Some seconds after starting, the nextcloud container drains a lot of system ressources**
   You either migrated the data of a pre-existing cloud instance, reset the searchindex or deleted the search index mount of the elasticsearch container. The start_indexing.sh script performs a update of the searchindex, indexing all data not yet present in the searchindex. Having lots of unindexed files in the cloud, this could take a while and take a lot of system ressources.
3. **My Searchindex seems broken, I want to rebuild it**
   Get a bash into the app container as user www-data (e.g. `docker-compose exec -u www-data app bash`) and run `./occ fulltextsearch:reset`
   Restart the app-container afterwards to perform a new full index of your cloud (mind the system resource point above).