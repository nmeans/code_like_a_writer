require 'virtus'
class MockOrderLineItem
  include Virtus.model
  attribute :ship_status, Symbol
  attribute :store_id, Integer
end
