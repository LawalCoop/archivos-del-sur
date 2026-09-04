#!/bin/sh
set -e

# /var/www/html/files is a named volume that keeps whatever ownership it had
# when it was first created, so a build-time `chown` in the Dockerfile never
# reaches it. Fix it on every container start instead.
chown -R www-data:www-data /var/www/html/files

exec "$@"
