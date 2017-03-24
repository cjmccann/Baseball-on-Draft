class SettingManagersController < ApplicationController
  before_action :authenticate_user!
  before_filter :check_for_cancel, :only => [:create, :update]

  def show
    @setting_manager = SettingManager.find(params[:id])
    authorize! :read, @setting_manager
  end

  def new
    @setting_manager = SettingManager.new
  end

  def edit
    @setting_manager = SettingManager.find(params[:id])
    authorize! :update, @setting_manager
  end

  def update
    @setting_manager = SettingManager.find(params[:id])

    @setting_manager.create_teams(params[:setting_manager]['num_teams'].to_i)

    if @setting_manager.update(setting_manager_params)
      redirect_to @setting_manager.league
    else
      render 'show'
    end

    authorize! :upate, @setting_manager
  end

  private

  def setting_manager_params 
    params.require(:setting_manager).permit('num_teams', SettingManager.defaults[:batter_positions].keys,
                                            SettingManager.defaults[:pitcher_positions].keys,
                                            SettingManager.defaults[:batter_stats].keys,
                                            SettingManager.defaults[:pitcher_stats].keys)
  end

  def check_for_cancel
    @setting_manager = SettingManager.find(params[:id])

    if(params.key?('cancel'))
      redirect_to league_path(@setting_manager.league)
    end
  end
end
