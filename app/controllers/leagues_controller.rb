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

    redirect_to root_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def changeTeamName
    league = League.find(params[:id])
    team = Team.find(params[:teamId])
    team.name = params[:newName]

    if (team.save)
      redirect_to league_path
    else
      render :status => 400
    end
  end

  private 
  def league_params
    params.require(:league).permit(:name, :teams)
  end
end
