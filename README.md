# OAI-PMH Provider for Solr

An Open Archives Initiative - Protocol for Metadata Harvesting (OAI-PMH)
provider backed by metadata records in Solr

## Initial Setup
```bash
git clone https://github.com/hathitrust/oai_solr
cd oai_solr
docker compose build
docker compose run web bundle install
```

## Running tests

```
docker compose run test
```

## How to update repository dependency versions

1- Upgrade the Bundler version specified in the `Gemfile.lock` file to the latest.

```
bundle update --bundler
```

2- Upgrade the versions of the gems specified in the `Gemfile.lock` file to the latest.

```
bundle update --all
```

2- Test the application to make sure the new versions of the dependencies do not cause any issues.

```
docker compose build
docker compose run --rm test bundle install
docker compose run --rm test
```

## Using an External Solr

Follow the README from https://github.com/hathitrust/hathitrust_catalog_indexer
and use the instructions for "Using with other projects via docker" to use this
project with the solr running in that docker-compose environment.

## Planned Features

* Paging and resumption tokens using Solr
* On-the-fly transformation of records in Solr to OAI output in various metadata formats
* Sets based on Solr filters
