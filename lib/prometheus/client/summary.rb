# encoding: UTF-8

require 'prometheus/client/metric'

module Prometheus
  module Client
    # Summary is an accumulator for samples. It captures Numeric data and
    # provides the total count and sum of observations.
    class Summary < Metric
      def type
        :summary
      end

      # Records a given value. The recorded value is usually positive
      # or zero. A negative value is accepted but prevents current
      # versions of Prometheus from properly detecting counter resets
      # in the sum of observations. See
      # https://prometheus.io/docs/practices/histograms/#count-and-sum-of-observations
      # for details.
      def observe(value, labels: {}, exemplar: nil)
        base_label_set = label_set_for(labels)

        @store.synchronize do
          @store.increment(labels: base_label_set.merge(quantile: "count"), by: 1, exemplar: exemplar)
          @store.increment(labels: base_label_set.merge(quantile: "sum"), by: value, exemplar: exemplar)
        end
      end

      # Returns a hash with "sum" and "count" as keys
      def get(labels: {})
        base_label_set = label_set_for(labels)

        internal_counters = ["count", "sum"]

        @store.synchronize do
          internal_counters.each_with_object({}) do |counter, acc|
            acc[counter] = @store.get(labels: base_label_set.merge(quantile: counter))
          end
        end
      end

      # Returns all label sets with their values expressed as hashes with their sum/count
      #
      # Converts from
      # {
      #   {<labels>, :quantile=>"count"} => <value>,
      #   {<labels>, :quantile=>"sum"} => <value>
      # }
      # to
      # {
      #   <labels>: {count: <value>, sum: <value>}
      # }
      #
      # This isn't going to work long term because it isn't possible to differentiate between
      # exemplars whose value is based on the count and exemplars whose value is based on the sum.
      # For now, it is random/unusable.
      def values
        values = @store.all_values(with_exemplars: true)

        values.each_with_object({}) do |(label_set, value_with_exemplars), acc|
          actual_label_set = label_set.reject{|l| l == :quantile }

          if acc.has_key? actual_label_set
            acc[actual_label_set].value[label_set[:quantile]] = value_with_exemplars.value
          else
            new_vwe = ValueWithExemplars.new
            value = { "count" => 0.0, "sum" => 0.0 }.merge({ label_set[:quantile] => value_with_exemplars.value })
            new_vwe.value = value
            new_vwe.exemplars = value_with_exemplars.exemplars # only copy over the exemplars once because both quantiles have the same exemplars

            acc[actual_label_set] = new_vwe
          end
        end
      end

      def init_label_set(labels)
        base_label_set = label_set_for(labels)

        @store.synchronize do
          @store.set(labels: base_label_set.merge(quantile: "count"), val: 0)
          @store.set(labels: base_label_set.merge(quantile: "sum"), val: 0)
        end
      end

      private

      def reserved_labels
        [:quantile]
      end
    end
  end
end
