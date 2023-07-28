require 'prometheus/client/value_with_exemplar'

module Prometheus
  module Client
    module DataStores
      # Stores all the data in simple hashes, one per metric. Each of these metrics
      # synchronizes access to their hash, but multiple metrics can run observations
      # concurrently.
      class Synchronized
        class InvalidStoreSettingsError < StandardError; end

        def for_metric(metric_name, metric_type:, metric_settings: {})
          # We don't need `metric_type` or `metric_settings` for this particular store
          validate_metric_settings(metric_settings: metric_settings)
          MetricStore.new
        end

        private

        def validate_metric_settings(metric_settings:)
          unless metric_settings.empty?
            raise InvalidStoreSettingsError,
                  "Synchronized doesn't allow any metric_settings"
          end
        end

        class MetricStore
          def initialize
            @internal_store = Hash.new { |hash, key| hash[key] = ValueWithExemplar.new }
            @lock = Monitor.new
          end

          def synchronize
            @lock.synchronize { yield }
          end

          def set(labels:, val:, exemplar_labels: {})
            synchronize do
              vwe = @internal_store[labels]
              vwe.value = val
              vwe.setup_exemplar(exemplar_labels)

              vwe.value
            end
          end

          def increment(labels:, by: 1, exemplar_labels: {})
            synchronize do
              vwe = @internal_store[labels]
              vwe.value = vwe.value + by
              vwe.setup_exemplar(exemplar_labels)

              vwe.value
            end
          end

          # get and get_with_exemplars probably combined into a single method eventually
          def get(labels:)
            synchronize do
              @internal_store[labels].value
            end
          end

          def get_with_exemplars(labels:)
            synchronize do
              @internal_store[labels]
            end
          end
          
          # all_values and all_values_with_exemplars probably combined into a single method
          # eventually
          def all_values
            synchronize do
              # this code is bad and I feel bad about it
              new_store = Hash.new { |hash, key| hash[key] = 0.0 }
              @internal_store.keys.each do |k|
                new_store[k] = @internal_store[k].value
              end

              new_store
            end
          end

          def all_values_with_exemplars
            synchronize { @internal_store.dup }
          end
        end

        private_constant :MetricStore
      end
    end
  end
end
