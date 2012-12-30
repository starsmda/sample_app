include ApplicationHelper

def sign_in(user)
  visit signin_path
  fill_in "Email",    with: user.email
  fill_in "Password", with: user.password
  click_button "Sign in"
  # Sign in when not using Capybara as well.
  cookies[:remember_token] = user.remember_token
end

# Support the have_constant check.
#
# The following breaks spork after a bundle install!
#matcher :have_constant do |const|
#  match do |owner|
#    (owner.is_a?(Class) ? owner : owner.class).const_defined?(const)
#  end
#end

# This is an alternative.
#RSpec::Matchers.define :have_constant do |const|
#  match do |owner|
#    owner.const_defined?(const)
#  end
#end

# This is a hybred of the two versions...
# spork seems happy with this version.
RSpec::Matchers.define :have_constant do |const|
  match do |owner|
    (owner.is_a?(Class) ? owner : owner.class).const_defined?(const)
  end
end
