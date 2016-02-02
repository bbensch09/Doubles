class SwipesController < ApplicationController
    before_action :login_user

      # POST /api/swipes
    def create
      case params[:type]
        when "yes"
          swipe_yes
        when "no"
          swipe_no
      end
    end

    def feed
      @next_five_users = current_user.narrow_users[0..4] if current_user
      if request.xhr?
        cards = render :parial => 'swipes/generate_cards', :locals => {:next_five_users => @next_five_users }

        render :json => {
          num_cards: @next_five_users.length,
          cards: cards
          }
      else
        if current_user.bio.nil?
          redirect_to '/finish_profile'
        else
          unless session[:swipes_explanation] || (current_user.swipes.count > 0)
            flash[:show_modal] = true
            flash[:modal_to_show]= 'users/swipes_explanation'
            session[:swipes_explanation] = true;
          end
        end
      end
    end

    private

    def swipe_yes
      new_swipe = current_user.swipes.create(swipee_id: params[:user_id], swiped_yes: true)
      match_found = User.find(params[:user_id]).swipes.where(swipee_id: current_user.id, swiped_yes: true).length > 0
      @matched_user = User.find(params[:user_id]) if match_found

      if request.xhr?
        render :partial => 'matches/overlay_modal'
      else
        if match_found
          render '/matches/overlay' and return if match_found
        else
          redirect_to "/feed"
        end
      end
    end

    def swipe_no
      current_user.swipes.create(swipee_id: params[:user_id], swiped_yes: false)
      if request.xhr?
        head :ok, content_type: "text/html"
      else
        redirect_to "/feed"
      end
    end
end
