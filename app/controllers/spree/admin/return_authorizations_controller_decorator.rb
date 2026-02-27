module Spree
  module Admin
    module ReturnAuthorizationsControllerDecorator
      private

      def load_return_items
        if @return_authorization.customer_returned_items?
          @form_return_items = @return_authorization.return_items.sort_by(&:inventory_unit_id)
        else
          super
        end
      end
    end
  end

  Spree::Admin::Orders::ReturnAuthorizationsController.prepend(Admin::ReturnAuthorizationsControllerDecorator)
end
