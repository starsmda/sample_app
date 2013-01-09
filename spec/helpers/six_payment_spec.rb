#
# Rspec module to test six_payment_helper module and class.
require 'spec_helper'

describe "SixPayment Class" do

  # Class Constants
  it "should have currency constants" do
    SixPayment.const_defined?(:EUR).should be_true
    SixPayment.const_defined?(:CHF).should be_true
    SixPayment.const_defined?(:USD).should be_true
  end

  it "should have language constants" do
    SixPayment.const_defined?(:GERMAN).should be_true
    SixPayment.const_defined?(:ENGLISH).should be_true
    SixPayment.const_defined?(:FRENCH).should be_true
    SixPayment.const_defined?(:DANISH).should be_true
    SixPayment.const_defined?(:CZECH).should be_true
    SixPayment.const_defined?(:SPANISH).should be_true
    SixPayment.const_defined?(:CROATIAN).should be_true
    SixPayment.const_defined?(:ITALIAN).should be_true
    SixPayment.const_defined?(:HUNGARIAN).should be_true
    SixPayment.const_defined?(:DUTCH).should be_true
    SixPayment.const_defined?(:NORWEGIAN).should be_true
    SixPayment.const_defined?(:POLISH).should be_true
    SixPayment.const_defined?(:PORTUGUESE).should be_true
    SixPayment.const_defined?(:RUSSIAN).should be_true
    SixPayment.const_defined?(:ROMANIAN).should be_true
    SixPayment.const_defined?(:SLOVAK).should be_true
    SixPayment.const_defined?(:SLOVENIAN).should be_true
    SixPayment.const_defined?(:FINNISH).should be_true
    SixPayment.const_defined?(:SWEDISH).should be_true
    SixPayment.const_defined?(:TURKISH).should be_true
    SixPayment.const_defined?(:GREEK).should be_true
    SixPayment.const_defined?(:JAPANESE).should be_true
  end

  it "should have configuration constants" do
    SixPayment.const_defined?(:CreatePayInitAPI).should be_true
    SixPayment.const_defined?(:VerifyPayConfirmAPI).should be_true
    SixPayment.const_defined?(:PayCompleteV2API).should be_true
    SixPayment.const_defined?(:CertsFile).should be_true
    SixPayment.const_defined?(:VerifyCerts).should be_true
    SixPayment.const_defined?(:PasswordForTestOnly).should be_true
  end

  it "mandatory configuration items should be set" do
    SixPayment::CreatePayInitAPI.should_not be_blank
    SixPayment::VerifyPayConfirmAPI.should_not be_blank
    SixPayment::PayCompleteV2API.should_not be_blank
  end

  # Class Methods
  it "should have class methods" do
    SixPayment.should respond_to(:verifyCerts?)
    SixPayment.should respond_to(:logSuccessfulPayment)
    SixPayment.should respond_to(:processPaymentNotification)
    SixPayment.should respond_to(:verifyPayConfirm)
    SixPayment.should respond_to(:payComplete)
  end

  it "should take verifyCerts config from Settings" do
    SixPayment.verifyCerts?.should == Settings.SixPayment.VerifyCerts
  end

  #
  # All other Class Methods call web services at SIX SaferPay.
  # 
  # Don't test for now.
  # 
end

describe "SixPayment Instance" do

  before do
  	@sixpayment = SixPayment.new()
  end

  subject { @sixpayment }

  describe "should have accessors" do
    it { should respond_to(:accountId) }
    it { should respond_to(:amount) }
    it { should respond_to(:currency) }
    it { should respond_to(:description) }
    it { should respond_to(:orderId) }
    it { should respond_to(:vtConfig) }
    it { should respond_to(:successLink) }
    it { should respond_to(:failLink) }
    it { should respond_to(:backLink) }
    it { should respond_to(:notifyURL) }
    it { should respond_to(:autoClose) }
    it { should respond_to(:notifyAddress) }
    it { should respond_to(:userNotify) }
    it { should respond_to(:langId) }
    it { should respond_to(:showLanguages) }
    it { should respond_to(:cardRefId) }
    it { should respond_to(:delivery) }
  end

  describe "default Construction" do
    its(:accountId)     { should_not be_blank }
    its(:accountId)     { should == Settings.SixPayment.AccountID }
    its(:vtConfig)      { should == Settings.SixPayment.VtConfig }
    its(:notifyAddress) { should == Settings.SixPayment.NotifyAddress }
    its(:showLanguages) { should == Settings.SixPayment.ShowLanguages }
    its(:delivery)      { should == Settings.SixPayment.Delivery }
    it { should_not be_valid }
  end

  describe "construction with args" do
    sp = SixPayment.new(amount: 1234, 
                        currency: SixPayment::EUR, 
                        accountId: '123456789',
                        vtConfig: 'TestTestTest')

    it "should take provided args over defaults" do
      sp.amount.should == 1234
      sp.currency.should == SixPayment::EUR
      sp.accountId.should == '123456789'
      sp.vtConfig.should == 'TestTestTest'
    end

    it "should default non-specified attributes" do
      sp.notifyAddress.should == Settings.SixPayment.NotifyAddress
      sp.showLanguages.should == Settings.SixPayment.ShowLanguages
      sp.delivery.should == Settings.SixPayment.Delivery
    end
  end

  describe "Validity" do
    sp = SixPayment.new(amount: 1234, 
                        currency: SixPayment::EUR, 
                        accountId: '123456789',
                        vtConfig: 'TestTestTest')
    it "should remain invalid until all mandatory fields are set" do
      sp.should_not be_valid
      sp.description  = 'Test Description'
      sp.should_not be_valid
      sp.orderId = 'TestOrderId'
      sp.should_not be_valid
      sp.successLink = 'http://www.foo.com/bar'
      sp.failLink = 'http://www.foo.com/bar'
      sp.backLink = 'http://www.foo.com/bar'
      sp.notifyURL = 'http://www.foo.com/bar'
      sp.should_not be_valid
      sp.notifyAddress = 'fred.blogs@foobar.com'
      sp.userNotify = 'bill.smith@foobar.com'
      sp.should be_valid
    end
  end

  describe "Generation of Pay Page link" do
    sp = SixPayment.new(amount: 1234, 
                        currency: SixPayment::EUR, 
                        accountId: '123456789',
                        vtConfig: 'TestTestTest',
                        description: 'Test Description',
                        orderId: 'TestOrderId',
                        successLink: 'http://www.foo.com/bar',
                        failLink: 'http://www.foo.com/bar',
                        backLink: 'http://www.foo.com/bar',
                        notifyURL: 'http://www.foo.com/bar',
                        notifyAddress: 'fred.blogs@foobar.com',
                        userNotify: 'bill.smith@foobar.com')
    it "should generate a valid URI for the payment page" do
      sp.should be_valid
      uri = sp.instance_eval{ getCreatePayInitApiUri }.to_s
      uri.should =~ /^https:\/\//
      uri.should =~ /ACCOUNTID\=/
      uri.should =~ /AMOUNT\=/
      uri.should =~ /CURRENCY\=/
      uri.should =~ /VTCONFIG\=/
      uri.should =~ /SUCCESSLINK\=/
      uri.should =~ /FAILLINK\=/
      uri.should =~ /BACKLINK\=/
      uri.should =~ /NOTIFYURL\=/
    end

=begin 
    # This test hits the SIX SaferPay webservice. 
    # By default it's commented out.
    it "should retrive a valid URI from the saferPay webservice" do
      uri = sp.getPayPageURI(amount: 543, 
                             currency: SixPayment::CHF, 
                             accountId: Settings.SixPayment.AccountID)
      uri.should_not be_blank
      uri.should =~ /^http[s]:\/\//
      uri.should =~ /ACCOUNTID%3d%22/
      uri.should =~ /AMOUNT%3d%2254300/
      uri.should =~ /CURRENCY%3d%22CHF/
    end
=end    

  end
end


