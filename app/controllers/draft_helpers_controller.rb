class DraftHelpersController < ApplicationController
  def index
  end

  def show
    @draft_helper = DraftHelper.find(params[:id])
    @draft_helper.data_manager.set_default_values
    # @sorted_player = @draft_helper.data_manager.get_sorted_players_list
    binding.pry
    authorize! :read, @draft_helper
  end

  def new
    @draft_helper = DraftHelper.new
    @league = League.find(params[:league_id])
    @setting_manager = @league.setting_manager
  end

  def edit
    @draft_helper = DraftHelper.find(params[:id])
    authorize! :update, @draft_helper
  end

  def create
    if(League.find(params[:league_id]).draft_helper)
      redirect_to draft_helper_path(League.find(params[:league_id]).draft_helper)
    else
      @draft_helper = DraftHelper.new
      @draft_helper.user = current_user
      @draft_helper.league = League.find(params[:league_id])

      if @draft_helper.save
        redirect_to draft_helper_path(@draft_helper)
      else
        render 'new'
      end
    end
  end

  def destroy
    @league = League.find(params[:id])
    authorize! :destroy, @league

    @league.destroy

    redirect_to leagues_path
  end

  private
  def draft_helper_params
    params.require(:draft_helper).permit()
  end
end
