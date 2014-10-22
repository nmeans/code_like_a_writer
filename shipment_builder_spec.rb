require_relative 'spec_helper'
require_relative 'shipment_builder'
require 'ostruct'

describe ShipmentBuilder do

  before { Object.send(:const_set, :Shipment, ShipmentDouble) }
  after { Object.send(:remove_const, :Shipment) }

it "returns a single consolidated shipment when consolidate is true" do
    order_line_items = [
      order_line_item_double(ship_status_symbol: :in_stock),
      order_line_item_double(ship_status_symbol: :drop_ship),
      order_line_item_double(ship_status_symbol: :order_in),
    ]
    shipments = ShipmentBuilder.new(order_line_items, true).build_shipments
    shipments.length.must_equal 1
  end

  it "returns a single in_stock shipment" do
    shipments = ShipmentBuilder.new([order_line_item_double, order_line_item_double]).build_shipments
    shipments.length.must_equal 1
    shipments.first.shipment_type.must_equal :in_stock
  end

  it "returns multiple shipments when types and vendors differ" do
    order_line_items = [
      order_line_item_double(ship_status_symbol: :in_stock),
      order_line_item_double(ship_status_symbol: :drop_ship, vendor_id: 9),
      order_line_item_double(ship_status_symbol: :drop_ship, vendor_id: 10),
      order_line_item_double(ship_status_symbol: :order_in),
    ]
    shipments = ShipmentBuilder.new(order_line_items).build_shipments
    shipments.length.must_equal 4
    shipments.count{|s| s.shipment_type == :drop_ship}.must_equal 2
  end

  it "consolidates drop ship items from the same vendor" do
    order_line_items = [
      order_line_item_double(ship_status_symbol: :drop_ship, vendor_id: 9),
      order_line_item_double(ship_status_symbol: :drop_ship, vendor_id: 9),
    ]
    shipments = ShipmentBuilder.new(order_line_items).build_shipments
    shipments.length.must_equal 1
  end

  it "consolidates in_stock to drop_ship if all in_stock items can be consolidated" do
    order_line_items = [
      order_line_item_double(ship_status_symbol: :in_stock, vendor_id: 9),
      order_line_item_double(ship_status_symbol: :drop_ship, vendor_id: 9),
    ]
    shipments = ShipmentBuilder.new(order_line_items).build_shipments
    shipments.length.must_equal 1
    shipments.first.shipment_type.must_equal :drop_ship
  end

  it "does not consolidate in_stock to drop ship if any in_stock items are not consolidatable" do
    order_line_items = [
      order_line_item_double(ship_status_symbol: :in_stock, vendor_id: 9),
      order_line_item_double(ship_status_symbol: :drop_ship, vendor_id: 9),
      order_line_item_double(ship_status_symbol: :in_stock, vendor_id: 10),
    ]
    shipments = ShipmentBuilder.new(order_line_items).build_shipments
    shipments.length.must_equal 2
    shipments.find{|s| s.shipment_type == :drop_ship}.line_items.length.must_equal 1
  end

end

def order_line_item_double(overrides = {})
  line_item_params = { :item_id => 1, :store_id => 1, :vendor_id => 1, :drop_shippable? => true,
                       :ship_status_symbol => :in_stock }.merge(overrides)
  OpenStruct.new(line_item_params)
end

class ShipmentDouble < OpenStruct
  def initialize(*)
    super
    self.line_items = []
  end
end
