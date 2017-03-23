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

    if params[:settings]
      @settings = params[:settings] 
      otherTeamId = @settings[:otherTeamSettings][:id]
    else
      @settings = { }
      otherTeamId = nil
    end

    team = @draft_helper.league.my_team
    @my_team = { :id => team.id, :name => team.name, :slots_with_players => team.get_slots_with_players, 
                 :team_percentiles => team.team_percentiles, :team_raw_stats => team.team_raw_stats, :hidden => false }

    @other_teams = [ ]

    @best_hitting_team = { :id => 0, :avg_percentile => 0 }
    @best_pitching_team = { :id => 0, :avg_percentile => 0 }
    @best_overall_team = { :id => 0, :avg_percentile => 0 }
    average_team_percentile_values = { :bat => { }, :pit => { } }
    average_team_raw_values = { :bat => { }, :pit => { } }

    @draft_helper.league.teams.each do |team|
      if team.name != 'My Team'
        if otherTeamId.nil?
          otherTeamId = team.id
        end

        avg_percentiles = team.get_average_team_percentiles

        if (avg_percentiles['bat'] > @best_hitting_team[:avg_percentile])
          @best_hitting_team[:id] = team.id
          @best_hitting_team[:avg_percentile] = avg_percentiles['bat']
        end

        if (avg_percentiles['pit'] > @best_pitching_team[:avg_percentile])
          @best_pitching_team[:id] = team.id
          @best_pitching_team[:avg_percentile] = avg_percentiles['pit']
        end

        if (avg_percentiles['overall'] > @best_overall_team[:avg_percentile])
          @best_overall_team[:id] = team.id
          @best_overall_team[:avg_percentile] = avg_percentiles['overall']
        end

        team.team_percentiles.each do |type, set|
          set.each do |category, data|
            average_team_percentile_values[type][category] = [ ] if average_team_percentile_values[type][category].nil? 

            average_team_percentile_values[type][category].push(data[:avg_percentile])
          end
        end

        team.team_raw_stats.each do |type, set|
          set.each do |category, data|
            average_team_raw_values[type][category] = [ ] if average_team_raw_values[type][category].nil? 

            average_team_raw_values[type][category].push(data[:avg_raw_stat])
          end
        end

        @other_teams.push({ :id => team.id, :name => team.name, :slots_with_players => team.get_slots_with_players, 
                             :team_percentiles => team.team_percentiles, :team_raw_stats => team.team_raw_stats, :hidden => (otherTeamId.to_i != team.id) })
      end
    end

    average_team_percentiles = { :bat => { }, :pit => { } }
    average_team_raw_stats = { :bat => { }, :pit => { } }

    average_team_percentile_values.each do |type, set|
      set.each do |category, values|
        average_team_percentiles[type][category] = { :avg_percentile => 0.0, :values => [ ] } if average_team_percentiles[type][category].nil?

        average_team_percentiles[type][category][:avg_percentile] = (values.reduce(0, :+) / values.length).round(3)
      end
    end

    average_team_raw_values.each do |type, set|
      set.each do |category, values|
        average_team_raw_stats[type][category] = { :avg_raw_stat => nil, :values => [ ] } if average_team_raw_stats[type][category].nil?

        average_team_raw_stats[type][category][:avg_raw_stat] = (values.reduce(0, :+) / values.length).round(3)
      end
    end

    @other_teams.push( { :id => 'allOtherTeamAvgs', :name => 'Other Teams (Avg)', :slots_with_players => @draft_helper.league.my_team.get_all_slots_as_empty,
                         :team_percentiles => average_team_percentiles, :team_raw_stats => average_team_raw_stats, :hidden => (otherTeamId != 'allOtherTeamAvgs') });


    @sorted_list = { :div_id => 'availablePlayersDummy', :value_label => 'Value', :list => [], :minmax => { } }

    authorize! :read, @draft_helper
  end

  def addPlayerToTeam
    draft_helper = DraftHelper.find(params[:id])
    team = Team.find(params[:teamId])
    player = Player.find(params[:playerId])

    if (team.add_player(player))
      redirect_to draft_helper_path(draft_helper, { :settings => params[:settings] })
    else
      render :status => 400
    end
  end

  def removePlayerFromTeam
    draft_helper = DraftHelper.find(params[:id])
    team = Team.find(params[:teamId])
    player = Player.find(params[:playerId])

    if (team.remove_player(player))
      redirect_to draft_helper_path(draft_helper, { :settings => params[:settings] })
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
    params.require(:draft_helper).permit(:settings, :teamId, :playerId)
  end
end
