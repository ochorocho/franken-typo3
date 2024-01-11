# TYPO3 running on frankenphp

:warning: EXPERIMENTAL!

A single container running TYPO3 using [frankenphp](https://github.com/dunglas/frankenphp) as webserver.

This container ships with TYPO3 located in `/app`. SQLite works out of the box.
The following DBs should work as well but haven't been tested so far:

* MariaDB
* MySQL
* PostgreSQL 

## Image details

* Runs on alpine
* Custom compiled PHP 8.2 required to have all modules enabled for frankenphp
* Custom compiled frankenphp for multi arch (linux/amd64, linux/arm64)

## Test image

TYPO3 will be available under https://localhost:450/

```
docker run --rm \
    -v $PWD/typo3:/app \
    -p 8100:80 \
    -p 450:443 \
    ochorocho/franken-typo3:latest
```

## Install local TYPO3 and mount it

This allows you to test any local TYPO3.

The document root is `/app/public`. To use a local TYPO3 it needs
to be mounted to `/app`.

```
composer create-project typo3/cms-base-distribution typo3
docker run \
    -v $PWD/typo3:/app \
    -p 8100:80 -p 450:443 \
    ochorocho/franken-typo3:latest
```

## Use custom caddy file

Download the [Caddyfile](config/Caddyfile) and mount it to `/etc/Caddyfile` 
and change it as needed. Requires a container restart for changes to take effect.

```
docker run \
    -v $PWD/Caddyfile:/etc/Caddyfile \
    -p 8100:80 \
    -p 450:443 \
    ochorocho/franken-typo3:latest
```

## Build locally

```
export GITHUB_TOKEN=<GITHUB-TOKEN>
docker build --load --platform linux/arm64 --build-arg github_token=${GITHUB_TOKEN} --no-cache --progress=plain . -f Dockerfile -t ochorocho/franken-typo3:latest
```
