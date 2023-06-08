# encoding: UTF-8

module Prometheus
  module Client

    # essentially a wrapper for a hash and a timestamp
    # maybe will hold validity checks eventually
    class Exemplar
      attr_reader :labels, :timestamp, :value
      attr_writer :value
      def initialize(labels: {}, timestamp: nil)
        @labels = labels
        @timestamp = timestamp || Time.now.to_i
      end
    end
  end
end
