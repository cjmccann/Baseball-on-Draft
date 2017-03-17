class LeaguesController < ApplicationController
  before_action :authenticate_user!

  def index
    @leagues = League.all
  end

  def show
    @league = League.find(params[:id])
    authorize! :read, @league
  end

  def new
    @league = League.new
  end

  def edit
    @league = League.find(params[:id])
    authorize! :update, @league
  end

  def create
    @league = League.new(league_params)
    @league.user = current_user
    # @league.setting_manager = SettingManager.new( { :league => @league, :user => current_user } )
    # @league.teams.push(Team.new( { :name => 'My Team', :league => @league, :user => current_user } ))

    if @league.save
      redirect_to setting_manager_path(@league.setting_manager)
    else
      render 'new'
    end


    #@league = League.find(params[:league_id])
    #@team = @league.teams.create(league_params)
  end

  def destroy
    @league = League.find(params[:id])
    authorize! :destroy, @league

    @league.destroy

    redirect_to leagues_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  private 
  def league_params
    params.require(:league).permit(:name, :teams)
  end
end
