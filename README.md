# Add Rails Version

```shell
asdf local ruby 2.7.6
```

```shell
set RAILS_VERSION 7.0.3
set GEMFILE_FILE_PATH gemfiles/Gemfile.$RAILS_VERSION.gemfile
echo $GEMFILE_FILE_PATH
```

```shell
bundle install --gemfile="$GEMFILE_FILE_PATH" --retry 1
```

```shell
bundle lock --add-platform x86_64-linux --gemfile $GEMFILE_FILE_PATH
```

```shell
BUNDLE_GEMFILE=$GEMFILE_FILE_PATH ./bin/setup
```

```shell
cd ActiveStorageOverTime && BUNDLE_GEMFILE=$GEMFILE_FILE_PATH bundle exec rails test
```