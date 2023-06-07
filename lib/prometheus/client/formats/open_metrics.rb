# encoding: UTF-8

module Prometheus
  module Client
    module Formats
      module OpenMetrics
        # used by the middleware to determine if this format works for the request
        MEDIA_TYPE   = 'text/plain'.freeze
        VERSION      = '0.0.1'.freeze
        CONTENT_TYPE = "#{MEDIA_TYPE}; version=#{VERSION}".freeze

        # public interface to generate out the /metrics payload
        def self.marshal(registry)
          lines = []

          registry.metrics.each do |metric|
            # generate metric and put it in lines
            lines << Writer.new(metric).to_open_metrics
          end

          (lines << nil).join(DELIMITER)
        end

        # big questions
        # - how to pull the timestamp out of the metrics repo
        # - how to pull the right number of metrics rows for the given number of timestamps out of
        #   the metrics repo
        # - how to pull out exemplars (and the right number of metric rows for exemplars)
        # - label formatting (copy from the other file)
        # - what does a sample mean in the docs, who decides that we should sample a specific value?
        class Writer
          attr_reader :metric
          def initialize(metric)
            @metric = metric
          end

          def name
            metric.name
          end

          def docstring
            metric.docstring
          end

          def unit
            metric.unit rescue "hotdogs"
          end

          # the spec has a weird conversion with hard coded constants
          # I am not sure if they are necessary
          # for example counter converts to %d99.111.117.110.116.101.114 which really looks like
          # character encodings for the word counter
          def type
            metric.type.to_sym
          end

          def metrics_to_a
            # special case for summaries
            # special case for histograms
            # maybe start with gauges/counters because they are easy
            output = []

            metric.values.collect do |label_set, value|
              if type == :histogram
                output << histogram(metric.name, label_set, value)
              else
                output << metric_line(name, label_set, value, timestamp) # timestamp
              end
            end

            output.flatten
          end

          def histogram(name, label_set, value)
            output = []

            bucket = "#{name}_bucket"
            value.each do |quantile, v|
              next if quantile == "sum"
              output << metric_line(bucket, label_set.merge(le: quantile), v)
            end

            output << metric_line("#{name}_sum", label_set, value["sum"])
            output << metric_line("#{name}_count", label_set, value["+Inf"])

            output
          end

          def metric_line(name, label_set, value, timestamp = nil)
            output = "#{name}#{labels(label_set)} #{value}"
                # require 'debug'; debugger    
            output += " #{timestamp}" if timestamp

            output
          end

          def labels(set)
            return if set.empty?

            output = []

            set.each do |key, value|
              output << "#{key}=\"#{escape(value, :label)}\""
            end

            "{#{output.join(",")}}"
          end

          # to be rewritten
          REGEX   = { doc: /[\n\\]/, label: /[\n\\"]/ }.freeze
          REPLACE = { "\n" => '\n', '\\' => '\\\\', '"' => '\"' }.freeze
          def escape(string, format = :doc)
            string.to_s.gsub(REGEX[format], REPLACE)
          end

          def description
            [
              "# TYPE #{name} #{type}",
              "# UNIT #{name} #{unit}",
              "# HELP #{name} #{docstring}"
            ]
          end

          def write
            (description + metrics_to_a).join("\n")
          end

          def timestamp
            
          end
        end
      end
    end
  end
end
