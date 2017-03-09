require 'pry'
class TeamsController < ApplicationController
  before_action :authenticate_user!

  def index
    @league = League.find(params[:league_id])
    @teams = @league.teams
  end

  def show
    #@league = League.find(params[:league_id])
    @team = Team.find(params[:id])
  end

  def new
    @league = League.find(params[:league_id])
    @team = Team.new
  end

  def edit
    @league = League.find(params[:league_id])
    @team = Team.find(params[:id])
  end

  def create
    @team = Team.new(team_params)
    @team.league = League.find(params[:league_id])
    @team.user = @team.league.user

    #redirect_to league_path(@league)
    if @team.save
      redirect_to @team
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
    @team.destroy

    redirect_to league_path(League.find(params[:league_id]))
  end

  private
    def team_params
      params.require(:team).permit(:name, :players)
    end
end
