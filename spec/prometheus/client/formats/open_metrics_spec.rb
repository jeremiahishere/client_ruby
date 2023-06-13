# encoding: UTF-8

require 'prometheus/client'
require 'prometheus/client/registry'
require 'prometheus/client/formats/open_metrics'
require "prometheus/client/value_with_exemplars"
require "prometheus/client/exemplar_collection"
require "prometheus/client/exemplar"

describe Prometheus::Client::Formats::OpenMetrics do
  # Reset the data store
  before do
    Prometheus::Client.config.data_store = Prometheus::Client::DataStores::Synchronized.new
  end

  let(:registry) { Prometheus::Client::Registry.new }

  describe "metric writers" do
    it "fully supports unit including comment string and forcing a metric name change based on the unit name"

    describe "counter" do
      let(:counter_metric) do
        counter_metric = registry.counter(:counter_metric,
                               docstring: 'foo description',
                               labels: [:umlauts, :utf, :code],
                               preset_labels: {umlauts: 'Björn', utf: '佖佥'})
        counter_metric.increment(labels: { code: 'red'}, by: 42)
        counter_metric.increment(labels: { code: 'green'}, by: 3.14E42)
        counter_metric.increment(labels: { code: 'blue'}, by: 1.23e-45)

        counter_metric
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_metric)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE counter_metric counter")
        # expect(lines).to include("# UNIT counter_metric hotdogs")
        expect(lines).to include("# HELP counter_metric foo description")
      end

      it "generates a metric without exemplars" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_metric)

        lines = writer.write.split("\n")

        expect(lines).to include("counter_metric{umlauts=\"Björn\",utf=\"佖佥\",code=\"red\"} 42.0")
        expect(lines).to include("counter_metric{umlauts=\"Björn\",utf=\"佖佥\",code=\"green\"} 3.14e+42")
        expect(lines).to include("counter_metric{umlauts=\"Björn\",utf=\"佖佥\",code=\"blue\"} 1.23e-45")
      end
      
      let(:counter_with_exemplars) do
        counter_with_exemplars = registry.counter(:counter_with_exemplars,
                               docstring: 'foo description',
                               labels: [:umlauts, :utf, :code],
                               preset_labels: {umlauts: 'Björn', utf: '佖佥'})

        counter_with_exemplars.increment(
          labels: { code: 'red'},
          by: 42,
          exemplar: Prometheus::Client::Exemplar.new(labels: {trace_id: 12345}, timestamp: 1000)
        )
        counter_with_exemplars.increment(labels: { code: 'red'}, by: 1)
        counter_with_exemplars.increment(
          labels: { code: 'blue'},
          by: 1000,
          exemplar: Prometheus::Client::Exemplar.new(labels: {trace_id: 23456}, timestamp: 2000)
        )

        counter_with_exemplars
      end

      it "generates a metric with an exemplar" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_with_exemplars)

        lines = writer.write.split("\n")

        expect(lines).to include("counter_with_exemplars{umlauts=\"Björn\",utf=\"佖佥\",code=\"red\"} 43.0 # {trace_id=\"12345\"} 42.0 1000")
        expect(lines).to include("counter_with_exemplars{umlauts=\"Björn\",utf=\"佖佥\",code=\"blue\"} 1000.0 # {trace_id=\"23456\"} 1000.0 2000")
      end

      it "generates a total metric point with exemplar and without labels" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_with_exemplars)

        lines = writer.write.split("\n")

        expect(lines).to include("counter_with_exemplars_total 1043.0 # {trace_id=\"23456\"} 1000.0 2000")
      end

      it "generates a created metric point without exemplar and with labels" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_with_exemplars)

        lines = writer.write.split("\n")
        puts lines

        # this is hard to test
        red_created = counter_with_exemplars.values(with_exemplars: true)[{:umlauts=>"Björn", :utf=>"佖佥", :code=>"red"}].created
        expect(lines).to include("counter_with_exemplars_created{umlauts=\"Björn\",utf=\"佖佥\",code=\"red\"} #{red_created}")
        blue_created = counter_with_exemplars.values(with_exemplars: true)[{:umlauts=>"Björn", :utf=>"佖佥", :code=>"blue"}].created
        expect(lines).to include("counter_with_exemplars_created{umlauts=\"Björn\",utf=\"佖佥\",code=\"blue\"} #{blue_created}")
      end
    end

    describe "gauge" do
      let :gauge_with_exemplar do
        bar = registry.gauge(:gauge_with_exemplar,
                             docstring: "bar description\nwith newline",
                             labels: [:status, :code])
        bar.set(15, labels: { status: 'success', code: 'pink'}, exemplar: Prometheus::Client::Exemplar.new(labels: {trace_id: 23456}, timestamp: 2000))
        bar.set(17, labels: { status: 'success', code: 'pink'})

        bar
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(gauge_with_exemplar)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE gauge_with_exemplar gauge")
        # expect(lines).to include("# UNIT gauge_with_exemplar hotdogs")
        expect(lines).to include("# HELP gauge_with_exemplar bar description\\nwith newline")
      end

      it "generates a metric without a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(gauge_with_exemplar)

        lines = writer.write.split("\n")

        expect(lines).to include("gauge_with_exemplar{status=\"success\",code=\"pink\"} 17.0 # {trace_id=\"23456\"} 15.0 2000")
      end
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
        # expect(lines).to include("# UNIT histogram_without_ts hotdogs")
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

      it "generates a metric with at least one bucket, sum, created, and count metric points"
      it "generates a bucket with a +Inf threshold that counts all values"
      it "generates cumulative buckets, a low value increments the count in all buckets with higher values"
      it "generates a sum that equals the sum of all measured event values"
      it "if there is a negative valued bucket, there should be no sum metric"
      it "is not clear if we should print the bucket multiple times with different timestamps to expose multiple exemplars"
      it "Bucket values MAY have exemplars.  It is up to us on which bucket gets which exemplar other than the exemplar falling within the bucket range.  Docs say exemplars SHOULD be put into the bucket with the highest value."
    end

    describe "summary" do
      let(:summary_metric) do
        summary_metric = registry.summary(:summary_metric,
                                          docstring: 'qux description',
                                          labels: [:for, :code],
                                          preset_labels: { for: 'sake', code: '1' })
        92.times { summary_metric.observe(0) }
        summary_metric.observe(1243.21)

        summary_metric
      end

      it "generates a metric description" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(summary_metric)

        lines = writer.write.split("\n")

        expect(lines).to include("# TYPE summary_metric summary")
        expect(lines).to include("# HELP summary_metric qux description")
      end

      it "generates a metric" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(summary_metric)

        lines = writer.write.split("\n")

        expect(lines).to include("summary_metric_sum{for=\"sake\",code=\"1\"} 1243.21")
        expect(lines).to include("summary_metric_count{for=\"sake\",code=\"1\"} 93.0")
      end

      it "generates a metric with an exemplar"
      it "generates _created metric point"
    end

    # we don't support these types right now so I am punting for now

    # describe "gaugehistogram" do
    #   it "generates a metric description"
    #   it "generates a metric without a timestamp"
    #   it "generates a metric with a timestamp"
    #   it "generates a metric with an exemplar"
    # end

    # describe "stateset" do
    #   it "generates a metric description"
    #   it "generates a metric without a timestamp"
    #   it "generates a metric with a timestamp"
    #   it "generates a metric with an exemplar"
    #
    #   it "A point of a StateSet metric MAY contain multiple states and MUST contain one boolean per State. States have a name which are Strings."
    #   it "A StateSet Metric's LabelSet MUST NOT have a label name which is the same as the name of its MetricFamily."
    #   it "If encoded as a StateSet, ENUMs MUST have exactly one Boolean which is true within a MetricPoint."
    #   it "MetricFamilies of type StateSets MUST have an empty Unit string."
    # end

    # describe "info" do
    #   it "generates a metric description"
    #   it "generates a metric without a timestamp"
    #   it "generates a metric with a timestamp"
    #   it "generates a metric with an exemplar"
    #
    #   it "A MetricPoint of an Info Metric contains a LabelSet. An Info MetricPoint's LabelSet MUST NOT have a label name which is the same as the name of a label of the LabelSet of its Metric."
    #   it "Info MAY be used to encode ENUMs whose values do not change over time, such as the type of a network interface."
    #   it "MetricFamilies of type Info MUST have an empty Unit string."
    # end

    # describe "unknown" do
    #   it "generates a metric description"
    #   it "generates a metric without a timestamp"
    #   it "generates a metric with a timestamp"
    #   it "generates a metric with an exemplar"
    # end
  end
end
