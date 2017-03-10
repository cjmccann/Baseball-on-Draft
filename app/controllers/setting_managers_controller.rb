class SettingManagersController < ApplicationController
  before_action :authenticate_user!

  def show
    @setting_manager = SettingManager.find(params[:id])
    @current_settings = @setting_manager.current_settings
    authorize! :read, @setting_manager
  end

  def new
    @setting_manager = SettingManager.new
  end

  def edit
    @setting_manager = SettingManager.find(params[:id])
    authorize! :update, @team
  end

  def update
    @setting_manager = SettingManager.find(params[:id])
    binding.pry
  end

  private
end
