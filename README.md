
# elastic-tools
 Elastic Search related scripts and tools for beginners

./elasticindex.sh 
=============================================

Usage: ./elasticindex.sh command [options]

export the following variables with proper values then use this script
       export ELASTIC_URL=http://user:password@127.0.0.1:9200
       export ELASTIC_INDEX=test-index

If you are on a kube environment you may portfoward to your elastic service
        kubectl port-forward service/elasticsearch-es-default 9200:9200

       Commands -
               ./elasticindex.sh create <indexname> - Create an index
               ./elasticindex.sh show  -  show the index
               ./elasticindex.sh writedocs     - Write some JSON docs to to the index
               ./elasticindex.sh getdocs       - Get docs from an index with doc ids
               ./elasticindex.sh deletedocs docid1 docid2 docid3
               ./elasticindex.sh list          - List indexes
               ./elasticindex.sh templates    - list templates info
               ./elasticindex.sh search <searchstring>


./kibana.sh
=============================================
