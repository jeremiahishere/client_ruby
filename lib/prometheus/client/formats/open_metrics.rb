# encoding: UTF-8

module Prometheus
  module Client
    module Formats
      module OpenMetrics
        # used by the middleware to determine if this format works for the request
        MEDIA_TYPE   = 'application/openmetrics-text'.freeze
        VERSION      = '1.0.0'.freeze
        CONTENT_TYPE = "#{MEDIA_TYPE}; version=#{VERSION}; charset=utf-8".freeze
        DELIMITER = "\n".freeze
        EOF = "# EOF\n".freeze

        # public interface to generate out the /metrics payload
        def self.marshal(registry)
          "hello world"
        end
      end
    end
  end
end
