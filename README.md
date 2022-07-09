# Add Rails Version

asdf local ruby 2.7.6

set RUBY_VERSION 7.0.3
set GEMFILE_FILE_PATH gemfiles/Gemfile.$RUBY_VERSION.gemfile
echo $GEMFILE_FILE_PATH

bundle install --gemfile="$GEMFILE_FILE_PATH" --retry 1

bundle lock --add-platform x86_64-linux --gemfile $GEMFILE_FILE_PATH

./bin/setup --rails-version=6.1.6

cd ActiveStorageOverTime && BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails test