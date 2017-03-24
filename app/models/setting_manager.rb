class SettingManager < ActiveRecord::Base
  before_create :set_default_values

  belongs_to :league
  belongs_to :user

  mattr_accessor :defaults

  self.defaults = { 
    "num_teams" => 12,
    :batter_positions => {
      "bat_C" => 2,
      "bat_1B" => 1,
      "bat_2B" => 1,
      "bat_3B" => 1,
      "bat_SS" => 1,
      "bat_LF" => 0,
      "bat_CF" => 0,
      "bat_RF" => 0,
      "bat_CI" => 1,
      "bat_MI" => 1,
      "bat_OF" => 5,
      "bat_UTIL" => 2 
    }, 
    :pitcher_positions => {
      "pit_SP" => 4,
      "pit_RP" => 2,
      "pit_P" => 4
    },
    :batter_stats => {
      "bat_r" => true,
      "bat_hr" => true,
      "bat_rbi" => true,
      "bat_sb" => true,
      "bat_obp" => true,
      "bat_slg" => true,
      "bat_doubles" => false,
      "bat_bb" => false,
      "bat_so" => false,
      "bat_avg" => false,
      "bat_war" => false
    },
    :pitcher_stats => {
      "pit_sv" => true,
      "pit_hr" => true,
      "pit_so" => true,
      "pit_era" => true,
      "pit_whip" => true,
      "pit_qs" => true,
      "pit_gs" => false,
      "pit_w" => false,
      "pit_l" => false,
      "pit_h" => false,
      "pit_bb" => false,
      "pit_kper9" => false,
      "pit_bbper9" => false,
      "pit_fip" => false,
      "pit_war" => false,
      "pit_dra" => false
    }
  }

  def convert_all_settings_to_hash
    { :positions => convert_positions_to_hash, :stats => convert_stats_to_hash }
  end

  def convert_positions_to_hash
    hash = { :positions => { :bat => { }, :pit => { } } }

    self.defaults[:batter_positions].each do |position, _|
      hash[:positions][:bat][position.split('_')[1]] = self[position]
    end

    self.defaults[:pitcher_positions].each do |position, count|
      hash[:positions][:pit][position.split('_')[1]] = self[position]
    end

    hash[:positions]
  end

  def convert_stats_to_hash
    hash = { :stats => { :bat => [ ], :pit => [ ] } }

    self.defaults[:batter_stats].each do |category, _|
      if self[category]
        hash[:stats][:bat].push(category.split('_')[1].to_sym)
      end
    end

    self.defaults[:pitcher_stats].each do |category, _|
      if self[category]
        hash[:stats][:pit].push(category.split('_')[1].to_sym)
      end
    end


    hash[:stats]
  end

  def get_stats
    convert_stats_to_hash
  end

  def get_positions
    convert_positions_to_hash
  end

  def create_teams(n)
    if (self.league.teams.length == 0)
      team = self.league.teams.build( { :name => 'My Team', :league => self.league, :user => self.league.user } )
      team.save
    end

    if (self.league.teams.length < n) && (n <= 24)
      names = get_filler_team_names(n)
      index = 0

      while self.league.teams.length < n
        team = self.league.teams.build( { :name => names[index], :league => self.league, :user => self.league.user } )
        team.save
        index += 1
      end
    elsif (self.league.teams.length > n) && (n >= 1) && (n <= 24)
      n_to_delete = self.league.teams.length - n

      while (n_to_delete > 0)
        to_delete = self.league.teams.last

        self.league.teams.delete(Team.find(to_delete.id))

        n_to_delete -= 1
      end
    end
  end

  private
  def set_default_values
    self.defaults[:batter_positions].each do |position, count|
      self[position] = count
    end

    self.defaults[:pitcher_positions].each do |position, count|
      self[position] = count
    end

    self.defaults[:batter_stats].each do |category, bool|
      self[category] = bool
    end

    self.defaults[:pitcher_stats].each do |category, bool|
      self[category] = bool
    end

    self['num_teams'] = 12
  end

  def get_filler_team_names(n)
    names = ['John', 'Phil', 'Matt', 'Kyle', 'Keenan', 'Foo', 'Bar', 'Baz', 'Mr. Anderson', 'Gately', 'Schacht', 'Pemulis',
             'Rebecca', 'Carol', 'Pepe Silvia', 'Jane', 'Gayle', 'Margot', 'Alina', 'Elaine', 'Black Dynamite', 'Kershaw', 'Noah',
             'Thor', 'Rich', 'Corey', 'Charlie', 'Mac', 'Dennis', 'Dee', 'Frank', 'Cricket', 'Rick', 'Morty', 'Beth', 'Birdperson', 'The Waitress',
             'Summer', 'Jerry', 'Tami', 'Bryce', 'Kirk', 'Joey', 'Jonathan', 'Chris', 'Brian', 'Warren', 'Sam', 'Steve', 'Stringer', 'Avon', 'Country Mac',
             'Deloris', 'Bernard', 'The Bluths', 'Reynolds Family', 'Fiendish Dr. Wu', 'Potato', 'Dingus', 'McCringleberry', 'God', 'The McPoyles',
             'Smoochie-Wallace', 'Moizoos', 'Quatro', 'Duprix', 'Jeremiah', 'Dr. Brule', 'Mellow Mike', 'Lady Godiva', 'Brotendo', 'Bill Ponderosa',
             'Meatwad', 'Shake', 'Frylock', 'Jumbo', 'Barnum', 'West', "John's awful team", "John's terrible team", "John's worst team", "John's last-place team",
             'Mr. Pickles', 'Dr. Weird', 'George Washington', 'A friendly ghost', 'The boy wonder', 'David Blaine', 'mlgN0sc0p3', 'Ron Burgundy', 'Champ Kind',
             'Brick Tamlin', 'Last Place', 'Dr. Mantis Toboggan', 'Nathan for You', 'Scott Clam', 'Your Mom', 'Brangadang', 'Atlas', 'Ortho Stice', 'DMZ' ]

    names.sample(n)
  end
end
