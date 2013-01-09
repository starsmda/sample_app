class StaticPagesController < ApplicationController
  def home
    if signed_in?
      @micropost  = current_user.microposts.build
      @feed_items = current_user.feed.paginate(page: params[:page])
  	end
  end

  def help
  end

  def about
  end

  def contact
  end


  #
  # Handle payment success or failure
  #
  def payfail
    # Payment fialed for some reason. The reason for the failure is not given from SIX Saferpay
    logger.debug "called with request.params: #{request.params.to_s}"
    flash[:error] = "Subscription failed! Please try again or call support."
    redirect_to edit_user_url(current_user)
  end

  def paysuccess
    # Payment suceeded.
    # Processing is handled in the notify URL
    logger.debug "called with request.params: #{request.params.to_s}"

    # Retrieve the confirmation ID and log the success
    args = { :UserId => current_user.id,
             :UserName => current_user.name, 
             :UserEmail => current_user.email }
    confirmId = SixPayment::logSuccessfulPayment args, params
    confirmId = " Confirmation ID:\"#{confirmId}\"." unless confirmId.blank?

    flash[:success] = "Subscription successful.#{confirmId} Thank you."

    redirect_to edit_user_url(current_user)
  end
end
