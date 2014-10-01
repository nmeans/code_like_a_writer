require_relative 'spec_helper'
require_relative 'shipment_builder'
require 'ostruct'

describe ShipmentBuilder do

  it "returns a single consolidated shipment when consolidate is true" do
    sb = ShipmentBuilder.new([mock_order_line_item, mock_order_line_item], true)
    sb.length.must_equal 1
  end

end

def mock_order_line_item
  OpenStruct.new()
end
