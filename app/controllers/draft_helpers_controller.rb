class DraftHelpersController < ApplicationController
  def index
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

  def show
    @draft_helper = DraftHelper.find(params[:id])
    @data_manager = @draft_helper.data_manager

    @my_team = @draft_helper.league.my_team
    @other_teams = [ ]
    @draft_helper.league.teams.each do |team|
      if team.name != 'My Team'
        @other_teams.push(team)
      end
    end

    @sorted_list = { :div_id => 'availablePlayersDummy', :value_label => 'Value', :list => [], :minmax => { } }
    authorize! :read, @draft_helper
  end

  def addPlayerToTeam
    draft_helper = DraftHelper.find(params[:id])
    team = Team.find(params[:teamId])
    player = Player.find(params[:playerId])

    if (team.add_player(player))
      redirect_to draft_helper_path(draft_helper)
    else
      render :status => 400
    end
  end

  def removePlayerFromTeam
    draft_helper = DraftHelper.find(params[:id])
    team = Team.find(params[:teamId])
    player = Player.find(params[:playerId])

    if (team.remove_player(player))
      redirect_to draft_helper_path(draft_helper)
    else
      render :status => 400
    end
  end

  def availablePlayersTable
    @draft_helper = DraftHelper.find(params[:id])
    sorted_obj = nil

    case params[:tableId]
    when 'availablePlayersCumulative'
      sorted_obj = @draft_helper.data_manager.get_sorted_players_list
      value_label = 'Cumulative % diff'
    when 'availablePlayersAbsolute'
      sorted_obj = @draft_helper.data_manager.get_sorted_players_list_absolute_percentiles
      value_label = 'Absolute % sum'
    when 'availablePlayersAbsolutePos'
      sorted_obj = @draft_helper.data_manager.get_sorted_players_list_with_pos_adjustments
      value_label = 'Abs. % sum, pos adj'
    when 'availablePlayersAbsolutePosSlot'
      sorted_obj = @draft_helper.data_manager.get_sorted_players_list_with_pos_adjustments_plus_slots
      value_label = 'Abs. % sum, pos+slot adj'
    else
      render :status => 400
    end

    @sorted_list = { :div_id => params[:tableId], :value_label => value_label,
                     :list => sorted_obj[:players], :minmax => sorted_obj[:minmax] }
    render :partial => 'player_table'
  end

  private
  def draft_helper_params
    params.require(:draft_helper).permit()
  end
end
