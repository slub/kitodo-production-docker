#!/bin/bash

set -e

curl -L https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-${BUILDER_RELEASE_VERSION}/${BUILDER_RELEASE_WAR} > /data/kitodo.war

curl -L https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-${BUILDER_RELEASE_VERSION}/${BUILDER_RELEASE_CONFIG_MODULES_ZIP} > /data/kitodo-config-modules.zip

curl -L https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-${BUILDER_RELEASE_VERSION}/${BUILDER_RELEASE_SQL} > /data/kitodo.sql

exit 0
