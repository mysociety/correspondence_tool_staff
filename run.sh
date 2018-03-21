#!/bin/bash
# export RAILS_ENV=production
# Make these available via Settings in the app
export SETTINGS__GIT_COMMIT="$APP_GIT_COMMIT"
export SETTINGS__BUILD_DATE="$APP_BUILD_DATE"
export SETTINGS__GIT_SOURCE="$APP_BUILD_TAG"

case ${DOCKER_STATE} in
create)
    echo "running create"
    bundle exec rails db:setup
    ;;
migrate)
    echo "running migrate"
    bundle exec rails db:migrate
    ;;
reset)
    if [[ "$ENV" = staging || "$ENV" = prod ]]
    then
        echo "cannot reset DB in staging or prod, see"
        echo "https://dsdmoj.atlassian.net/wiki/display/CD/Resetting+the+DB+in+Deployed+Environments"
        echo "for instructions on how to do this manually."
    else
        echo "running DB reset"
        bundle exec rails db:reset
    fi
    ;;
esac

bundle exec puma -C config/puma.rb
