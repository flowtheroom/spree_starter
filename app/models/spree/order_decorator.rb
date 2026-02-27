module Spree
  module OrderDecorator
    def create_proposed_shipments
      if shipments.ready_or_pending.size > 0
        puts "Skipped Spree::Order.create_proposed_shipments"
      else
        super
      end
    end

    def order_refunded?
      return false if item_count.zero?

      (payment_state.in?(%w[void failed]) && refunds_total.positive?) ||
        refunds_total >= total_minus_store_credits
    end

    def partially_refunded?
      return false if item_count.zero?
      return false if payment_state.in?(%w[void failed]) || refunds.empty?

      refunds_total < total_minus_store_credits
    end
  end

  Spree::Order.prepend(OrderDecorator)
end
