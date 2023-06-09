# encoding: UTF-8

require 'prometheus/client/exemplar'
require 'prometheus/client/exemplar_collection'

describe Prometheus::Client::ExemplarCollection do
  describe "add" do
    it "adds an exemplar" do
      collection = described_class.new

      exemplar = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"}, timestamp: 1)
      collection.add(exemplar)

      expect(collection.first).to eq(exemplar)
    end

    it "cleans up if necessary" do
      collection = described_class.new

      120.times do |index|
        exemplar = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"}, timestamp: index)
        collection.add(exemplar)
      end

      expect(collection.size).to eq(120)

      exemplar = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"}, timestamp: 1000)
      collection.add(exemplar)

      expect(collection.size).to eq(120)
      expect(collection.most_recent.timestamp).to eq(1000)
    end
  end

  describe "most_recent" do
    it "returns the most recent exemplar by timestamp" do
      collection = described_class.new

      exemplar_1 = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"}, timestamp: 10)
      collection.add(exemplar_1)

      exemplar_2 = Prometheus::Client::Exemplar.new(labels: {hotdogs: "bad"}, timestamp: 5)
      collection.add(exemplar_2)

      expect(collection.most_recent).to eq(exemplar_1)
    end

    it "returns the most recently written exemplar if there is a timestamp tie" do
      collection = described_class.new

      exemplar_1 = Prometheus::Client::Exemplar.new(labels: {hotdogs: "great"}, timestamp: 1)
      collection.add(exemplar_1)

      exemplar_2 = Prometheus::Client::Exemplar.new(labels: {hotdogs: "bad"}, timestamp: 1)
      collection.add(exemplar_2)

      expect(collection.most_recent).to eq(exemplar_2)
    end
  end
end
