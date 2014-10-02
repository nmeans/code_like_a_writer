require 'virtus'
class MockOrderLineItem
  include Virtus.model
  attribute :ship_status, Symbol
  attribute :store_id, Integer
  attribute :vendor_id, Integer
  attribute :drop_shippable, Boolean

  def drop_shippable?
    drop_shippable
  end

  alias_method :original_ship_status, :ship_status
  def ship_status
    return :in_stock if [:closeout_instock,:from_stock_only_instock].include?(original_ship_status)
    original_ship_status
  end
end
