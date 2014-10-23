class ShipmentBuilder
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Determine the groups in which items will be shipped. This is necessary for
  # non-consolidated shipments when some items are out of stock or are being
  # drop-shipped from a vendors warehouse.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  attr_reader :line_items, :single_shipment, :shipments, :shipment_list

  def initialize(line_items, single_shipment = false)
    @line_items = line_items
    @single_shipment = single_shipment
    @shipments = []
    @shipment_list = ShipmentList.new(shipments)
  end

  def build_shipments
    optimize_consolidation
    assign_items_to_shipments

    return shipments
  end

  def optimize_consolidation
    consolidate_to_single_shipment if single_shipment
    consolidate_to_drop_ships if consolidate_to_drop_ships?
  end

  def consolidate_to_single_shipment
    line_items.each { |li| li.ship_status = :consolidated }
  end

  def consolidate_to_drop_ships
    in_stock_items.each{|li| li.ship_status = :drop_ship}
  end

  def consolidate_to_drop_ships?
    return false unless in_stock_items.all?(&:drop_shippable)
    (in_stock_items.map(&:vendor_id) - drop_ship_items.map(&:vendor_id)).empty?
  end

  def in_stock_items
    line_items_by_ship_status(:in_stock)
  end

  def drop_ship_items
    line_items_by_ship_status(:drop_ship)
  end

  def line_items_by_ship_status(status)
    line_items.select{|li| li.ship_status == status}
  end

  def assign_items_to_shipments
    line_items.each{|li| shipment_list.assign_to_shipment(li)}
  end

  class ShipmentList
    attr_accessor :shipments

    def initialize(shipments)
      @shipments = shipments
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
