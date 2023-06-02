# encoding: UTF-8

require 'prometheus/client'
require 'prometheus/client/registry'
require 'prometheus/client/formats/open_metrics'

describe Prometheus::Client::Formats::OpenMetrics do
  # Reset the data store
  before do
    Prometheus::Client.config.data_store = Prometheus::Client::DataStores::Synchronized.new
  end

  let(:registry) { Prometheus::Client::Registry.new }

  describe "metric writers" do
    describe "counter" do
      before do
        @foo = registry.counter(:foo,
                               docstring: 'foo description',
                               labels: [:umlauts, :utf, :code],
                               preset_labels: {umlauts: 'Björn', utf: '佖佥'})
        @foo.increment(labels: { code: 'red'}, by: 42)
        @foo.increment(labels: { code: 'green'}, by: 3.14E42)
        @foo.increment(labels: { code: 'blue'}, by: 1.23e-45)
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(@foo)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE foo counter")
        expect(lines).to include("# UNIT foo hotdogs")
        expect(lines).to include("# HELP foo foo description")
      end

      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "histogram" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "gaugehistogram" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "stateset" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "summary" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "info" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "unknown" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end
  end
end
