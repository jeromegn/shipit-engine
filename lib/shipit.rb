require 'active_support/all'
require 'active_model_serializers'
require 'state_machines-activerecord'
require 'validate_url'
require 'responders'
require 'explicit-parameters'

require 'sass-rails'
require 'coffee-rails'
require 'jquery-rails'
require 'rails-timeago'
require 'ansi_stream'
require 'autoprefixer-rails'

require 'omniauth-github'

require 'pubsubstub'
require 'safe_yaml/load'
require 'securecompare'

require 'redis-objects'

require 'octokit'
require 'faraday-http-cache'

require 'shipit/null_serializer'
require 'shipit/csv_serializer'
require 'shipit/octokit_iterator'
require 'shipit/first_parent_commits_iterator'
require 'shipit/simple_message_verifier'

require 'command'
require 'commands'
require 'stack_commands'
require 'task_commands'
require 'deploy_commands'
require 'rollback_commands'

require 'shipit/engine'

SafeYAML::OPTIONS[:default_mode] = :safe
SafeYAML::OPTIONS[:deserialize_symbols] = false

module Shipit
  extend self

  def app_name
    @app_name ||= secrets.app_name || Rails.application.class.name.split(':').first
  end

  def redis_url
    return @redis_url if defined?(@redis_url)
    @redis_url = secrets.redis_url.present? ? URI(secrets.redis_url) : nil
  end

  def redis
    @redis ||= Redis.new(url: redis_url.to_s, logger: Rails.logger)
  end

  def github_api
    @github_api ||= begin
      client = Octokit::Client.new(github_api_credentials)
      client.middleware.use(
        Faraday::HttpCache,
        shared_cache: false,
        store: Rails.cache,
        logger: Rails.logger,
        serializer: NullSerializer,
      )
      client
    end
  end

  def github_api_credentials
    (Rails.application.secrets.github_api || {}).symbolize_keys
  end

  def api_clients_secret
    secrets.api_clients_secret || ''
  end

  def host
    secrets.host.presence
  end

  def github_team
    @github_team ||= github_oauth_credentials['team'] && Team.find_or_create_by_handle(github_oauth_credentials['team'])
  end

  def github_oauth_id
    github_oauth_credentials['id']
  end

  def github_oauth_secret
    github_oauth_credentials['secret']
  end

  def github_oauth_credentials
    secrets.github_oauth || {}
  end

  def all_settings_present?
    @all_settings_present ||= [
      github_oauth_id,
      github_oauth_secret,
      github_api_credentials,
      redis_url,
      host,
    ].all?(&:present?)
  end

  def extra_env
    secrets.env || {}
  end

  def revision
    @revision ||= begin
      if revision_file.exist?
        revision_file.read
      else
        `git rev-parse HEAD`
      end.strip
    end
  end

  protected

  def revision_file
    Rails.root.join('REVISION')
  end

  def secrets
    Rails.application.secrets
  end
end
