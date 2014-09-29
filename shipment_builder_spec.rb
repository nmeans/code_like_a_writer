require_relative 'spec_helper'
require_relative 'shipment_builder'
require 'ostruct'

describe ShipmentBuilder do
  it "exists" do
    assert ShipmentBuilder.new(order_line_item)
  end
end

def order_line_item
  OpenStruct.new(:item_id => 1)
end
