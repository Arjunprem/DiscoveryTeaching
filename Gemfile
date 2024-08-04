# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

ruby '3.3.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.2.0.beta2'

# Adds ability to store file attachments for models
gem 'activestorage'
# Adds ability to store file attachments for models on AWS S3
gem 'aws-sdk-s3', require: false

# Adds ability to resize images
gem 'image_processing'
# Adds ability to conveniently validate file attachments
# TODO: migrate to ActiveStorage attachment validations from Rails when introduced
gem 'active_storage_validations'

# Use PostGres as the database for Active Record
gem 'pg'

gem 'bootsnap', require: false
gem 'execjs'
gem 'rb-readline'
gem "recaptcha", require: "recaptcha/rails"

# Shim to load environment variables from .env into ENV in development.
gem 'dotenv', groups: [:development, :test]

gem 'wicked_pdf', '~> 2.1'
gem 'wkhtmltopdf-binary', '~> 0.12.6', group: [:development, :test]
gem 'csv', '~> 3.0'

#https://github.com/norman/friendly_id

gem 'friendly_id' # Note: You MUST use 5.0.0 or greater for Rails 4.0+

group :assets do
  gem 'mini_racer'
end

gem "sprockets-rails"


# The figaro gem offers a practical alternative to setting environment variables in the Unix shell.
gem 'figaro'

# Invicible Catpcha > https://github.com/markets/invisible_captcha
gem 'invisible_captcha'

group :development do
  # a gem to speed up Rails' asset pipeline in development by preventing excessive reloading.
  # gem 'rails-dev-tweaks', '~> 1.1'
  gem 'ibm_watson'
  gem 'listen'
  gem 'web-console'
end


# Use SCSS for stylesheets
gem 'sassc-rails'

gem 'font-awesome-rails'

# This gem embeddes the jQuery colorpicker in the Rails asset pipeline.
gem 'jquery-minicolors-rails'

# Use Uglifier as compressor for JavaScript assets

# jQuery timepicker for Rails
gem 'jquery-timepicker-rails'

# Use Devise for authentication
gem 'devise', '~> 4.9', '>= 4.9.3'

gem 'mimemagic', '~> 0.4.3'

# Puma is a webserver that competes with Unicorn and allows you to process concurrent requests.
gem 'puma'
# Puma worker killer allows you to set up a rolling worker restart of your Puma workers.
gem 'puma_worker_killer'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem 'awesome_print'
gem 'hirb'
gem 'pry'
gem 'pry-rails'
gem 'pry-stack_explorer'

gem 'redis'

gem 'auto_strip_attributes'

gem 'rollbar'
gem 'scout_apm'

group :production do
  gem 'rails_12factor'
  gem 'rack-timeout'
end

group :development, :test do
  gem 'action-cable-testing'
  gem 'foreman'
  gem 'rspec-rails'
  gem 'rubocop', require: false
end

# TODO: tinymce need new version jquery
gem 'tinymce-rails'

gem 'bootstrap_tokenfield_rails'
