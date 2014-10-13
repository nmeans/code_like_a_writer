require_relative 'shipment'

class ShipmentBuilder
  attr_reader :line_items, :consolidate_to_single_shipment

  def initialize(line_items, consolidate_to_single_shipment = false)
    @line_items = line_items
    @consolidate_to_single_shipment = consolidate_to_single_shipment
  end

  def build_shipments
    optimize_ship_statuses
    assign_items_to_shipments
    return shipments
  end

  def assign_items_to_shipments
    line_items.each { |li| shipment_list.assign_to_shipment(li) }
  end

  def optimize_ship_statuses
    if consolidate_to_single_shipment
      line_items.each{|li| li.ship_status = :consolidated}
    end

    if consolidate_all_in_stock_to_drop_ship?
      in_stock_items.each{|li| li.ship_status = :drop_ship}
    end
  end

  [:in_stock, :drop_ship, :order_in].each do |stock_status|
    define_method "#{stock_status}_items" do                 # def in_stock_items
      line_items.select{|li| li.ship_status == stock_status} #   line_items.select{|li| li.ship_status == :in_stock}
    end                                                      # end
  end

  def consolidate_all_in_stock_to_drop_ship?
    return false unless in_stock_items.all?(&:drop_shippable)
    (in_stock_items.map(&:vendor_id) - drop_ship_items.map(&:vendor_id)).empty?
  end

  def shipment_list
    @shipment_list ||= ShipmentList.new
  end

  def shipments
    shipment_list.shipments
  end

  class ShipmentList
    attr_reader :shipments

    def initialize
      @shipments = []
    end

    def assign_to_shipment(line_item)
      shipment = find_or_create_shipment(line_item.ship_status, line_item.vendor_id)
      shipment.line_items << line_item
    end

    def find_or_create_shipment(type, shipper_id)
      find_shipment(type, shipper_id) || create_shipment(type, shipper_id)
    end

    def find_shipment(type, shipper_id)
      shipments.find do |shipment|
        shipment.shipment_type == type && (shipment.shipper_id == shipper_id || shipment.shipment_type != :drop_ship)
      end
    end

    def create_shipment(type, shipper_id)
      shipments << new_shipment = Shipment.new(shipment_type: type, shipper_id: shipper_id, store_id: 1)
      new_shipment
    end

  end
end
