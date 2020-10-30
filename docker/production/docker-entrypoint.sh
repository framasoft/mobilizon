#!/bin/sh

set -e

echo "-- Running migrations..."
/bin/mobilizon_ctl migrate

echo "-- Starting!"
exec /bin/mobilizon start