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
end
