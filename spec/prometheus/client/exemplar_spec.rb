# encoding: UTF-8

require 'prometheus/client/exemplar'

describe Prometheus::Client::Exemplar do
  it "sets default labels" do
    e = described_class.new

    expect(e.labels).to eq({})
  end

  it "sets a default timestamp" do
    e = described_class.new

    expect(e.timestamp).to be <= Time.now.to_i
  end
end
