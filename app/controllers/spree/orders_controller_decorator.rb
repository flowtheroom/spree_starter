module Spree
  module OrdersControllerDecorator
    def create_payment
      result = Spree::Payments::Create.call(order: resource, params: params)
      if result.success?
        render_serialized_payload(201) { serialize_resource(resource.reload) }
      else
        render_error_payload(result.error)
      end
    end
  end

  Spree::Api::V2::Platform::OrdersController.prepend(OrdersControllerDecorator)
end
