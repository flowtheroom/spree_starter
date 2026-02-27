module Spree
  module PaymentsControllerDecorator
    def confirm_payment
      if resource.order.payment_total < resource.order.total
        resource.confirm!

        resource.order.updater.update_payment_state
        resource.order.save!
      end
      render_serialized_payload(200) { serialize_resource(resource.reload) }
    end
  end

  Spree::Api::V2::Platform::PaymentsController.prepend(PaymentsControllerDecorator)
end
