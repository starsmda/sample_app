# 
# Helper module/class for taking credit card payments via the SIX saferpay 
#  payment service.
# See www.saferpay.con
# 
# This module uses the http interface to Saferpay to keep it light weight 
#  and free from .NET or java libraries.
#
# The module utilises a helper class as suggested by Iain Hecker 
#  on iain.nl/helpers-are-code-too
#
# ToDo List
# 1. It should be implemented as a gem once my ruby skills are up to it.
#
#
require 'net/https'
require 'rexml/document'

class SixPayment
  attr_accessor :accountId,
                :amount,
                :currency,
                :description,
                :orderId,
                :vtConfig,
                :successLink,
                :failLink,
                :backLink,
                :notifyURL,
                :autoClose,
                :notifyAddress,
                :userNotify,
                :langId,
                :showLanguages,
                :cardRefId,
                :delivery

  #############################################
  #
  # Class Constants
  #
  #############################################
  #
  # Define Saferpay webservice API URLs
  #
  # Generation of a payment link:
  CreatePayInitAPI=Settings.SixPayment.HttpsAPI.CreatePayInitAPI
  # Verifying an authorization response:
  VerifyPayConfirmAPI=Settings.SixPayment.HttpsAPI.VerifyPayConfirmAPI
  # Settlement of a payment:
  PayCompleteV2API=Settings.SixPayment.HttpsAPI.PayCompleteV2API

  #
  # Location of the Certificate Authority's Public Keys
  #
  CertsFile=Settings.SixPayment.CertsFile 
  VerifyCerts=Settings.SixPayment.VerifyCerts

  # 
  # Specail password for SIX SaferPay test system only
  PasswordForTestOnly=Settings.SixPayment.TestPassword 

  #
	# Define a subset of currency constants as per ISO 4217
  #
	CHF='CHF'
	EUR='EUR'
	USD='USD'

  #
  # Define a subset of languages as per ISO ISO 6391-1
  # These are languages supported on the saferpay payment page
  #
  GERMAN='de'
  ENGLISH='en'
  FRENCH='fr'
  DANISH='da'
  CZECH='cs'
  SPANISH='es'
  CROATIAN='hr'
  ITALIAN='it'
  HUNGARIAN='hu'
  DUTCH='nl'
  NORWEGIAN='no'
  POLISH='pl'
  PORTUGUESE='pt'
  RUSSIAN='ru'
  ROMANIAN='ro'
  SLOVAK='sk'
  SLOVENIAN='sl'
  FINNISH='fi'
  SWEDISH='sv'
  TURKISH='tr'
  GREEK='el'
  JAPANESE='ja'


  #############################################
  #
  # Instance Methods
  #
  #############################################

  #
  # Initialise. 
  # Based on current environment give attributes reasonable defaults.
  #
  def initialize (args = {})

    # Set all mandatory and important variables to a default...
    @accountId = Settings.SixPayment.AccountID
    @vtConfig = Settings.SixPayment.VtConfig
    @notifyAddress = Settings.SixPayment.NotifyAddress
    @showLanguages = Settings.SixPayment.ShowLanguages
    @delivery = Settings.SixPayment.Delivery 

    # Apply args...
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }

  end

  #
  # valid?
  # Instance Method
  # Returns true or false to indicate mandatory fields have been set.
  #
  def valid?
    begin
      # First check constants.
      raise ValidationException, 'CreatePayInitAPI is blank'    if CreatePayInitAPI.blank?
      raise ValidationException, 'VerifyPayConfirmAPI is blank' if VerifyPayConfirmAPI.blank?
      raise ValidationException, 'PayCompleteV2API is blank'    if PayCompleteV2API.blank?

      # Mandatory Fields on the CreatePayInitAPI message.
      raise ValidationException, '@accountId is blank' if @accountId.blank?
      raise ValidationException, '@amount is nil' if @amount.nil?
      raise ValidationException, '@amount <= 0' if @amount <= 0
      raise ValidationException, '@currency is blank' if @currency.blank?
      raise ValidationException, '@description is blank' if @description.blank?
      raise ValidationException, '@orderId is blank' if @orderId.blank?

      # Other important fields
      raise ValidationException, '@vtConfig is blank' if @vtConfig.blank?
      raise ValidationException, '@successLink is blank' if @successLink.blank?
      raise ValidationException, '@failLink is blank' if @failLink.blank?
      raise ValidationException, '@backLink is blank' if @backLink.blank?
      raise ValidationException, '@notifyURL is blank' if @notifyURL.blank?
      raise ValidationException, '@notifyAddress is blank' if @notifyAddress.blank?
      raise ValidationException, '@userNotify is blank' if @userNotify.blank?

      raise ValidationException, 'verifyCerts is true but CertsFile is blank' if SixPayment::verifyCerts? && CertsFile.blank?

    rescue ValidationException => e
      Rails.logger.debug " Instance invalid because: #{e.message}"
      return false
    end  

    # Everything must be ok.
    return true 
  end

  # 
  # getPayPageURI
  # Instance Method
  # Get the createPayInit URL to redirect via to the payments page
  # Call the saferpay https API to get the payment page URL
  # Returns nil on error.
  #
  def getPayPageURI (args = {})
    Rails.logger.debug "Called with args: #{args.to_s}"

    # Apply args...
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }

    # Check we're valid.
    if (!valid?)
      Rails.logger.error "Class not fully initialised #{self.to_s}"
      return nil
    end

    # Call the web service
    begin
      res = SixPayment::callWebService(getCreatePayInitApiUri(args))
    rescue Timeout::Error
      Rails.logger.error "Call to CreatePayInitAPI WebService Timed Out!"
      return nil
    end

    # Check the result
    # Always returns HTTPSuccess. A failure is indicated in the result body with an ERROR string.
    if (!res.is_a?(Net::HTTPSuccess))
      Rails.logger.error "Call to CreatePayInitAPI WebService expected HTTPSuccess got: #{res.to_s}"
      return nil
    end

    if (res.body =~ /^ERROR\:/)
      Rails.logger.error "Call to CreatePayInitAPI WebService returned error: #{res.body}"
      return nil
    end

    return res.body
  end

  def CreatePayInit (args = {})
    return self.getPayPageURI(args)
  end

  #############################################
  #
  # Class Methods
  #
  #############################################

  def self.verifyCerts?
    return (VerifyCerts.nil? ? false : VerifyCerts)
  end

  # 
  # logSuccessfulPayment ( app_args, request_params)
  # Class Method
  # Log a success payment.
  # 
  #
  def self.logSuccessfulPayment (app_args, request_params)

    confId = ""
    msg = ""

    # Build a log string with the application args.
    msg << "AppArgs["
    app_args.each {|key, value| msg << "#{key}:\"#{value}\" " }
    msg << "]"

    # Add the payment success fields from the xml string in the DATA parameter of the request.
    data = request_params["DATA"]
    if data
      # Parse the DATA parameter.
      pe = REXML::Document.new(data).elements['IDP']

      if pe.nil?
        Rails.logger.error "Mandatory IDP element missing from DATA parameter!"
      else
        msg << " PaymentParams["
        pe.attributes.each {|key, value| msg << "#{key}:\"#{value}\" " }
        msg << "]"
        confId = pe.attributes['ID'] 
      end
    end

    Rails.logger.info "[PaymentSuccess] #{msg}"

    return confId
  end

  # 
  # processPaymentNotification (ActionDispath::Request request)
  # Class Method  
  # Process a payment notification.
  # This method takes the request from the controller action invoked by SIX on the
  # notifyURL.
  #
  def self.processPaymentNotification (request)

    Rails.logger.debug "Processing request method: #{request.method.to_s} " <<
                       "url: #{request.url.to_s} " <<
                       "params: #{request.params.to_s} " <<
                       "remote_ip: #{request.remote_ip.to_s}"
 
    # Pull out DATA and SIGNATURE from parameters
    data, signature = request.params["DATA"], request.params["SIGNATURE"]

    # Check key parameters are present.
    unless (data && signature)
      Rails.logger.error "Missing mandatory parameter(s) (DATA and/or SIGNATURE!)"
      Rails.logger.error "Ignoring notifcation from #{request.remote_ip} with params #{request.params}"
      return
    end

    # Parse the DATA parameter.
    pe = REXML::Document.new(data).elements['IDP']

    if pe.nil?
      Rails.logger.error "Mandatory IDP element missing from DATA parameter!"
      return
    end

    if pe.attributes['MSGTYPE'] != 'PayConfirm'
      Rails.logger.error "Expected msgtype \'PayConfirm\' got \'#{pe.attributes['MSGTYPE']}\'!"
      return
    end

    Rails.logger.debug "IDP Attributes retrieved from DATA Params are: #{pe.attributes}"

    #
    # Verify the PayConfirm and if ok complete the payment
    #
    # TODO: Use delayed execution to do veriy and pay confirm.
    # This would prevent re-entrancy on the SIX api and avoid
    # potential HTTP timeouts on the caller to this URI
    payComplete pe.attributes if verifyPayConfirm request.params 

  end

  # 
  # verifyPayConfirm
  # Class Method
  # Verifies the given PayConfirm message.
  # http: request containing the PayConfirm message
  # returns true on successful verification else false. 
  #
  def self.verifyPayConfirm(params)
    #
    # Pass the DATA and SIGNATURE params on the verify web service
    #
    Rails.logger.debug " Verifying payConfirm with params: #{params.to_s}"

    # Build a URI using just the DATA and SIGNATURE query pramaters from the params
    uri = URI.join(VerifyPayConfirmAPI,
                    "?" + 
                    URI.encode_www_form(params.select { |k| k == 'DATA' || k == 'SIGNATURE' } ))

    # Call the Verify WebService
    Rails.logger.debug "Calling verifyPayConfirm with URI: #{uri.to_s}"
    begin
      res = callWebService(uri)
    rescue Timeout::Error
      Rails.logger.error "Call to VerifyPayConfirm WebService Timed Out URI: #{uri.to_s}!"
      return false
    end

    # Check the result.
    # Always returns HTTPSUccess. A failure is indicated in the result body with an ERROR string.
    if (!res.is_a?(Net::HTTPSuccess))
      Rails.logger.error "Call to VerifyPayConfirmAPI WebService expected HTTPSuccess got: #{res.to_s}"
      return false
    end

    Rails.logger.debug "Result of verifyPayConfirm web service call: \"#{res.body}\""

    if (res.body =~ /^ERROR\:/)
      Rails.logger.error "Error result from verifyPayConfirm web service call! ErrMsg is: \"#{res.body}\""
      return false
    end

    # Everything must be good.
    return true
  end

  # 
  # payComplete (args)
  # Class Method 
  # Instructs SIX SaferPay to turn the reservation into a payment.
  #
  def self.payComplete (args)
    Rails.logger.debug "payComplete called with params: #{args.to_s}"

    # Check for mandatory args ACCOUNTID and ID
    unless (args['ACCOUNTID'] && args['ID'])
      Rails.logger.error "Mandatory argument(s) missing (ACCOUNTID and/or ID)!"
      Rails.logger.error "Skipping payComplete on payment with args: #{args.to_s}"
      return
    end

    # Build a URI with only the ACCOUNTID, ID and spPassword parameters.
    # Add the specail test password into the parameters.
    # This should only be done on the SIX SaferPay test system
    args['spPassword'] = PasswordForTestOnly unless PasswordForTestOnly.blank?

    uri = URI.join(PayCompleteV2API, "?" + 
              URI.encode_www_form(args.select { |k| ['ACCOUNTID', 'ID', 'spPassword'].include? k } ))

    # Call the PayComplete WebService
    Rails.logger.debug "Calling PayComplete with URI: #{uri.to_s}"
    begin
      res = callWebService(uri)
    rescue Timeout::Error
      Rails.logger.error "Call to PayCompleteAPI WebService Timed Out URI: #{uri.to_s}!"
      return
    end

    # Check the result.
    # Always returns HTTPSUccess. A failure is indicated in the result body with an ERROR string.
    if (!res.is_a?(Net::HTTPSuccess))
      Rails.logger.error "Call to PayCompleteAPI WebService expected HTTPSuccess got: #{res.to_s}"
      return
    end

    Rails.logger.debug "Result of payComplete web service call: \"#{res.body}\""

    if (res.body =~ /^ERROR\:/)
      Rails.logger.error "Error result from payComplete web service call! ErrMsg is: \"#{res.body}\""
      return false
    end

    # Payment Completed.
    Rails.logger.info "Payment Complete :o) Result from web service call: \"#{res.body}\""
  end

  #############################################
  #
  # Private Methods
  #
  #############################################

  private

  #
  # getCreatePayInitApiUri
  # Private Instance Method
  # The URL to call to get the URL for the payment page.
  #
  # example of Uri...
  # https://www.saferpay.com/hosting/CreatePayInit.asp?ACCOUNTID=99867-94913159&AMOUNT=10&CURRENCY=EUR&DESCRIPTION="Test test test1"&VTCONFIG=DarrenPlay
  #
  def getCreatePayInitApiUri (args = {})

    # Apply args...
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }

    # Build params part of URI
    params = {};
    params['ACCOUNTID'] = @accountId unless @accountId.blank?
    params['AMOUNT'] = ("%d" % (@amount * 100)) unless @amount.nil? || @amount <= 0
    params['CURRENCY'] = @currency unless @currency.blank?
    params['DESCRIPTION'] = @description unless @description.blank?
    params['ORDERID'] = @orderId unless @orderId.blank?
    params['VTCONFIG'] = @vtConfig unless @vtConfig.blank?
    params['SUCCESSLINK'] = @successLink unless @successLink.blank?
    params['FAILLINK'] = @failLink unless @failLink.blank?
    params['BACKLINK'] = @backLink unless @backLink.blank?
    params['NOTIFYURL'] = @notifyURL unless @notifyURL.blank?
    params['AUTOCLOSE'] = @autoClose unless @autoClose.nil?
    params['NOTIFYADDRESS'] = @notifyAddress unless @notifyAddress.blank?
    params['USERNOTIFY'] = @userNotify unless @userNotify.blank?
    params['LANGID'] = @langId unless @langId.blank?
    params['SHOWLANGUAGES'] = @showLanguages unless @showLanguages.blank?
    params['CARDREFID'] = @cardRefId unless @cardRefId.blank?
    params['DELIVERY'] = @delivery unless @delivery.blank?

    Rails.logger.debug "Parameters for CreatePayInitAPI are: #{params.to_s}"

    return URI.join(CreatePayInitAPI,
                    "?" + URI.encode_www_form(params))

  end

  #
  # callWebService
  # Private Class Method
  # Invoke a web service call.
  # Can cause timeout exceptions.
  #
  def self.callWebService(uri)
    #
    # Code is uglier that necessary as https requires a different calling convention.
    # 
    return Net::HTTP.get_response(uri) unless uri.scheme == 'https'

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.ca_file = CertsFile 
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless verifyCerts?
    request = Net::HTTP::Get.new(uri.request_uri)
    return http.request(request)
  end

  #
  # Private Exception class for the valid? method.
  #
  class ValidationException < ArgumentError
  end
end





