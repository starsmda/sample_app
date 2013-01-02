module UsersHelper
	
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user, options = { size: 50 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  # Payment link for a user
  def buySubscription_for(user, 
                          amount, 
                          currency, 
                          description = "Subscription")

    sp = SixPayment.new(amount: amount, 
  						  currency: currency,
  						  description: description,
  						  orderId: user.id,
  						  notifyAddress: user.email,
                backLink: edit_user_url(user),
                failLink: payfail_url(user),
                successLink: paysuccess_url(user),
                notifyURL: payment_notifications_notify_url)

    logger.debug("Set payment callbacks to" + 
                 " back = " + sp.backLink + 
                 " fail = " + sp.failLink + 
                 " success = " + sp.successLink +
                 " notify = " + sp.notifyURL)

    # Todo? Set notify URL?

    return sp.getPayPageURI()
  end

end
