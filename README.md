# OAI-PMH Provider for Solr

An Open Archives Initiative - Protocol for Metadata Harvesting (OAI-PMH)
provider backed by metadata records in Solr

## Initial Setup
```bash
git clone https://github.com/hathitrust/oai_solr
docker-compose up
```

## Using an External Solr

Follow the README from https://github.com/hathitrust/hathitrust_catalog_indexer
and use the instructions for "Using with other projects via docker" to use this
project with the solr running in that docker-compose environment.

## Planned Features

* Paging and resumption tokens using Solr
* On-the-fly transformation of records in Solr to OAI output in various metadata formats
* Sets based on Solr filters
