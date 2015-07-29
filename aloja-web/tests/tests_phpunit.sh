#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
( cd ${BASE_DIR}/.. ; ${BASE_DIR}/../vendor/bin/phpunit -c ${BASE_DIR}/../phpunit.xml )
