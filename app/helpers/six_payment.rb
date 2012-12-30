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
# 6. Move Currency and Language lists out to a helper
#
#
# CreatePayInit (getPayPageURI)
# The variables required to initiate a payment are available as attritubes with
# sensible defaults. The method also allows attributes on the call invocation.
#
require 'net/https'

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
                :certsFile

	# Define configurations for test and production
	DefaulyTestAccountID='99867-94913159'
	VtConfig='DarrenPlay'

  # Define Saferpay webservice API URLs
  # Generation of a payment link:
  CreatePayInitAPI='https://www.saferpay.com/hosting/CreatePayInit.asp'
  # Verifying an authorization response:
  VerifyPayConfirmAPI='https://www.saferpay.com/hosting/VerifyPayConfirm.asp'
  # Settlement of a payment:
  PayCompleteV2API='https://www.saferpay.com/hosting/PayCompleteV2.asp'

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
      @accountId = '<tbd>'
      @amount = 10.0
      @currency = CHF
      @description = 'DrawMGT V2 Individual Monthly Subscription'
      @orderId = 'P000000000'
      @vtConfig = 'SoftXSprod'
      @successLink = 'http://zg.softxs.ch/test/v2-payment/success.php'
      @failLink = 'http://zg.softxs.ch/test/v2-payment/failure.php'
      @backLink = 'http://zg.softxs.ch/test/v2-payment/cancel.php'
      @notifyURL = 'http://zg.softxs.ch/test/v2-payment/success.php'
      @notifyAddress = 'darren.starsmore@gmail.com'
      @showLanguages = 'yes'
      @delivery = 'no' 
      @verfiyCert = true
      @certsFile = '/usr/local/CA_Certs/cacerts.pem'    
      
    else
      @accountId = DefaulyTestAccountID
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
      @certsFile = '/Users/darrenstarsmore/Development/CA_Certs/cacert.pem'    
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

end





