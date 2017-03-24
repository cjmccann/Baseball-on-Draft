class TeamsController < ApplicationController
  before_action :authenticate_user!

  # validates_uniqueness_of :name, scope: [:league]

  def index
    @league = League.find(params[:league_id])
    @teams = @league.teams
  end

  def show
    @team = Team.find(params[:id])
    authorize! :read, @team
  end

  def new
    @league = League.find(params[:league_id])
    @team = Team.new
  end

  def edit
    @team = Team.find(params[:id])
    @league = @team.league
    authorize! :update, @team
  end

  def create
    @team = Team.new(team_params)
    @team.league = League.find(params[:league_id])
    @team.user = @team.league.user

    #redirect_to league_path(@league)
    if @team.save
      redirect_to @team.league
    else
      render 'new'
    end
  end

  def update
    @team = Team.find(params[:id])

    if @team.update(team_params)
      redirect_to @team
    else
      render 'edit'
    end
  end

  def destroy
    @team = Team.find(params[:id])
    @league = @team.league
    authorize! :destroy, @team

    @team.destroy

    redirect_to league_path(@league)
  end

  private
    def team_params
      params.require(:team).permit(:name, :players)
    end
end
