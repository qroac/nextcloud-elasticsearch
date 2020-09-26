#!/bin/bash
fulltextsearch_installed () {
	# At least the following apps need to be installed:
	# fulltextsearch
	# fulltextsearch_elasticsearch
	# files_fulltextsearch
	if [ "`/var/www/html/occ app:list | grep fulltextsearch | wc -l`" -ge 3 ]; then 
		return 1 
	fi	
	return 0
}

fulltextsearch_install() {
	echo "Installing fulltextsearch apps to nextcloud"
	/var/www/html/occ app:install fulltextsearch
	/var/www/html/occ app:install files_fulltextsearch
	/var/www/html/occ app:install fulltextsearch_elasticsearch
}

fulltextsearch_configure() {
	echo "Configuring fulltextsearch for elasticsearch indexing"
	/var/www/html/occ config:app:set --value "OCA\FullTextSearch_ElasticSearch\Platform\ElasticSearchPlatform" fulltextsearch search_platform
	/var/www/html/occ config:app:set --value "http://elasticsearch:9200" fulltextsearch_elasticsearch elastic_host
	/var/www/html/occ config:app:set --value "nextcloud" fulltextsearch_elasticsearch elastic_index
}

while fulltextsearch_installed -ne 1 ; do
	echo "Required nextcloud apps not found; Trying to install"
	fulltextsearch_install
	fulltextsearch_configure
	sleep 15
done

echo "Performing full index run for indexing missing objects"
/var/www/html/occ fulltextsearch:index -rnq

echo "Starting live indexing service"
/var/www/html/occ fulltextsearch:live -q
