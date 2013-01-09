require 'six_payment'
class PaymentNotificationsController < ApplicationController
  def notify
    logger.debug "Entered."
  	SixPayment::processPaymentNotification (request)
    logger.debug "Leaving."
  end
end
