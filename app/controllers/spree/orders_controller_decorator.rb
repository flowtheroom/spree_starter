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

    def return_order
      associated_inventory_units = resource.return_items.not_cancelled.pluck(:inventory_unit_id)
      unassociated_inventory_units = resource.inventory_units.shipped.where.not(id: associated_inventory_units)

      if unassociated_inventory_units.empty?
        render_error_payload(Spree.t('return_item_inventory_unit_reimbursed'))
      else
        results = { success: [], failure: [] }

        inventory_units_by_location = unassociated_inventory_units.group_by { |unit| unit.shipment.stock_location_id }
        inventory_units_by_location.each do |stock_location_id, inventory_units|
          result = return_inventory(
            order: resource,
            stock_location_id: stock_location_id,
            inventory_units: inventory_units,
            return_authorization_reason_id: params[:return_authorization_reason_id]
          )
          if result[:error]
            results[:failure] << result
          else
            results[:success] << result
          end
        end
        render json: results, status: 200
      end
    end

    private

    def return_inventory(order:, stock_location_id:, inventory_units:, return_authorization_reason_id:)
      Rails.logger.info "\e[33m===== RETURN TO #{stock_location_id} (##{inventory_units.count}) =====\e[0m"

      Spree::ReturnAuthorization.transaction do
        return_items = inventory_units.map { |unit| Spree::ReturnItem.from_inventory_unit(unit) }
        Rails.logger.info "\e[33m✓ Spree::ReturnItem\e[0m"

        return_authorization = Spree::ReturnAuthorization.create!(
          order: order,
          return_items: return_items,
          stock_location_id: stock_location_id,
          return_authorization_reason_id: return_authorization_reason_id
        )
        Rails.logger.info "\e[33m✓ Spree::ReturnAuthorization\e[0m"
      
        customer_return = Spree::CustomerReturn.create!(
          store_id: order.store_id,
          stock_location_id: stock_location_id,
          return_items: return_authorization.return_items
        )
        Rails.logger.info "\e[33m✓ Spree::CustomerReturn\e[0m"
      
        reimbursement = Spree::Reimbursement.build_from_customer_return(customer_return)
        reimbursement.save!
        Rails.logger.info "\e[33m✓ Spree::Reimbursement\e[0m"
      
        reimbursement.perform!
        Rails.logger.info "\e[33m>>> Refunded Successfully\e[0m"
        return { stock_location_id: stock_location_id, return_authorization_id: return_authorization.id, reimbursement: reimbursement.id }
      end
      
    rescue StandardError => e
      Rails.logger.error "Failed to return order #{order.id} to stock location #{stock_location_id}: #{e.message}"
      return { stock_location_id: stock_location_id, error: e.message }
    end
  end

  Spree::Api::V2::Platform::OrdersController.prepend(OrdersControllerDecorator)
end
