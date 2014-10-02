require_relative 'spec_helper'
require_relative 'shipment_builder'
require_relative 'mock_order_line_item'
require 'ostruct'

describe ShipmentBuilder do

  it "returns a single consolidated shipment when consolidate is true" do
    shipments = ShipmentBuilder.new.build_shipments([mock_order_line_item, mock_order_line_item], true)
    shipments.length.must_equal 1
  end

  it "returns a single in_stock shipment" do
    shipments = ShipmentBuilder.new.build_shipments([mock_order_line_item(:in_stock), mock_order_line_item(:in_stock)])
    shipments.length.must_equal 1
    shipments.first.shipment_type.must_equal :in_stock
  end

end

def mock_order_line_item(ship_status = :in_stock, store_id = 1)
  MockOrderLineItem.new(ship_status: ship_status, store_id: store_id)
end
