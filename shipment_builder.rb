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
      in_stock_items.each do |li|
        matching_ds = drop_ship_items.count{|dsli| dsli.vendor_id == li.vendor_id} > 0
        li.consolidatable = (matching_ds && li.drop_shippable)
      end
      if in_stock_items.count{|li| !li.consolidatable} < 1
        #Woo-hoo! Let's consolidate
        line_items.each{|li| li.ship_status = :drop_ship if li.ship_status == :in_stock}
      end
    end

    line_items.each do |li|
      create_group_if_necessary_and_insert( shipments, li.ship_status, li.store_id,
                                            li.ship_status == :drop_ship ? li.vendor_id : li.store_id, li.line_item )
    end
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
