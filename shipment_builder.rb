class ShipmentBuilder
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Determine the groups in which items will be shipped. This is necessary for
  # non-consolidated shipments when some items are out of stock or are being
  # drop-shipped from a vendors warehouse.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  attr_reader :line_items, :consolidate, :shipments

  def initialize(line_items, consolidate = false)
    @line_items = line_items
    @consolidate = consolidate
    @shipments = []
  end

  def build_shipments
    unless consolidate
      build_shipments_by_ship_status
    else
      build_consolidated_shipment
    end

    return shipments
  end

  def build_consolidated_shipment
    line_items.each do |line_item|
      create_group_if_necessary_and_insert( shipments, :consolidated, line_item.store_id, line_item.store_id, line_item)
    end
  end

  def build_shipments_by_ship_status
    # MAGIC GOES HERE TO DO THE CONSOLIDATION

    if in_stock_items.length > 0 && drop_ship_items.length > 0
      # If we've got us some in_stocks and some drop_ships, let's see if
      # we can do some consolidating. It only makes sense to consolidate if we can completely
      # get rid of in_stocks.
      if consolidate_to_drop_ships?
        in_stock_items.each{|li| li.ship_status = :drop_ship}
      end
    end

    line_items.each do |li|
      create_group_if_necessary_and_insert( shipments, li.ship_status, li.store_id,
                                            li.ship_status == :drop_ship ? li.vendor_id : li.store_id, li.line_item )
    end
  end

  def consolidate_to_drop_ships?
    in_stock_items.each do |in_stock_item|
      matching_ds = drop_ship_items.any?{|drop_ship_item| drop_ship_item.vendor_id == in_stock_item.vendor_id}
      in_stock_item.consolidatable = (matching_ds && in_stock_item.drop_shippable)
    end
    in_stock_items.all?(&:consolidatable)
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

  def create_group_if_necessary_and_insert( shipments, key, store_id, shipper_id, order_line_item)
    found = false
    shipments.each do |shipment|
      if shipment.shipment_type == key && shipment.shipper_id == shipper_id && shipment.store_id == store_id
        shipment.line_items << order_line_item
        found = true
      end
    end
    if found == false
      shipment = Shipment.new
      shipment.shipment_type = key
      shipment.shipper_id = shipper_id
      shipment.store_id = store_id
      shipment.line_items << order_line_item
      shipments << shipment
    end
  end
end
