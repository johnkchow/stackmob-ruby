# Copyright 2012 StackMob
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rack'
require 'rack/proxy'

module StackMob
  module Middleware
    class Proxy < ::Rack::Proxy
      
      HEADER_NAME = 'X-StackMob-Proxy'
      RACK_ENV_NAME = 'HTTP_X_STACKMOB_PROXY_PLAIN'
      LEGACY_RACK_ENV_NAME = 'HTTP_X_STACKMOB_PROXY'
      VALID_HEADER_VALUES = ['stackmob-api']
      STACKMOB_FORWARDED_HOST_ENV = 'HTTP_X_STACKMOB_FORWARDED_HOST'
      STACKMOB_FORWARDED_PORT_ENV = 'HTTP_X_STACKMOB_FORWARDED_PORT'

      EXCLUDED_HEADERS = ["VERSION", "DATE", "HOST", "ACCEPT"].map { |s| "HTTP_#{s}" }

      def initialize(app)
        @app = app
      end

      def call(env)
        if VALID_HEADER_VALUES.include?(env[RACK_ENV_NAME]) || env['PATH_INFO'] =~ /^\/?.*\/accessToken/
          super(env)
        elsif VALID_HEADER_VALUES.include?(env[LEGACY_RACK_ENV_NAME])  
          req = ::Rack::Request.new(env)
          method = http_method(env)          
          headers = http_headers(env)
          params = [:put,:post].include?(method) ? req.body : req.query_string

          response = client.request(method, :api, env['PATH_INFO'], params, true, headers)

          [response.code.to_i, response.to_hash, response.body]
        else
          @app.call(env)
        end
      end

      def rewrite_env(env)
        env[STACKMOB_FORWARDED_HOST_ENV] = "127.0.0.1"
        env[STACKMOB_FORWARDED_PORT_ENV] = env['SERVER_PORT']
        env['HTTP_HOST'] = StackMob.plain_proxy_host
        if StackMob.plain_proxy_host != ENV['STACKMOB_DEV_URL']
          # rewrite port for api.stackmob.com
          env['SERVER_PORT'] = 80 
        end

        env
      end

      def client
        @client ||= StackMob::Client.new(StackMob.dev_url, StackMob.app_name, StackMob::SANDBOX, StackMob.key, StackMob.secret)
      end
      private :client

      def http_method(env)
        env['REQUEST_METHOD'].downcase.to_sym
      end

      def http_headers(env)
        headers = {}
        for headerArr in env.select { |k, v| k.start_with? 'HTTP_' } 
          if !EXCLUDED_HEADERS.include?(headerArr[0])
            headers[normalize(headerArr[0])] = headerArr[1]
          end
        end
        headers["Accept"] = "application/json"
        headers
      end

      def normalize(key)
        key.sub('HTTP_', '').split('_').map! { |p| p.downcase }.join("-")
      end 

    end
  end
end
