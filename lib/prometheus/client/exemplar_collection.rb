# encoding: UTF-8

module Prometheus
  module Client
    class ExemplarCollection
      extend Enumerable

      # store the exemplars attached to a metric + label set
      def initialize
        @collection = {}

        # theoretical way to avoid causing a major memory leak
        #
        # This could store two minutes of requests with 2 requests per second with these settings.
        # I am not clear on the situation where this wouldn't be enough but I am sure I will find it
        @max_timestamps = 120
        @max_exemplars = 240
        @exemplar_count = 0
      end

      def add(exemplar)
        cleanup_if_necessary
        @collection[exemplar.timestamp] ||= []
        @collection[exemplar.timestamp] << exemplar

        exemplar
      end

      def most_recent
        @collection[last_key]&.last
      end

      def last
        most_recent
      end

      def each
        @collection.keys.sort.each do |key|
          @collection[key].each do |exemplar|
            yield(exemplar)
          end
        end
      end

      private
      
      def cleanup_if_necessary
        @exemplar_count += 1
        if @exemplar_count > @max_exemplars || @collection.keys.size > @max_timestamps
          @exemplar_count -= @collection.delete(first_key)&.size
        end
      end
      
      def first_key
        @collection.keys.sort&.first
      end

      def last_key
        @collection.keys.sort&.last
      end
    end
  end
end
