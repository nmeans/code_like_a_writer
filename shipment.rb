class Shipment
  attr_accessor :shipment_type, :shipper_id, :store_id, :line_items

  def initialize
    @line_items = []
  end
end
