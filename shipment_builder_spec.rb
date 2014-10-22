require_relative 'spec_helper'
require_relative 'shipment_builder'
require 'ostruct'

describe ShipmentBuilder do

  before { Object.send(:const_set, :Shipment, ShipmentDouble) }
  after { Object.send(:remove_const, :Shipment) }

  it "returns a single in_stock shipment" do
    shipments = ShipmentBuilder.new([order_line_item_double, order_line_item_double]).build_shipments
    shipments.length.must_equal 1
    shipments.first.shipment_type.must_equal :in_stock
  end

  it "returns a single consolidated shipment when consolidate is true" do
    shipments = ShipmentBuilder.new([order_line_item_double, order_line_item_double], true).build_shipments
    shipments.length.must_equal 1
    shipments.first.shipment_type.must_equal :consolidated
  end

end

def order_line_item_double
  OpenStruct.new(:item_id => 1, :store_id => 1, :vendor_id => 1, :drop_shippable? => true,
                 :ship_status_symbol => :in_stock)
end

class ShipmentDouble < OpenStruct
  def initialize(*)
    super
    self.line_items = []
  end
end
