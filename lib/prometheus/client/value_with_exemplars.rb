# encoding: UTF-8

module Prometheus
  module Client
    # stores a value for a label permutation on a metric along with all the exemplars that match the
    # labels.
    #
    # The labels are actually stored somewhere else.  Maybe we could duplicate them here?
    #
    # no idea how this is going to work with histograms
    class ValueWithExemplars
      attr_reader :value, :exemplar, :created

      def initialize
        @exemplars = ExemplarCollection.new
        @value = 0.0

        # slightly confused on the spec for this one
        # One reading is that the created timestamp is on a per label set/metricpoint basis, not per
        # metric.  I also wrote a parallel change that adds the created to the constructor in
        # metric.rb and decided to remove it based on the spec interpretation.
        #
        # Floating point time is used to match the spec examples
        @created = Time.now.to_f
      end

      def most_recent_exemplar
        @exemplars.most_recent
      end

      def set(value:, exemplar:)
        @value = value.to_f
        if exemplar
          exemplar.value = @value # not convinced this line goes in this file
          @exemplars.add(exemplar)
        end

        @value
      end

      def increment(by: 1, exemplar:)
        @value += by
        if exemplar
          exemplar.value = @value # not convinced this line goes in this file
          @exemplars.add(exemplar)
        end

        @value
      end
    end
  end
end
