# typed: ignore

require 'datadog/tracing/contrib/rack/middlewares'

require 'datadog/security/contrib/patcher'
require 'datadog/security/contrib/sinatra/integration'
require 'datadog/security/contrib/rack/request_middleware'
require 'datadog/security/contrib/sinatra/framework'
require 'datadog/tracing/contrib/sinatra/framework'

module Datadog
  module AppSec
    module Contrib
      module Sinatra
        # Set tracer configuration at a late enough time
        module AppSecSetupPatch
          def setup_middleware(*args, &block)
            super.tap do
              Datadog::AppSec::Contrib::Sinatra::Framework.setup
            end
          end
        end

        # Hook into builder before the middleware list gets frozen
        module DefaultMiddlewarePatch
          def setup_middleware(*args, &block)
            builder = args.first

            super.tap do
              if Datadog::Tracing::Contrib::Sinatra::Framework.include_middleware?(Datadog::Tracing::Contrib::Rack::TraceMiddleware, builder)
                Datadog::Tracing::Contrib::Sinatra::Framework.add_middleware_after(Datadog::Tracing::Contrib::Rack::TraceMiddleware, Datadog::AppSec::Contrib::Rack::RequestMiddleware, builder)
              else
                Datadog::Tracing::Contrib::Sinatra::Framework.add_middleware(Datadog::AppSec::Contrib::Rack::RequestMiddleware, builder)
              end
              Datadog::Tracing::Contrib::Sinatra::Framework.inspect_middlewares(builder)
            end
          end
        end

        # Patcher for AppSec on Sinatra
        module Patcher
          include Datadog::AppSec::Contrib::Patcher

          module_function

          def patched?
            Patcher.instance_variable_get(:@patched)
          end

          def target_version
            Integration.version
          end

          def patch
            patch_default_middlewares
            setup_security

            Patcher.instance_variable_set(:@patched, true)
          end

          def setup_security
            ::Sinatra::Base.singleton_class.prepend(AppSecSetupPatch)
          end

          def patch_default_middlewares
            ::Sinatra::Base.singleton_class.prepend(DefaultMiddlewarePatch)
          end
        end
      end
    end
  end
end
