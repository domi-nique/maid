#!/bin/bash

function usage()
{
    echo -e "maid"
    echo -e "\t-h --help"
    echo -e ""
    echo -e "\t-a --all\t\tPerform all tasks"
    echo -e ""
    echo -e "\t-c --cache\t\tClean Magento cache"
    echo -e "\t-com --compiled\t\tDump generated code"
    echo -e "\t-f --frontend\t\tClear static content and generated views"
    echo -e "\t-p --permissions\tSet environment permissions"
    echo -e "\t-d --deployment\tRun deployment tasks"
    echo -e ""
}

function all()
{
    permissions;
    compiled;
    frontend;
    cache;
}

function cache()
{
    echo "Emptying caches .."

    bin/magento cache:clean
    rm -rf var/cache/*
}

function compiled()
{
    echo "Dumping generated code .."

    rm -rf generated/code/*
}

function frontend()
{
    echo "Clearing frontend .."

    echo "Removing preprocessed views .."
    rm -rf var/view_preprocessed/*

    echo "Dumping static content .."
    rm -rf pub/static/*
}

function permissions()
{
    echo "Setting permissions .."

    echo "chmod .."
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
    chmod u+x bin/magento

    echo "chown .."
    chown -R :www-data .
    chown -R www-data:www-data var
    chown -R www-data:www-data generated
    chown -R www-data:www-data pub/static
    chown -R www-data:www-data pub/media
}

function deployment()
{
    echo "Run deployment tasks.."

    echo "Performing composer install"
    composer install
    
    echo "Cleaning Magento caches"
    php bin/magento cache:clean

    echo "Performing dependency injection compile"
    php bin/magento setup:di:compile

    echo "Performing upgrade migrations"
    php bin/magento setup:upgrade --keep-generated

    echo "Remove static content"
    rm -rf var/view_preprocessed/* && rm -rf pub/static/*

    echo "Deploying static content"
    php bin/magento setup:static-content:deploy de_DE en_US

    echo "Flushing Magento caches"
    php bin/magento cache:flush

}

function checkEnv()
{
    if ! test -f "bin/magento"; then
        echo "It looks like you are not in your Magento folder (bin/magento not found)."
        exit 1
    fi
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -a | --all)
            checkEnv
            all
            echo "Done."
            exit;
            ;;
        -c | --cache)
            checkEnv
            cache
            echo "Done."
            exit;
            ;;
        -com | --compiled)
            checkEnv
            compiled
            echo "Done."
            exit;
            ;;
        -f | --frontend)
            checkEnv
            frontend
            echo "Done."
            exit;
            ;;
        -p | --permissions)
            checkEnv
            permissions
            echo "Done."
            exit;
            ;;
        -d | --deployment)
            checkEnv
            deployment
            echo "Done."
            exit;
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

usage
