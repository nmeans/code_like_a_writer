require_relative 'spec_helper'
require_relative 'shipment_builder'
require_relative 'mock_order_line_item'
require 'ostruct'

describe ShipmentBuilder do

  it "returns a single consolidated shipment when consolidate is true" do
    shipments = ShipmentBuilder.new.build_shipments([mock_order_line_item, mock_order_line_item], true)
    shipments.length.must_equal 1
  end

end

def mock_order_line_item(ship_status = :in_stock, store_id = 1)
  MockOrderLineItem.new(ship_status: ship_status, store_id: store_id)
end
