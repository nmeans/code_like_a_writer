require_relative 'shipment'

class ShipmentBuilder
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Determine the groups in which items will be shipped. This is necessary for
  # non-consolidated shipments when some items are out of stock or are being
  # drop-shipped from a vendors warehouse.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def build_shipments( order_line_items, consolidate = false)
    shipments = []

    unless consolidate
      # Build a hash of line items with associated data we can use without having to re-query the database for all the iterations.
      line_items = []
      order_line_items.each do |order_line_item|
        line_items << OpenStruct.new( :ship_status_symbol => order_line_item.ship_status,
                                      :store_id => order_line_item.store_id,
                                      :vendor_id => order_line_item.vendor_id,
                                      :line_item => order_line_item,
                                      :drop_shippable => order_line_item.drop_shippable? )
      end


      # MAGIC GOES HERE TO DO THE CONSOLIDATION
      line_items_by_sym = {}
      [:in_stock,:drop_ship,:order_in].each do |ship_sym|
        line_items_by_sym[ship_sym] = line_items.select{|li| li.ship_status_symbol == ship_sym}
      end

      if line_items_by_sym[:in_stock].length > 0 && line_items_by_sym[:drop_ship].length > 0
        # If we've got us some in_stocks and some drop_ships, let's see if
        # we can do some consolidating. It only makes sense to consolidate if we can completely
        # get rid of in_stocks.
        line_items_by_sym[:in_stock].each do |li|
          matching_ds = line_items_by_sym[:drop_ship].count{|dsli| dsli.vendor_id == li.vendor_id} > 0
          li.consolidatable = (matching_ds && li.drop_shippable)
        end
        if line_items_by_sym[:in_stock].count{|li| !li.consolidatable} < 1
          #Woo-hoo! Let's consolidate
          line_items.each{|li| li.ship_status_symbol = :drop_ship if li.ship_status_symbol == :in_stock}
        end

      end

      line_items.each do |li|
        create_group_if_necessary_and_insert( shipments, li.ship_status_symbol, li.store_id,
                                              li.ship_status_symbol == :drop_ship ? li.vendor_id : li.store_id, li.line_item )
      end
    else
      order_line_items.each do |order_line_item|
        create_group_if_necessary_and_insert( shipments, :consolidated, order_line_item.store_id, order_line_item.store_id, order_line_item)
      end
    end

    return shipments
  end

  def create_group_if_necessary_and_insert( shipments, key, store_id, shipper_id, order_line_item)
    found = false
    shipments.each do |shipment|
      if shipment.shipment_type == key && shipment.shipper_id == shipper_id
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
