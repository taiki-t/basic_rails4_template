if yes?("Identical gem versions to the Tutorial? ('n' to install all latest versions.): ")

  remove_file 'Gemfile'
  add_file 'Gemfile'
  add_source 'https://rubygems.org'

  gem 'rails', '4.0.2'
  gem 'bootstrap-sass', '2.3.2.0'
  gem 'bcrypt-ruby', '3.1.2'
  gem 'faker', '1.1.2'
  gem 'will_paginate', '3.0.4'
  gem 'bootstrap-will_paginate', '0.0.9'

  gem_group :development, :test do
    gem 'sqlite3', '1.3.8'
    gem 'rspec-rails', '2.13.1'

    if yes?("Use Guard and Spork?")

      gem 'guard-rspec', '2.5.0'
      gem 'spork-rails', '4.0.0'
      gem 'guard-spork', '1.5.0'
      gem 'childprocess', '0.3.6'

      run remove_file 'test'
    end
  end

  gem_group :test do
    gem 'selenium-webdriver', '2.35.1'
    gem 'capybara', '2.1.0'
    gem 'factory_girl_rails', '4.2.0'
    gem 'cucumber-rails', '1.4.0', :require => false
    gem 'database_cleaner', github: 'bmabey/database_cleaner'

    gem 'growl', '1.0.3' if yes?("Use growl on OS X?")

    gem 'libnotify', '0.8.0' if yes?("Using on Linux?")

    if yes?("Using on Windows?")
      gem 'rb-notifu', '0.0.4'
      gem 'win32console', '1.3.2'
      gem 'wdm', '0.1.0'
    end
  end

  gem 'sass-rails', '4.0.1'
  gem 'uglifier', '2.1.1'
  gem 'coffee-rails', '4.0.1'
  gem 'jquery-rails', '3.0.4'
  gem 'turbolinks', '1.1.1'
  gem 'jbuilder', '1.0.2'

  gem_group :doc do
    gem 'sdoc', '0.3.20', require: false
  end

  gem_group :production do
    gem 'pg', '0.15.1'
    gem 'rails_12factor', '0.0.2'
  end

else # up-to-date default setting

  gem 'bootstrap-sass'
  gem 'bcrypt-ruby'
  gem 'faker'
  gem 'will_paginate'
  gem 'bootstrap-will_paginate'

  gem_group :development, :test do
    gem 'sqlite3'
    gem 'rspec-rails'

    if yes?("Use Guard and Spork?")

      gem 'guard-rspec'
      gem 'spork-rails'
      gem 'guard-spork'
      gem 'childprocess'
    end
  end

  gem_group :test do
    gem 'selenium-webdriver'
    gem 'capybara'
    gem 'factory_girl_rails'
    gem 'cucumber-rails', :require => false
    gem 'database_cleaner', github: 'bmabey/database_cleaner'

    gem 'growl' if yes?("Use growl on OS X?")

    gem 'libnotify' if yes?("Are you on Linux?")

    if yes?("Are you on Windows?")
      gem 'rb-notifu'
      gem 'win32console'
      gem 'wdm'
    end
  end

  gem_group :production do
    gem 'pg'
    gem 'rails_12factor'
  end
end

gsub_file 'gemfile',/# Use sqlite3 as the database for Active Record\n.*'/, ''

run 'bundle install'

# bootstrap(twitter)
# ------------------------------------
create_file 'app/assets/stylesheets/custom.css.scss' ,'@import "bootstrap";'
gsub_file 'app/assets/javascripts/Application.js', %r{//= require jquery_ujs}, <<EOF
//= require jquery_ujs
//= require bootstrap
EOF

# RSpec and Guard
# -------------------------------------------------

remove_file 'test'
run 'rails generate rspec:install'
run 'bundle exec guard init rspec'

prepend_file 'guardfile', "require 'active_support/inflector'
"

gsub_file 'guardfile', /guard :rspec do/, <<'EOF'
guard 'rspec', all_after_pass: false do

 # Custom Rails Tutorial specs
  watch(%r{^app/controllers/(.+)_(controller)\.rb$}) do |m|
    ["spec/routing/#{m[1]}_routing_spec.rb",
     "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb",
     "spec/acceptance/#{m[1]}_spec.rb",
     (m[1][/_pages/] ? "spec/requests/#{m[1]}_spec.rb" :
                       "spec/requests/#{m[1].singularize}_pages_spec.rb")]
  end
  watch(%r{^app/views/(.+)/}) do |m|
    (m[1][/_pages/] ? "spec/requests/#{m[1]}_spec.rb" :
                      "spec/requests/#{m[1].singularize}_pages_spec.rb")
  end
  watch(%r{^app/controllers/sessions_controller\.rb$}) do |m|
    "spec/requests/authentication_pages_spec.rb"
  end
EOF

# spork
# -------------------------------------------
run 'bundle exec spork --bootstrap'

gsub_file 'spec/spec_helper.rb', /require.*end/m, <<'EOF'
require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  # Checks for pending migrations before tests are run.
  # If you are not using ActiveRecord, you can remove this line.
  ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

  RSpec.configure do |config|
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = "random"
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.

EOF


# .gitignore
# ----------------------------------------------

append_file '.gitignore', <<'EOF'

# Ignore other unneeded files.
database.yml
doc/
*.swp
*~
.project
.DS_Store
.idea
.secret
EOF

# secret_token
# -----------------------------------------------
@app_name = app_name

remove_file 'config/initializers/secret_token.rb'
create_file 'config/initializers/secret_token.rb', <<EOF
  # Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
require 'securerandom'

def secure_token
  token_file = Rails.root.join('.secret')
  if File.exist?(token_file)
    # Use the existing token.
    File.read(token_file).chomp
  else
    # Generate a new token and store it in token_file.
    token = SecureRandom.hex(64)
    File.write(token_file, token)
    token
  end
end

#{@app_name.classify}::Application.config.secret_key_base = secure_token
EOF