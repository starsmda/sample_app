#
# Rspec module to test six_payment_helper module and class.
require 'spec_helper'

describe "SixPayment Class" do

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

end

describe "SixPayment Instance" do

  before do
  	@sixpayment = SixPayment.new()
  end

  subject { @sixpayment }

  describe "accessors" do
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
    it { should respond_to(:verifyCert) }
    it { should respond_to(:verifyCert?) }
    it { should respond_to(:certsFile) }
  end

  describe "default Construction" do
    its(:accountId)   { should_not be_blank }
    its(:accountId)   { should == SixPayment::DefaulyTestAccountID }
    its(:description) { should =~ /^\[TEST\]/ }
    its(:successLink) { should_not be_blank }
    its(:failLink)    { should_not be_blank }
    its(:backLink)    { should_not be_blank } 
    its(:notifyURL)   { should_not be_blank } 
    its(:amount)      { should > 0 } 
    its(:currency)    { should_not be_blank }
    its(:verifyCert)  { should be_true }
    its(:verifyCert?) { should be_true }
    its(:certsFile)   { should_not be_blank }
  end

  describe "construction with args" do
    sp = SixPayment.new(amount: 1234, 
                        currency: SixPayment::EUR, 
                        verifyCert: false,
                        certsFile: '/tmp/cacerts.pem')

    it "should take provided args over defaults" do
      sp.amount.should == 1234
      sp.currency.should == SixPayment::EUR
      sp.verifyCert?.should == false
      sp.certsFile.should == '/tmp/cacerts.pem'
    end
    it "should default non-specified attributes" do
      sp.accountId.should == SixPayment::DefaulyTestAccountID
      sp.description.should =~ /^\[TEST\]/
    end
  end

  describe "CreatePayInit URL generation" do
    it "should be a real URL" do
      @sixpayment.getCreatePayInitApiUri.to_s.should =~ /^https:\/\//
    end
    it "should contain important fields" do
      @sixpayment.getCreatePayInitApiUri.to_s.should =~ /ACCOUNTID\=/
      @sixpayment.getCreatePayInitApiUri.to_s.should =~ /AMOUNT\=/
      @sixpayment.getCreatePayInitApiUri.to_s.should =~ /CURRENCY\=/
    end
  end  
end



