# encoding: UTF-8

module Prometheus
  module Client
    module Formats
      module OpenMetrics
        # used by the middleware to determine if this format works for the request
        MEDIA_TYPE   = 'text/plain'.freeze
        VERSION      = '0.0.1'.freeze
        CONTENT_TYPE = "#{MEDIA_TYPE}; version=#{VERSION}".freeze
        DELIMITER = "\n".freeze

        # public interface to generate out the /metrics payload
        def self.marshal(registry)
          lines = []

          registry.metrics.each do |metric|
            # generate metric and put it in lines
            lines << Writer.new(metric).write
          end

          (lines.flatten.compact << nil).join(DELIMITER)
        end

        class Writer
          attr_reader :metric
          def initialize(metric)
            @metric = metric
          end

          def name
            metric.name.to_s
          end

          def docstring
            metric.docstring
          end

          def unit
            metric&.unit || nil
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

            if type == :histogram
              output << histogram
            elsif type == :summary
              output << summary
            elsif type == :counter
              output << counter
            else # if [:gauge].include?(type)
              metric.values(with_exemplars: true).collect do |label_set, value_with_exemplars|
                output << metric_line(name, label_set, value_with_exemplars.value, value_with_exemplars.most_recent_exemplar)
              end
            end

            output.flatten
          end

          def histogram
            output = []

            metric.values.collect do |label_set, value|
              bucket = "#{name}_bucket"
              value.each do |quantile, v|
                next if quantile == "sum"
                output << metric_line(bucket, label_set.merge(le: quantile), v)
              end

              output << metric_line("#{name}_sum", label_set, value["sum"])
              output << metric_line("#{name}_count", label_set, value["+Inf"])
              # created is dependent on the exemplar working
              # output << metric_line("#{name}_created", label_set, created)
            end

            output
          end

          def summary
            output = []

            metric.values.collect do |label_set, vwe|
              output << metric_line("#{name}_sum", label_set, vwe.value["sum"], vwe.most_recent_exemplar)
              output << metric_line("#{name}_count", label_set, vwe.value["count"], vwe.most_recent_exemplar)
              output << metric_line("#{name}_created", label_set, vwe.created)
            end

            output
          end

          def counter
            output = []
            total_value = 0
            most_recent_total_exemplar = Exemplar.new(labels: {}, timestamp: 0)

            metric.values(with_exemplars: true).collect do |label_set, value_with_exemplars|
              value = value_with_exemplars.value
              exemplar = value_with_exemplars.most_recent_exemplar
              created = value_with_exemplars.created

              # hack in support to remove _total from all of our counters because _total is now a
              # reserved word
              metric_name = name.gsub(/_total$/, "")

              output << metric_line(name, label_set, value, exemplar)
              output << metric_line("#{name}_created", label_set, created)

              total_value += value
              most_recent_total_exemplar = exemplar if exemplar && exemplar.timestamp > most_recent_total_exemplar.timestamp
            end
            
            # assume any exemplar fits here (regardless of labels) as long as it is the most recent
            output << metric_line("#{name}_total", {}, total_value, most_recent_total_exemplar)

            output
          end

          def metric_line(name, label_set, value, exemplar = nil)
            output = "#{name}#{labels(label_set)} #{value}"
            output += " #{timestamp}" if timestamp
            output += " # #{labels(exemplar.labels)} #{exemplar.value} #{exemplar.timestamp}" if exemplar && !exemplar.empty?

            output
          end

          def timestamp
            # not implemented yet
            return nil
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
            output = []
            output << "# TYPE #{name} #{type}"
            output << "# UNIT #{name} #{unit}" if unit
            output << "# HELP #{name} #{escape(docstring, :doc)}"

            output
          end

          def write
            (description + metrics_to_a).flatten.join(Prometheus::Client::Formats::OpenMetrics::DELIMITER)
          end

        end
      end
    end
  end
end
