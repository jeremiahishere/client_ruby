# encoding: UTF-8

require 'prometheus/client'
require 'prometheus/client/summary'
require 'examples/metric_example'

describe Prometheus::Client::Summary do
  # Reset the data store
  before do
    Prometheus::Client.config.data_store = Prometheus::Client::DataStores::Synchronized.new
  end

  let(:expected_labels) { [] }

  let(:summary) do
    Prometheus::Client::Summary.new(:bar,
                                    docstring: 'bar description',
                                    labels: expected_labels)
  end

  it_behaves_like Prometheus::Client::Metric

  describe '#initialization' do
    it 'raise error for `quantile` label' do
      expect do
        described_class.new(:bar, docstring: 'bar description', labels: [:quantile])
      end.to raise_error Prometheus::Client::LabelSetValidator::ReservedLabelError
    end
  end

  describe '#observe' do
    it 'records the given value' do
      expect do
        summary.observe(5)
      end.to change { summary.get }.
        from({ "count" => 0.0, "sum" => 0.0 }).
        to({ "count" => 1.0, "sum" => 5.0 })
    end

    it 'raise error for quantile labels' do
      expect do
        summary.observe(5, labels: { quantile: 1 })
      end.to raise_error Prometheus::Client::LabelSetValidator::InvalidLabelSetError
    end

    context "with a an expected label set" do
      let(:expected_labels) { [:test] }

      it 'observes a value for a given label set' do
        expect do
          expect do
            summary.observe(5, labels: { test: 'value' })
          end.to change { summary.get(labels: { test: 'value' })["count"] }
        end.to_not change { summary.get(labels: { test: 'other' })["count"] }
      end
    end
  end

  describe '#get' do
    let(:expected_labels) { [:foo] }

    before do
      summary.observe(3, labels: { foo: 'bar' })
      summary.observe(5.2, labels: { foo: 'bar' })
      summary.observe(13, labels: { foo: 'bar' })
      summary.observe(4, labels: { foo: 'bar' })
    end

    it 'returns a value which responds to #sum and #total' do
      expect(summary.get(labels: { foo: 'bar' })).
        to eql({ "count" => 4.0, "sum" => 25.2 })
    end
  end

  describe '#values' do
    let(:expected_labels) { [:status] }

    it 'returns a hash of all recorded summaries' do
      summary.observe(3, labels: { status: 'bar' })
      summary.observe(5, labels: { status: 'foo' })

      expect(summary.values[{ status: 'bar' }].value).to eql({ "count" => 1.0, "sum" => 3.0 })
      expect(summary.values[{ status: 'foo' }].value).to eql({ "count" => 1.0, "sum" => 5.0 })
    end
  end

  describe '#init_label_set' do
    context "with labels" do
      let(:expected_labels) { [:status] }

      it 'initializes the metric for a given label set' do
        expect(summary.values).to eql({})

        summary.init_label_set(status: 'bar')
        summary.init_label_set(status: 'foo')

        expect(summary.values[{ status: 'bar' }].value).to eql({ "count" => 0.0, "sum" => 0.0 })
        expect(summary.values[{ status: 'foo' }].value).to eql({ "count" => 0.0, "sum" => 0.0 })
      end
    end

    context "without labels" do
      it 'automatically initializes the metric' do
        expect(summary.values[{}].value).to eql({ "count" => 0.0, "sum" => 0.0 })
      end
    end
  end
end
