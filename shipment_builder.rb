class ShipmentBuilder
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Determine the groups in which items will be shipped. This is necessary for
  # non-consolidated shipments when some items are out of stock or are being
  # drop-shipped from a vendors warehouse.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def build_shipments( order_line_items, consolidate=false )
    shipments = []

    unless consolidate
      # Build a hash of line items with associated data we can use without having to re-query the database for all the iterations.
      line_items = []
      order_line_items.each do |order_line_item|
        item = order_line_item.item_id ? Item.find(order_line_item.item_id, :include => :product) : UsedItem.find(order_line_item.used_item_id)
        RAILS_DEFAULT_LOGGER.info("Build shipments found item: #{item.inspect} from store #{item.store_id}")
        ship_status_symbol = item.shipping_status_symbol_for_quantity(order_line_item.quantity)
        ship_status_symbol = :in_stock if [:closeout_instock,:from_stock_only_instock].include?(ship_status_symbol)
        line_items << OpenStruct.new( :ship_status_symbol => ship_status_symbol,
                                      :store_id => item.instance_of?(Item) ? item.product.store_id : 1,
                                      :vendor_id => item.instance_of?(Item) ? item.product.vendor_id : nil,
                                      :line_item => order_line_item,
                                      :drop_shippable => item.drop_shippable?,
                                      :consolidatable => false)
      end


      # MAGIC GOES HERE TO DO THE CONSOLIDATION
      line_items_by_sym = {}
      [:in_stock,:drop_ship,:order_in].each do |ship_sym|
        line_items_by_sym[ship_sym] = line_items.select{|li| li.ship_status_symbol == ship_sym}
      end

      if line_items_by_sym[:in_stock].length > 0 && line_items_by_sym[:drop_ship].length > 0
        RAILS_DEFAULT_LOGGER.debug("Attempting to consolidate in_stocks and drop_ships.")
        # If we've got us some in_stocks and some drop_ships, let's see if
        # we can do some consolidating. It only makes sense to consolidate if we can completely
        # get rid of in_stocks.
        line_items_by_sym[:in_stock].each do |li|
          matching_ds = line_items_by_sym[:drop_ship].count{|dsli| dsli.vendor_id == li.vendor_id} > 0
          li.consolidatable = (matching_ds && li.drop_shippable)
        end
        if line_items_by_sym[:in_stock].count{|li| !li.consolidatable} < 1
          RAILS_DEFAULT_LOGGER.debug("Consolidating in_stocks and drop_ships.")
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
        item = order_line_item.item_id ? Item.find(order_line_item.item_id, :include => :product) : UsedItem.find(order_line_item.used_item_id)
        create_group_if_necessary_and_insert( shipments, :consolidated, item.store_id, item.store_id, order_line_item)
      end
    end

    set_consolidate_flags( shipments )

    RAILS_DEFAULT_LOGGER.info "====================================================="
    RAILS_DEFAULT_LOGGER.info "Shipments"
    RAILS_DEFAULT_LOGGER.info "====================================================="
    RAILS_DEFAULT_LOGGER.info "#{shipments.inspect}"
    RAILS_DEFAULT_LOGGER.info "====================================================="
    return shipments
  end

  def set_consolidate_flags( shipments )
    #RAILS_DEFAULT_LOGGER.debug shipments.to_yaml
    # Now let's set appropriate consolidate flags on the shipments that are to be shipped together (NEML & NEHP)
    in_stock = []
    order_in = []
    consol   = []
    shipments.each do |s|
      if s.shipment_type == Shipment::IN_STOCK
        in_stock << s
      elsif s.shipment_type == Shipment::ORDER_IN
        order_in << s
      elsif s.shipment_type == Shipment::CONSOLIDATED
        consol << s
      end
    end
    # NEMX_TODO - Make this more robust if we need to combine with NEMX in the future.
    groups = [in_stock, order_in, consol]
    groups.each do |g|
      #RAILS_DEFAULT_LOGGER.debug "================================================================"
      #RAILS_DEFAULT_LOGGER.debug "Group #{g.inspect}"
      #RAILS_DEFAULT_LOGGER.debug "================================================================"
      if g.length == 2
        # We can assume here that shipper_id == store_id always because a drop-ship from one store
        # will never be combined with a drop-ship from another store.  If shipment was drop-shipped
        # shipper_id == vendor_id.
        if g[1].shipper_id == 1
          g[0].combine_flag = "combine"
          g[1].combine_flag = "has_combined_shipment"
          g[1].combine_with_shipment = g[0]
        else
          g[1].combine_flag = "combine"
          g[0].combine_flag = "has_combined_shipment"
          g[0].combine_with_shipment = g[1]
        end
      end
    end
  end

  def create_group_if_necessary_and_insert( shipments, key, store_id, shipper_id, order_line_item)
    found = false
    shipments.each do |shipment|
      if shipment.shipment_type == shipment.shipment_type_from_symbol( key ) && shipment.shipper_id == shipper_id && shipment.store_id == store_id
        shipment.line_items << order_line_item
        found = true
      end
    end
    if found == false
      shipment = Shipment.new
      shipment.shipment_type = shipment.shipment_type_from_symbol( key )
      shipment.shipper_id = shipper_id
      shipment.store_id = store_id
      shipment.line_items << order_line_item
      shipments << shipment
    end
  end
end
