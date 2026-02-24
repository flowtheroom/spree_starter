module Spree
  module CheckPaymentDecorator
    def generate_authorization_code(originator)
      if originator.try(:id)
        identifier = "#{originator.class.name.demodulize.upcase}-#{originator.id}"
      else
        identifier = "AUTH-#{Time.now.utc.strftime('%Y%m%d%H%M%S%6N')}"
      end

      "CHECK-#{identifier}"
    end

    def credit(amount_in_cents, auth_code, gateway_options = {})
      authorization_code = auth_code.presence || generate_authorization_code(gateway_options&.dig(:originator))
      ActiveMerchant::Billing::Response.new(true, '', {}, authorization: authorization_code)
    end
  end

  Spree::PaymentMethod::Check.prepend(CheckPaymentDecorator)
end
