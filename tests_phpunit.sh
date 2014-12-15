#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

( cd ${BASE_DIR}/aloja-web/ ; ${BASE_DIR}/aloja-web/vendor/bin/phpunit -c ${BASE_DIR}/aloja-web/phpunit.xml )
