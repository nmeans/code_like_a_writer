require_relative 'spec_helper'
require_relative 'shipment_builder'
require_relative 'mock_order_line_item'
require 'ostruct'

describe ShipmentBuilder do

  it "returns a single consolidated shipment when consolidate is true" do
    order_line_items = [
      mock_order_line_item(ship_status: :in_stock),
      mock_order_line_item(ship_status: :drop_ship),
      mock_order_line_item(ship_status: :order_in),
    ]
    shipments = ShipmentBuilder.new.build_shipments(order_line_items, true)
    shipments.length.must_equal 1
  end

  it "returns a single in_stock shipment" do
    shipments = ShipmentBuilder.new.build_shipments([mock_order_line_item, mock_order_line_item])
    shipments.length.must_equal 1
    shipments.first.shipment_type.must_equal :in_stock
  end

end

def mock_order_line_item(overrides = {})
  params = {:ship_status => :in_stock, :store_id => 1, :vendor_id => 1, :drop_shippable => true}.merge(overrides)
  MockOrderLineItem.new(params)
end
