# encoding: UTF-8

module Prometheus
  module Client

    # Store a snapshot of metric data including an extra set of kv pairs for a specific moment in
    # time and specific moment of code execution.
    #
    # Value is expected to be set after the exemplar is initialized.
    class Exemplar
      # The kv pairs that make up the unique information in the exemplar.
      #
      # We generally store trace ids here
      attr_reader :labels

      # The time the exemplar was recorded
      attr_reader :timestamp

      # The value of the metric at the time the exemplar was recorded
      attr_writer :value
      attr_reader :value

      def initialize(labels: {}, timestamp: nil)
        @labels = labels
        @timestamp = timestamp || Time.now.to_i
      end
    end
  end
end
