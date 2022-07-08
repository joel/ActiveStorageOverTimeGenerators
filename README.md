cp tests/attachment_test.rb ActiveStorageOverTime/test/

BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails generate model attachment

bin/rails db:migrate

bin/rails app:active_storage:install

bin/rails db:migrate

BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails app:railties:install:migrations

BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec bin/setup
BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails app:active_storage:update
BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails db:migrate RAILS_ENV=test
BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails test



