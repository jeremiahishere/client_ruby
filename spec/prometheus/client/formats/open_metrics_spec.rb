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
      let(:counter_without_ts) do
        counter_without_ts = registry.counter(:counter_without_ts,
                               docstring: 'foo description',
                               labels: [:umlauts, :utf, :code],
                               preset_labels: {umlauts: 'Björn', utf: '佖佥'})
        counter_without_ts.increment(labels: { code: 'red'}, by: 42)
        counter_without_ts.increment(labels: { code: 'green'}, by: 3.14E42)
        counter_without_ts.increment(labels: { code: 'blue'}, by: 1.23e-45)

        counter_without_ts
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE counter_without_ts counter")
        expect(lines).to include("# UNIT counter_without_ts hotdogs")
        expect(lines).to include("# HELP counter_without_ts foo description")
      end

      it "generates a metric without a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("counter_without_ts{umlauts=\"Björn\",utf=\"佖佥\",code=\"red\"} 42.0")
        expect(lines).to include("counter_without_ts{umlauts=\"Björn\",utf=\"佖佥\",code=\"green\"} 3.14e+42")
        expect(lines).to include("counter_without_ts{umlauts=\"Björn\",utf=\"佖佥\",code=\"blue\"} 1.23e-45")
      end

      let(:counter_with_ts) do
        counter_with_ts = registry.counter(:counter_with_ts,
                               docstring: 'foo description',
                               labels: [:umlauts, :utf, :code],
                               preset_labels: {umlauts: 'Björn', utf: '佖佥'},
                               timestamp: 1686111748)
        counter_with_ts.increment(labels: { code: 'red'}, by: 42, timestamp: Time.now.to_i)
        counter_with_ts.increment(labels: { code: 'green'}, by: 3.14E42, timestamp: Time.now.to_i)
        counter_with_ts.increment(labels: { code: 'blue'}, by: 1.23e-45, timestamp: Time.now.to_i + 1)
        counter_with_ts

      end

      xit "generates a metric with a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_with_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("???")
      end

      xit "generates a metric with an exemplar"
    end

    describe "gauge" do
      let :gauge_without_ts do
        bar = registry.gauge(:gauge_without_ts,
                             docstring: "bar description\nwith newline",
                             labels: [:status, :code])
        bar.set(15, labels: { status: 'success', code: 'pink'})

        bar
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(gauge_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE gauge_without_ts gauge")
        expect(lines).to include("# UNIT gauge_without_ts hotdogs")
        # I think the \n should be escaped
        expect(lines).to include("# HELP gauge_without_ts bar description\nwith newline")
      end

      it "generates a metric without a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(gauge_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("gauge_without_ts{status=\"success\",code=\"pink\"} 15.0")
      end

      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end

    describe "histogram" do
      let(:histogram_without_ts) do
        xuq = registry.histogram(:histogram_without_ts,
                                 docstring: 'xuq description',
                                 labels: [:code],
                                 preset_labels: {code: 'ah'},
                                 buckets: [10, 20, 30])
        xuq.observe(12)
        xuq.observe(3.2)

        xuq
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(histogram_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE histogram_without_ts histogram")
        expect(lines).to include("# UNIT histogram_without_ts hotdogs")
        expect(lines).to include("# HELP histogram_without_ts xuq description")
      end

      it "generates a metric without a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(histogram_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("histogram_without_ts_bucket{code=\"ah\",le=\"10\"} 1.0")
        expect(lines).to include("histogram_without_ts_bucket{code=\"ah\",le=\"20\"} 2.0")
        expect(lines).to include("histogram_without_ts_bucket{code=\"ah\",le=\"30\"} 2.0")
        expect(lines).to include("histogram_without_ts_bucket{code=\"ah\",le=\"+Inf\"} 2.0")
        expect(lines).to include("histogram_without_ts_sum{code=\"ah\"} 15.2")
        expect(lines).to include("histogram_without_ts_count{code=\"ah\"} 2.0")
      end
      it "generates a metric with a timestamp" do
        
      end
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

    # describe "summary" do
    #   let(:registry.summary(:summary)) do
    #     counter_without_ts = registry.counter(:counter_without_ts,
    #                            docstring: 'foo description',
    #                            labels: [:umlauts, :utf, :code],
    #                            preset_labels: {umlauts: 'Björn', utf: '佖佥'})
    #     counter_without_ts.increment(labels: { code: 'red'}, by: 42)
    #     counter_without_ts.increment(labels: { code: 'green'}, by: 3.14E42)
    #     counter_without_ts.increment(labels: { code: 'blue'}, by: 1.23e-45)
    #
    #     counter_without_ts
    #   end
    #   it "generates a metric description"
    #   it "generates a metric without a timestamp"
    #   it "generates a metric with a timestamp"
    #   it "generates a metric with an exemplar"
    # end

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
