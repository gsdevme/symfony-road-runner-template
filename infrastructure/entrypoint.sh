#!/bin/bash
set -e

if [ -z "$(ls -A /app/vendor)" ]; then
   echo "empty /vendor folder, run composer install first"

   return 1
fi

exec "$@"
