require_relative 'spec_helper'
require_relative 'shipment_builder'
require 'ostruct'

describe ShipmentBuilder do

  before { Object.send(:const_set, :Shipment, ShipmentDouble) }
  after { Object.send(:remove_const, :Shipment) }

  it "executes when consoildate is false" do
    assert ShipmentBuilder.new([order_line_item_double])
  end

  it "executes when consoildate is true" do
    assert ShipmentBuilder.new([order_line_item_double], true)
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
