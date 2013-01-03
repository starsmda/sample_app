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
# 2. Configuration mechanism to import config from elsewhere rather than 
#      hardcoded.
# 3. Add valid? method to check optional versus mandatory fields and values are in range.
# 4. Add timeout exception handler around the Net::HTTP.getResponse call and others.
# 5. Add logging of errors.
#
#
#
# CreatePayInit (getPayPageURI)
# The variables required to initiate a payment are available as attritubes with
# sensible defaults. The method also allows attributes on the call invocation.
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
                :delivery,
                :verifyCert,
                :certsFile,
                :passwordForTestOnly

	# Define configurations for test and production
	DefaultTestAccountID='99867-94913159'
	VtConfig='DarrenPlay'

  # Define Saferpay webservice API URLs
  # Generation of a payment link:
  CreatePayInitAPI='https://www.saferpay.com/hosting/CreatePayInit.asp'
  # Verifying an authorization response:
  VerifyPayConfirmAPI='https://www.saferpay.com/hosting/VerifyPayConfirm.asp'
  # Settlement of a payment:
  PayCompleteV2API='https://www.saferpay.com/hosting/PayCompleteV2.asp'

  # The test system requires a passowrd to complete payment :o(
  TestPassword='XAjc3Kna'  

	# Define a subset of currency constants as per ISO 4217
	CHF='CHF'
	EUR='EUR'
	USD='USD'

  # Define a subset of languages as per ISO ISO 6391-1
  # These are languages supported on the saferpay payment page
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

  #
  # Initialise. 
  # Based on current environment give attributes reasonable defaults.
  #
  def initialize (args = {})

    # Set all mandatory and important variables to default...
    if Rails.env.production?
      @accountId = DefaultTestAccountID
      @amount = 10.0
      @currency = CHF
      @description = 'DrawMGT V2 Individual Monthly Subscription'
      @orderId = 'P000000000'
      @vtConfig = 'DarrenPlay'
      @successLink = 'http://zg.softxs.ch/test/v2-payment/success.php'
      @failLink = 'http://zg.softxs.ch/test/v2-payment/failure.php'
      @backLink = 'http://zg.softxs.ch/test/v2-payment/cancel.php'
      @notifyURL = 'http://zg.softxs.ch/test/v2-payment/notice.php'
      @notifyAddress = 'darren.starsmore@gmail.com'
      @showLanguages = 'yes'
      @delivery = 'no' 
      @verfiyCert = true
      @certsFile = (Rails.root + 'app/assets/cacert.pem').to_s
      @passwordForTestOnly = nil  # Must not be used in production 
    else
      @accountId = DefaultTestAccountID
      @amount = 10.0
      @currency = CHF
      @description = '[TEST] DrawMGT V2 Individual Monthly Subscription'
      @orderId = 'T123456789'
      @vtConfig = 'DarrenPlay'
      @successLink = 'http://zg.softxs.ch/test/v2-payment/success.php'
      @failLink = 'http://zg.softxs.ch/test/v2-payment/failure.php'
      @backLink = 'http://zg.softxs.ch/test/v2-payment/cancel.php'
      @notifyURL = 'http://zg.softxs.ch/test/v2-payment/success.php'
      @notifyAddress = 'darren.starsmore@gmail.com'
      @showLanguages = 'yes'
      @delivery = 'no'
      @verifyCert = true
      @certsFile = (Rails.root + 'app/assets/cacert.pem').to_s
      @passwordForTestOnly = TestPassword
    end

    # Apply args...
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
  end

  #
  # getCreatePayInitApiUri
  #
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
    params['AMOUNT'] = ("%d" % (@amount * 100)) unless @amount <= 0
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


    return URI.join(CreatePayInitAPI,
                    "?" + URI.encode_www_form(params))

  end

  #
  # Get the createPayInit URL to redirect via to the payments page
  # Call the saferpay https API to get the payment page URL
  #
  def getPayPageURI (args = {})
    res = nil;

    # Code is uglier that necessary as https requires a different calling convention.
    uri = self.getCreatePayInitApiUri(args);
    if (uri.scheme == 'https')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.ca_file = @certsFile 
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless (self.verifyCert?)
      request = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(request)
    else
      res = Net::HTTP.get_response(uri);
    end

    # Always returns HTTPSUccess. A failure is indicated in the result body with an ERROR string.
    if (!res.is_a?(Net::HTTPSuccess))
      # TODO Log error.
      return nil
    end

    if (res.body =~ /^ERROR\:/)
      # TODO Log error.
      return nil
    end

    return res.body

  end

  def CreatePayInit (args = {})
    return self.getPayPageURI(args)
  end

  # Todo: is there a better way to handle boolean attributes?
  def verifyCert?
    return (@verifyCert.nil? ? false : @verifyCert)
  end

  # 
  # Class Method processPaymentNotification (ActionDispath::Request request)
  # Process a payment notification.
  # This method takes the request from the controller action invoked by SIX on the
  # notifyURL.
  #
  def self.processPaymentNotification (request)
    # Pull out DATA and SIGNATURE from parameters
    data, signature = request.params["DATA"], request.params["SIGNATURE"]

    # Check key parameters are present.
    unless (data && signature)
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         " Missing mandatory parameter(s) (DATA and/or SIGNATURE!)"
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " << 
                         "Ignoring notifcation from #{request.remote_ip} with params #{request.params}"
      return
    end

    # Parse the DATA parameter.
    doc = REXML::Document.new(data)
    pe = doc.elements['IDP']

    if pe.nil?
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "Mandatory IDP element missing!"
      return
    end

    if pe.attributes['MSGTYPE'] != 'PayConfirm'
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "Unexpected msgtype #{pe.attributes['MSGTYPE']}!"
      return
    end

    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "IDP Attributes retrieved are #{pe.attributes}"
    #
    # Verify the PayConfirm and if ok complete the payment
    #
    # TODO: Need to refactor so that a web service call can be done from a class method and doesn't 
    # require this calss instance to be made.
    sp = SixPayment.new
    sp.payComplete pe.attributes if sp.verifyPayConfirm(request.params)

  end

  # 
  # Class Method verifyPayConfirm 
  # Verifies the given PayConfirm message.
  # http: request containing the PayConfirm message
  # returns true on successful verification else false. 
  # TODO: Refactor so this can be class method.
  #
  def verifyPayConfirm(params)
    #
    # Pass the DATA and SIGNATURE params on the verify web service
    #

    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "params = #{params}"
    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "data = #{params['DATA']}"
    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "signature = #{params['SIGNATURE']}"

    # TODO refactor with the getPayPageURI
    res = nil;

    # Just capture the DATA and SIGNATURE from the params
    # TODO: There must be a more eligant way of doing this.
    p = {'DATA' => params['DATA'], 'SIGNATURE' => params['SIGNATURE']}
    # Code is uglier that necessary as https requires a different calling convention.
    uri = URI.join(VerifyPayConfirmAPI,
                    "?" + URI.encode_www_form(p))

    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "Using this URI to verifyPayConfirm #{uri.to_s}"

    if (uri.scheme == 'https')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.ca_file = @certsFile 
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless (self.verifyCert?)
      request = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(request)
    else
      res = Net::HTTP.get_response(uri);
    end

    # Always returns HTTPSUccess. A failure is indicated in the result body with an ERROR string.
    if (!res.is_a?(Net::HTTPSuccess))
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "Didn't get HTTPSuccess result from web service call!"
      return false
    end

    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "Result from web service call: \"#{res.body}\""

    if (res.body =~ /^ERROR\:/)
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "ERROR result from verify web service call! ErrMsg is: \"#{res.body}\""
      return false
    end

    return true
  end

  # 
  # Class Method payComplete (args)
  # TODO:
  #
  def payComplete (args)

    #
    # Check for mandatory args ACCOUNTID and ID
    #
    unless (args['ACCOUNTID'] && args['ID'])
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "Mandatory argument(s) missing (ACCOUNTID and/or ID)!"
      return
    end

    # TODO refactor to capture below once and also from and class method.

    # TODO: There must be a more eligant way of doing this.
    p = {'ACCOUNTID' => args['ACCOUNTID'], 'ID' => args['ID']}

    # Need to add in a password on the test system.
    p['spPassword'] = @passwordForTestOnly unless @passwordForTestOnly.blank?

    uri = URI.join(PayCompleteV2API,
                    "?" + URI.encode_www_form(p))

    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "Using this URI to PayComplete #{uri.to_s}"

    # Code is uglier that necessary as https requires a different calling convention.
    if (uri.scheme == 'https')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.ca_file = @certsFile 
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless (self.verifyCert?)
      request = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(request)
    else
      res = Net::HTTP.get_response(uri);
    end

    # Always returns HTTPSUccess. A failure is indicated in the result body with an ERROR string.
    if (!res.is_a?(Net::HTTPSuccess))
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "Didn't get HTTPSuccess result from web service call!"
      return
    end

    Rails.logger.debug "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                       "Result from web service call: \"#{res.body}\""

    if (res.body =~ /^ERROR\:/)
      Rails.logger.error "[DLS] file:#{__FILE__} line:#{__LINE__} method:#{__method__} " <<
                         "ERROR result from verify web service call! ErrMsg is: \"#{res.body}\""
      return
    end

  end
end





