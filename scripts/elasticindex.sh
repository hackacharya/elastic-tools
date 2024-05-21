#!/bin/bash 

# elasticindex.sh 
# Quick tool to get started with ELastic and doing mundane tasks.

# Copyright 2024 hackacharya@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the “Software”), to deal 
# in the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
# the Software, and to permit persons to whom the Software is furnished to do so, 
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# -------------------------------------------------------------------------------

# Set this in the env, if not defaults will  used
# We use usernamepassword auth.
ELASTIC_URL=${ELASTIC_URL:=http://elastic:unknown@127.0.0.1:9200}
INDEX=${ELASTIC_INDEX:=test-index}

# Assume we have curl
# '-k' is not great but start from there.
CURL="curl -s -k --connect-timeout 10"

#CURL="curl -s -k -v"

case $1 in 
help)
	cat << ENDOFHELP

Usage: $0 command [options]

export the following variables with proper values then use this script
	# use https wherever possible
 	export ELASTIC_URL=http://user:password@127.0.0.1:9200
	export ELASTIC_INDEX=test-index

If you are on a kube environment you may portfoward to your elastic service
        kubectl port-forward service/elasticsearch-es-default 9200:9200

	Commands -
		$0 create <indexname> - Create an index
		$0 show 	-  show the index
		$0 writedocs	- Write some JSON docs to to the index 
		$0 getdocs 	- Get docs from an index with doc ids
		$0 deletedocs docid1 docid2 docid3 
		$0 list  	- List indexes
		$0 templates    - list templates info
		$0 search <searchstring> 
ENDOFHELP
	;;
templates) 
	$CURL "${ELASTIC_URL}/_index_template"
	;;
list) 
	$CURL  "${ELASTIC_URL}/_cat/indices?v" 
	;;

createwts) 
	$CURL  -XPUT "${ELASTIC_URL}/${INDEX}" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    }
  },
  "mappings": {
    "properties": {
      "timestamp": {
        "type": "date"
      },
      "time": {
        "type": "date"
      }
    }
  }
}'
;;
create) 
	# One Shard and 1 REPLICA for now
	INDEX=$2;
	$CURL  -XPUT "${ELASTIC_URL}/${INDEX}" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    }
  }
}'
	;;
delete)
	INDEX=$2;
	read -p "Are you sure you want to delete ${INDEX}? " ans
	ANSW=`echo $ans | tr a-z A-Z`
	if test "x${ANSW}" == "xYES"; then
		$CURL -XDELETE ${ELASTIC_URL}/${INDEX}
	else
		echo "Ok. Doing nothing!"
	fi
	;;

show)
	$CURL "${ELASTIC_URL}/_cat/indices/${INDEX}?v"
	;;

writedocs)
	NUMDOCS=$2
	# write send some sample docs do some random genration
	echo "Writing first doc to $INDEX "
	$CURL "${ELASTIC_URL}/${INDEX}/_doc" -H "Content-Type: application/json" -d'
{ "@timestamp":"2024-04-14T09:10:10.000Z", "message": " Completed metrics collection successfully.", "level": "INFO", "app":"fbtest", "module": "moda", "namespace": "sandbox" }'

	echo "Writing second doc to $INDEX "
	$CURL "${ELASTIC_URL}/${INDEX}/_doc" -H "Content-Type: application/json" -d'
{ "@timestamp":"2024-04-14T08:20:10.000Z", "message": "Connection to database 127.0.0.1:5432 regained after 4 attempts?",   "level": "INFO", "app":"fbtest", "module": "moda", "namespace": "sandbox" }'

	echo "Writing thrid doc to $INDEX"
	$CURL "${ELASTIC_URL}/${INDEX}/_doc" -H "Content-Type: application/json" -d'
{ "@timestamp":"2024-04-14T07:20:00.000Z", "message": "Rate of API threshold crossed 800/sec!",  "level": "CRITICAL", "app":"fbtest", "module": "moda", "namespace": "sandbox" }'
;;

getdocs)
	if [ "x$2" != "x" ]; then
		INDEX=$2
        fi
	ecoh "Reading everything from $INDEX .. "
	$CURL -XGET "$URL/${INDEX}/_search" -H "Content-Type: application/json" -d'{ "query": { "match_all": {} } }'
	;;

deletedocs)
	shift;
	if test $# -eq 0 ; then
           echo "No document ids specified to delete. Doing nothing."
   	   exit 0
	fi
	for docid in `echo $*`
	do
	   $CURL -XDELETE "$URL/${INDEX}/_doc/${docid}"
	   echo
	done
	;;

search)
	# very simplistic don't use *s and such for now. Results undefined :-)
	PATTERN="$2";
	$CURL -XGET "$URL/${INDEX}/_search" -H "Content-Type: application/json" -d'{ "query": { "match": { "module": "$PATTERN" } } }'
	;;
esac
RETVAL=$?
echo
exit $RETVAL

#---------------------------------------------------------------------------------
# TODO for another day
ILM policy create
This Elasticsearch request will create or update this index lifecycle policy.

PUT _ilm/policy/FourteenDaysLowPrio
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "14d",
            "max_primary_shard_size": "10gb"
          },
          "set_priority": {
            "priority": 50
          }
        },
        "min_age": "0ms"
      }
    }
  }
}



PUT _index_template/applogs_template
{
  "index_patterns": ["applogs-test-*"],
  "template": {
    "settings": {
      "number_of_shards": 1
    },
    "mappings": {
      "_source": {
        "enabled": true
      },
      "properties": {
        "host_name": {
          "type": "keyword"
        },
        "created_at": {
          "type": "date",
          "format": "EEE MMM dd HH:mm:ss Z yyyy"
        }
      }
    },
    "aliases": {
      "mydata": { }
    }
  },
  "priority": 500,
  "composed_of": ["component_template1", "runtime_component_template"], 
  "version": 3,
  "_meta": {
    "description": "App logs template"
  }
}
