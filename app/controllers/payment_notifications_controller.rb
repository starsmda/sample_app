class PaymentNotificationsController < ApplicationController
  def notify
  	# TODO: complete.
  	logger.debug("[DLS] #{__FILE__} Notify invoked!")
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.params: " + request.params.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.url:" + request.url.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.headers:" + request.headers.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.method:" + request.method.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.request_method:" + request.request_method.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.remote_ip:" + request.remote_ip.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.request_parameters:" + request.request_parameters.to_s)
  	logger.debug("[DLS] #{__FILE__} Notify invoked with following request.xml_http_request?:" + (request.xml_http_request? ? "true" : "false"))
  end
end
