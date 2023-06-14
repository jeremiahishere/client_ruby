# no idea why this is reuired but giving up for now
require 'prometheus/client/exemplar'
require 'prometheus/client/exemplar_collection'
require 'prometheus/client/value_with_exemplars'

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
            @internal_store = Hash.new { |hash, key| hash[key] = Prometheus::Client::ValueWithExemplars.new }
            @lock = Monitor.new
          end

          def synchronize
            @lock.synchronize { yield }
          end

          def set(labels:, val:, exemplar: nil)
            synchronize do
              @internal_store[labels].set(value: val, exemplar: exemplar)
            end
          end

          def increment(labels:, by: 1, exemplar: nil)
            synchronize do
              @internal_store[labels].increment(by: by, exemplar: exemplar)
            end
          end

          def get(labels:, with_exemplars: false)
            synchronize do
              if with_exemplars
                @internal_store[labels]
              else
                @internal_store[labels].value
              end
            end
          end

          def all_values(with_exemplars: false)
            synchronize do
              if with_exemplars
                @internal_store.dup
              else
                # this mess is just for backwards compatibility
                output = Hash.new { |hash, key| hash[key] = 0.0 }
                @internal_store.keys.each do |k|
                  output[k] = @internal_store[k].value
                end

                output
              end
            end
          end
        end

        private_constant :MetricStore
      end
    end
  end
end
