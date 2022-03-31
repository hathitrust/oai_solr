# OAI-PMH Provider for Solr

An Open Archives Initiative - Protocol for Metadata Harvesting (OAI-PMH)
provider backed by metadata records in Solr

## Initial Setup
```bash
git clone https://github.com/hathitrust/oai_solr
docker-compose up
```

## Using an External Solr

TODO add instructions here for adjusting docker-compose.yml

## Planned Features

* Paging and resumption tokens using Solr
* On-the-fly transformation of records in Solr to OAI output in various metadata formats
* Sets based on Solr filters
