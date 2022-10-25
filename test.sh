#!/bin/bash

composer --version || exit 1
php -v | grep "^PHP" || (echo "PHP missing" && exit 1)

## See php and required modules
ALL_MODULES="curl zip intl gd mbstring zlib fileinfo libxml session SPL fileinfo PDO"

for module in $ALL_MODULES
do
    php -m | grep "$module" || (echo "PHP $module missing" && exit 1)
done

convert --version | grep "^Version" || (echo "convert missing" && exit 1)
identify --version | grep "^Version" || (echo "identify missing" && exit 1)
frankenphp version
