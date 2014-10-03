require 'virtus'

class Shipment
  include Virtus.model
  attribute :shipment_type, Symbol
  attribute :shipper_id, Integer
  attribute :store_id, Integer
  attribute :line_items, Array
end
