require 'spec_helper'
require 'stock_service/event_buffer'

describe 'EventBuffer' do
  describe '#backpressure' do
    let(:event_buffer) do
      buf = EventBuffer.new
      buf.instance_variable_set(
        :@metric_registry,
        double('registry', meter: double('meter', mark: ''))
      )
      buf
    end

    context 'when back pressured' do
      it 'should increase the backoff duration' do
        expect(event_buffer.instance_variable_get(:@backoff_duration)).to eq 0
        event_buffer.backpressure(true)
        expect(event_buffer.instance_variable_get(:@backoff_duration)).to be > 0
      end
    end
  end
end
