module Spree
  module OrderDecorator
    def create_proposed_shipments
      if shipments.ready_or_pending.size > 0
        puts "Skipped Spree::Order.create_proposed_shipments"
      else
        super
      end
    end
  end

  Spree::Order.prepend(OrderDecorator)
end
