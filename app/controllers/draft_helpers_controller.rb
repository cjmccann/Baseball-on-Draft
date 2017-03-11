class DraftHelpersController < ApplicationController
  def index
  end

  def show
    @draft_helper = DraftHelper.find(params[:id])
    authorize! :read, @draft_helper
  end

  def new
    @draft_helper = DraftHelper.new
  end

  def edit
    @draft_helper = DraftHelper.find(params[:id])
    authorize! :update, @draft_helper
  end

  def create
    binding.pry
    @draft_helper = DraftHelper.new(league_params)
    @draft_helper.user = current_user
    @draft_helper.league = nil

    if @league.save
      redirect_to setting_manager_path(@league.setting_manager)
    else
      render 'new'
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
