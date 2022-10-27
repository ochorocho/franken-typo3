#!/bin/bash
#--no-cache
# DOCKER_BUILDKIT=1
# docker buildx build --push --platform linux/arm64,linux/amd64 --progress=plain . -f Dockerfile -t ochorocho/franken-typo3:latest && docker run --rm -it -v `pwd`/test.sh:/tmp/test.sh --entrypoint "ash" ochorocho/franken-typo3:latest /tmp/test.sh
docker build --no-cache --progress=plain . -f Dockerfile -t ochorocho/franken-typo3:latest && docker run --rm -it -v `pwd`/test.sh:/tmp/test.sh --entrypoint "ash" ochorocho/franken-typo3:latest /tmp/test.sh
docker images | grep ochorocho/franken-typo3

# docker push ochorocho/gitpod-tdk:latest
# docker run -v $PWD/typo3:/app -p 8100:80 -p 450:443  ochorocho/franken-typo3:latest