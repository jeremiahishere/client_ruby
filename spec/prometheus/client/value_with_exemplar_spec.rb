# encoding: UTF-8

require 'prometheus/client/exemplar'
require 'prometheus/client/exemplar_collection'

describe Prometheus::Client::ValueWithExemplars do
  describe "set" do
    it "updates the value as a float" do
      vwe = described_class.new

      vwe.set(value: 5)

      expect(vwe.value).to eq(5.0)
    end

    it "stores an exemplar and updates its value" do
      vwe = described_class.new

      exemplar = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"})
      vwe.set(value: 5, exemplar: exemplar)

      expect(vwe.most_recent_exemplar.value).to eq(5.0)
    end
  end

  describe "increment" do
    it "updates the value as a float" do
      vwe = described_class.new

      vwe.set(value: 5)
      exemplar = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"})
      vwe.increment(by: 7, exemplar: exemplar)

      expect(vwe.value).to eq(12.0)
      expect(vwe.most_recent_exemplar.value).to eq(12.0)
    end
  end

  describe "most_recent_exemplar" do
    it "returns the most recent exemplar by timestamp" do
      vwe = described_class.new

      vwe.set(value: 5)
      exemplar = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"})
      vwe.increment(by: 7, exemplar: exemplar)
      vwe.increment(by: 3)

      expect(vwe.value).to eq(15.0)
      expect(vwe.most_recent_exemplar.value).to eq(12.0)
    end
  end
end
