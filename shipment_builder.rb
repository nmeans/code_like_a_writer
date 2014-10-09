require_relative 'shipment'

class ShipmentBuilder
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Determine the groups in which items will be shipped. This is necessary for
  # non-consolidated shipments when some items are out of stock or are being
  # drop-shipped from a vendors warehouse.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  attr_reader :line_items, :consolidate_to_single_shipment, :shipments

  def initialize(line_items, consolidate_to_single_shipment = false)
    @line_items = line_items
    @consolidate_to_single_shipment = consolidate_to_single_shipment
    @shipments = []
  end

  def build_shipments
    if consolidate_to_single_shipment
      line_items.each{|li| li.ship_status = :consolidated}
    end

    if consolidate_all_in_stock_to_drop_ship?
      in_stock_items.each{|li| li.ship_status = :drop_ship}
    end

    line_items.each do |li|
      create_group_if_necessary_and_insert( shipments, li.ship_status, li.store_id,
                                            li.ship_status == :drop_ship ? li.vendor_id : li.store_id, li )
    end

    return shipments
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

  def create_group_if_necessary_and_insert( shipments, key, store_id, shipper_id, line_item)
    matching_shipment = find_shipment(key, shipper_id)
    if matching_shipment
      matching_shipment.line_items << line_item
    else
      shipment = create_shipment(key, shipper_id)
      shipment.line_items << line_item
    end
  end

  def find_shipment(type, shipper_id)
    shipments.find do |shipment|
      shipment.shipment_type == type && shipment.shipper_id == shipper_id
    end
  end

  def create_shipment(type, shipper_id)
    shipments << new_shipment = Shipment.new(shipment_type: type, shipper_id: shipper_id, store_id: 1)
    new_shipment
  end
end
