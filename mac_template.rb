# DB: postgreSQL
# Test framework: RSpec
# test helper: Guard, Spring
# CSS framework: bootstrap-sass


username = ask 'Please input your database username:'
growl = yes?("Use growl on OS X?")

gem 'bootstrap-sass'
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

  gem 'growl' if growl
end

  gem_group :production do
    gem 'rails_12factor'
  end

run 'bundle install'

# bootstrap(twitter)
# ------------------------------------
create_file 'app/assets/stylesheets/custom.css.scss' ,'@import "bootstrap";'

# include necessary js files.
# -------------------------------------------------
gsub_file 'app/assets/javascripts/Application.js', %r{//= require jquery_ujs}, <<EOF
//= require jquery.turbolinks
//= require jquery_ujs
//= require bootstrap
EOF

# RSpec and Guard
# -------------------------------------------------

remove_file 'test'

run 'rails generate rspec:install'
run 'bundle exec guard init rspec'

add_file 'spec/features'

prepend_file 'guardfile', "require 'active_support/inflector'
"
append_file '.rspec', '--drb'

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

inject_into_file 'config/environments/test.rb', injecting_string, before: "end"

# notification center
# -----------------------------------------------

def send_to_notification_center(body,title, options={})
  subtitle = options[:subtitle]
  sound_name = options[:sound_name]
  string = "display notification \"#{body}\" "
  string << "with title \"#{title}\" "
  string << "subtitle \"#{subtitle}\" "
  string << "sound name \"#{sound_name}\" "

  run "echo '#{string}' | osascript"
end

if growl
  run "echo 'growlnotify -m #{body} -t #{title}' "
else
  send_to_notification_center("You can create anything now!", "Rails new finished.",
                             subtitle: "your turn.", sound_name: "Frog")
end
