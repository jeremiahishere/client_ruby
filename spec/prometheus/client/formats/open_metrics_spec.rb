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

  it "If a unit is specified it MUST be provided in a UNIT metadata line. In addition, an underscore and the unit MUST be the suffix of the MetricFamily name."
  it "If more than one MetricPoint is exposed for a Metric, the ordering should be by label permutation, then by oldest to newest timestamp"
    # for example
    # # TYPE foo_seconds summary
    # # UNIT foo_seconds seconds
    # foo_seconds_count{a="bb"} 0 123
    # foo_seconds_sum{a="bb"} 0 123
    # foo_seconds_count{a="bb"} 0 456
    # foo_seconds_sum{a="bb"} 0 456
    # foo_seconds_count{a="ccc"} 0 123
    # foo_seconds_sum{a="ccc"} 0 123
    # foo_seconds_count{a="ccc"} 0 456
    # foo_seconds_sum{a="ccc"} 0 456

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
                               labels: [:umlauts, :utf, :code, :_timestamp],
                               preset_labels: {umlauts: 'Björn', utf: '佖佥'})
        counter_with_ts.increment(labels: { code: 'red', _timestamp: 1000000}, by: 42)
        counter_with_ts.increment(labels: { code: 'red', _timestamp: 1000000}, by: 1)
        counter_with_ts.increment(labels: { code: 'blue', _timestamp: 1000001}, by: 1.23e-45)

        counter_with_ts
      end

      it "generates a metric with a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(counter_with_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("counter_with_ts{umlauts=\"Björn\",utf=\"佖佥\",code=\"red\"} 43.0 1000000")
        expect(lines).to include("counter_with_ts{umlauts=\"Björn\",utf=\"佖佥\",code=\"blue\"} 1.23e-45 1000001")
      end

      it "A MetricPoint in a Metric with the type Counter MUST have one value called Total. A Total is a non-NaN and MUST be monotonically non-decreasing over time, starting from 0."
      it "A MetricPoint in a Metric with the type Counter SHOULD have a Timestamp value called Created. This can help ingestors discern between new metrics and long-running ones it did not see before.  Created does not have a value except the timestamp."

      it "A MetricPoint in a Metric's Counter's Total MAY reset to 0. If present, the corresponding Created time MUST also be set to the timestamp of the reset."
      it "A MetricPoint in a Metric's Counter's Total MAY have an exemplar."

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
        expect(lines).to include("# HELP gauge_without_ts bar description\\nwith newline")
      end

      it "generates a metric without a timestamp" do
        writer = Prometheus::Client::Formats::OpenMetrics::Writer.new(gauge_without_ts)

        lines = writer.write.split("\n")

        expect(lines).to include("gauge_without_ts{status=\"success\",code=\"pink\"} 15.0")
      end

      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
      
      it "A MetricPoint in a Metric with the type gauge MUST have a single value.  I am pretty sure this means a single metric per label permutation per gauge but not 100% (JH)"
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

      it "A Histogram MetricPoint MUST contain at least one bucket, and SHOULD contain Sum, and Created values. Every bucket MUST have a threshold and a value."
      it "Histogram MetricPoints MUST have one bucket with an +Inf threshold."
      it "Buckets MUST be cumulative. As an example for a metric representing request latency in seconds its values for buckets with thresholds 1, 2, 3, and +Inf MUST follow value_1 <= value_2 <= value_3 <= value_+Inf. If ten requests took 1 second each, the values of the 1, 2, 3, and +Inf buckets MUST equal 10."
      it "The +Inf bucket counts all requests. If present, the Sum value MUST equal the Sum of all the measured event values. Bucket thresholds within a MetricPoint MUST be unique."
      it "Semantically, Sum, and buckets values are counters so MUST NOT be NaN or negative. Negative threshold buckets MAY be used, but then the Histogram MetricPoint MUST NOT contain a sum value as it would no longer be a counter semantically. Bucket thresholds MUST NOT equal NaN. Count and bucket values MUST be integers."
      it "A Histogram MetricPoint SHOULD have a Timestamp value called Created. This can help ingestors discern between new metrics and long-running ones it did not see before."
      it "A Histogram's Metric's LabelSet MUST NOT have a 'le' label name."
      it "Bucket values MAY have exemplars. Buckets are cumulative to allow monitoring systems to drop any non-+Inf bucket for performance/anti-denial-of-service reasons in a way that loses granularity but is still a valid Histogram."
      it "Each bucket covers the values less and or equal to it, and the value of the exemplar MUST be within this range. Exemplars SHOULD be put into the bucket with the highest value. A bucket MUST NOT have more than one exemplar."
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

      it "A point of a StateSet metric MAY contain multiple states and MUST contain one boolean per State. States have a name which are Strings."
      it "A StateSet Metric's LabelSet MUST NOT have a label name which is the same as the name of its MetricFamily."
      it "If encoded as a StateSet, ENUMs MUST have exactly one Boolean which is true within a MetricPoint."
      it "MetricFamilies of type StateSets MUST have an empty Unit string."
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

      it "A MetricPoint of an Info Metric contains a LabelSet. An Info MetricPoint's LabelSet MUST NOT have a label name which is the same as the name of a label of the LabelSet of its Metric."
      it "Info MAY be used to encode ENUMs whose values do not change over time, such as the type of a network interface."
      it "MetricFamilies of type Info MUST have an empty Unit string."
    end

    describe "unknown" do
      it "generates a metric description"
      it "generates a metric without a timestamp"
      it "generates a metric with a timestamp"
      it "generates a metric with an exemplar"
    end
  end
end
