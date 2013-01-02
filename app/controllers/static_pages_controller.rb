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
  # TODO: Review/Remove or use to redirect.
  #
  def payfail
    # Payment fialed for some reason.
    # TODO: Find and display reason.
    flash[:error] = "Subscription failed! Please try again or call support."
    redirect_to edit_user_url(current_user)
  end

  def paysuccess
    # Payment suceeded.
    # Processing is handled in the notify URL
    # For now just say thanks.
    flash[:success] = "Subscription successful. Thanks you."
    redirect_to edit_user_url(current_user)
  end
end
