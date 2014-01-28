# DB: postgreSQL
# Test framework: RSpec
# test helper: Guard, Spring
# CSS framework: bootstrap-sass

# define variables and methods.
# ------------------------------------
username = ask 'Please input your database username:'
use_growl = yes?("Use growl on OS X?")
use_bt_generators = yes?('Use bootstrap-generators instead of bootstrap-sass?')
use_simple_form = yes?("Use simple_form?")
use_devise = yes?("Use devise?")


def notification(body,title, options={sound_name: "Frog"})
  subtitle = options[:subtitle]
  sound_name = options[:sound_name]
  use_growl = options[:use_growl]

  string = "display notification \"#{body}\" "
  string << "with title \"#{title}\" "
  string << "subtitle \"#{subtitle}\" "
  string << "sound name \"#{sound_name}\" "

  if use_growl
    run "echo 'growlnotify -m #{body} -t #{title}' "
  else
    run "echo '#{string}' | osascript"
  end
end

# ---------------------------------------

if use_bt_generators
  gem 'bootstrap-generators', '~> 3.0.2'
else
  gem 'bootstrap-sass'
end

gem 'simple_form' if use_simple_form
gem 'devise' if use_devise

gem 'bcrypt-ruby'
gem 'faker'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'jquery-turbolinks'

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'guard-rspec'
  gem 'spring'
  gem "spring-commands-rspec"
end

gem_group :test do
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner', github: 'bmabey/database_cleaner'

  gem 'growl' if use_growl
end

  gem_group :production do
    gem 'rails_12factor'
  end


# --------------------------------------------
run 'bundle install'

# bootstrap(twitter)
# --------------------------------------------
if use_bt_generators
  generate 'bootstrap:install', '-f'
else
  create_file 'app/assets/stylesheets/custom.css.scss' ,'@import "bootstrap";'
end

# include necessary js files.
gsub_file 'app/assets/javascripts/Application.js', %r{//= require jquery_ujs}, <<EOF
//= require jquery.turbolinks
//= require jquery_ujs
//= require bootstrap
EOF

# simple_form
# --------------------------------------------

# remove bootstrap-generator side effect to prevent conflicts.
remove_file 'lib/templates/erb/scaffold/_form.html.erb'

simple_form_bootstrap_path = 'config/initializers/simple_form_bootstrap.rb'
url_to_get = "https://gist.github.com/tokenvolt/6599141/raw/09d33083102c0e4bdde1049b321ea4ca66ff1ca0/simple_form_bootstrap3.rb"

generate 'simple_form:install', '--bootstrap' if use_simple_form
remove_file simple_form_bootstrap_path
get url_to_get, simple_form_bootstrap_path

set_btn_primary =<<EOF

  # Default class for buttons
  config.button_class = 'btn btn-primary'

EOF

inject_into_file simple_form_bootstrap_path, set_btn_primary, after: "SimpleForm.setup do |config|\n"


# RSpec
# -------------------------------------------------

remove_file 'test'

generate 'rspec:install'
append_file '.rspec', '--drb'

inside 'spec' do
  empty_directory 'controllers'
  empty_directory 'features'
end


# add configuration to 'spec_helper.rb'
factorygirl_settings =<<EOF

  config.before(:all) do
    FactoryGirl.reload
  end


EOF

inject_into_file 'spec/spec_helper.rb', factorygirl_settings, before: /^end\s*\z/

rspec_settings =<<EOF

    config.generators do |g|
      g.test_framework = "rspec"
      g.controller_specs = false
      g.helper_specs = false
      g.view_specs = false
    end

EOF

application rspec_settings


# guard
# ---------------------------------------------------

run 'bundle exec guard init rspec'
prepend_file 'guardfile', "require 'active_support/inflector'"

gsub_file 'guardfile', /guard :rspec do/, <<'EOF'
guard :rspec, cmd: 'spring rspec -f doc', all_after_pass: false do

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


# database.yml
# -----------------------------------------------
gsub_file 'config/database.yml', /username:.*/, "username: #{username}"

# basic settings
# -----------------------------------------------

git :init
git add: "."
git commit: "-m Initial commit"

rake 'db:create'
rake 'db:migrate'
rake 'db:test:prepare'

# Speed up tests by lowering bcrypt's cost function.
# -----------------------------------------------

injecting_string = <<EOF

  # Speed up tests by lowering bcrypt's cost function.
  ActiveModel::SecurePassword.min_cost = true
EOF

application injecting_string, env: 'test'

# devise
# -----------------------------------------------
if use_devise
  generate 'devise:install'

  host_in_development = "config.action_mailer.default_url_options = { :host => 'localhost:3000' }"
  application host_in_development, env: 'development'

  # modify flash to show devise's error message properly
  gsub_file 'app/views/layouts/application.html.erb', 'name == :error', 'name == :alert'
end
# notification center
# -----------------------------------------------

notification("You can create anything now!", "Rails new finished.",
              subtitle: "your turn.", use_growl: use_growl)
