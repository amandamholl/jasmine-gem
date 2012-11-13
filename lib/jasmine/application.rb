require 'rack'
require 'rack/utils'
require 'jasmine-core'
require 'rack/jasmine/runner'
require 'rack/jasmine/focused_suite'
require 'rack/jasmine/redirect'
require 'rack/jasmine/cache_control'
require 'ostruct'

module Jasmine
  class Application
    def self.app(config = Jasmine::RunnerConfig.new)
      page = Jasmine::Page.new(config)
      if Jasmine::Dependencies.rails_3_asset_pipeline?
        config.src_mapper = Jasmine::AssetPipelineMapper.new
      end
      Rack::Builder.app do
        use Rack::Head
        use Rack::Jasmine::CacheControl
        if Jasmine::Dependencies.rails_3_asset_pipeline?
          map('/assets') do
            # In order to have asset helpers like asset_path and image_path, we need to require 'action_view/base'.  This
            # triggers run_load_hooks on action_view which, in turn, causes sprockets/railtie to load the Sprockets asset
            # helpers.  Alternatively, you can include the helpers yourself without loading action_view/base:
            #   Rails.application.assets.context_class.instance_eval do
            #     include ::Sprockets::Helpers::IsolatedHelper
            #     include ::Sprockets::Helpers::RailsHelper
            #   end
            require 'action_view/base'

            run Rails.application.assets
          end
        end

        map('/run.html')         { run Rack::Jasmine::Redirect.new('/') }
        map('/__suite__')        { run Rack::Jasmine::FocusedSuite.new(config) }

        #TODO: These path mappings should come from the config.
        map('/__JASMINE_ROOT__') { run Rack::File.new(Jasmine::Core.path) }
        map(config.spec_path)    { run Rack::File.new(config.spec_dir) }
        map(config.root_path)    { run Rack::File.new(config.project_root) }

        map('/') do
          run Rack::Cascade.new([
            Rack::URLMap.new('/' => Rack::File.new(config.src_dir)),
            Rack::Jasmine::Runner.new(page)
          ])
        end
      end
    end
  end
end
