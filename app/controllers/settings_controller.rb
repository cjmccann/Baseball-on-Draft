class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @setting = Setting.find(params[:id])
    authorize! :read, @setting
  end

  def new
    @setting = Setting.new
    @batter_positions = nil
    @pitcher_positions = nil
    @batter_categories = nil
    @pitcher_positions = nil
  end

  def edit
    @setting = Setting.find(params[:id])
    authorize! :update, @setting
  end

  def create
    @setting = Setting.new(setting_params)
    @setting.user = current_user
    @setting.league = League.find(params[:league_id])

    if @setting.save
      redirect_to @setting.league
    else
      render 'new'
    end
  end

  private
  def setting_params
    params.require(:setting).permit(:fields)
  end
end
