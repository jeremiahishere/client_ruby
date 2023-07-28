# encoding: UTF-8

module Prometheus
  module Client
    class ValueWithExemplar
      attr_accessor :value, :exemplar_labels, :exemplar_value, :exemplar_timestamp

      def self.from_json(json)
        attributes = JSON.parse(json)
        new(attributes) # this needs some more initialize args to actually work
      end

      def initialize(val: 0)
        self.value = val
      end

      def value=(new_val)
        @value = new_val.to_f
      end

      # to be cleaned up
      def setup_exemplar(data)
        if !data.empty? # don't store an exemplar on an empty values hash (might need to be converted to a nil check)
          now = Time.now

          if !exemplar_timestamp # no previous exemplar set
            exemplar_labels = data
            exemplar_value = value
            exemplar_timestamp = now
          elsif now > exemplar_timestamp # previous exemplar in the past
            exemplar_labels = data
            exemplar_value = value
            exemplar_timestamp = now
          end
        end
      end

      def to_hash
        {
          value: value,
          exemplar_labels: exemplar_labels,
          exemplar_value: exemplar_value,
          exemplar_timestamp: exemplar_timestamp
        }
      end

      def to_json
        to_hash.to_json
      end
    end
  end
end
