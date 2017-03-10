class SettingManager < ActiveRecord::Base
  # after_initialize :default_values
  # http://stackoverflow.com/questions/23673513/saving-multiple-records-with-a-single-form-in-rails-4

  has_many :settings, dependent: :destroy
  accepts_nested_attributes_for :settings

  belongs_to :league
  belongs_to :user

  attr_accessor :current_settings

  def current_settings
    if @current_settings.nil?
      store_default_settings
    end

    @current_settings
  end

  private
  def store_default_settings
    # TODO: make this better. repeated code -- but want to make display easy
    @current_settings = { :positions => { :bat => [ ], :pit => [ ] },
                  :stats => { :bat => [ ], :pit => [ ] } }
    
    defaults = default_values

    defaults[:batter_positions].each do |position, count|
      setting = Setting.new( { :league => self.league, :user => self.user,
                               :setting_type => "bat", :name => position, :position_value => count } )
      setting.save

      @current_settings[:positions][:bat].push(setting)
    end

    defaults[:pitcher_positions].each do |position, count|
      setting = Setting.new( { :league => self.league, :user => self.user,
                               :setting_type => "pit", :name => position, :position_value => count } )
      setting.save

      @current_settings[:positions][:pit].push(setting)
    end
    
    defaults[:batter_stats].each do |category, val|
      setting = Setting.new( { :league => self.league, :user => self.user,
                               :setting_type => "bat", :name => category, :category_value => val } )
      setting.save

      @current_settings[:stats][:bat].push(setting)
    end

    defaults[:pitcher_stats].each do |category, val|
      setting = Setting.new( { :league => self.league, :user => self.user,
                               :setting_type => "pit", :name => category, :category_value => val } )
      setting.save

      @current_settings[:stats][:pit].push(setting)
    end
  end

  def default_values
    defaults = { 
      :batter_positions => {
        "C" => 2,
        "1B" => 1,
        "2B" => 1,
        "3B" => 1,
        "SS" => 1,
        "LF" => 0,
        "CF" => 0,
        "RF" => 0,
        "CI" => 1,
        "MI" => 1,
        "OF" => 5,
        "UTIL" => 2 
      }, 
      :pitcher_positions => {
          "SP" => 4,
          "RP" => 2,
          "P" => 4
      },
      :batter_stats => {
        :r => true,
        :hr => true,
        :rbi => true,
        :sb => true,
        :obp => true,
        :slg => true,
        :doubles => false,
        :bb => false,
        :so => false,
        :avg => false,
        :war => false
      },
      :pitcher_stats => {
        :sv => true,
        :hr => true,
        :so => true,
        :era => true,
        :whip => true,
        :qs => true,
        :gs => false,
        :w => false,
        :l => false,
        :h => false,
        :bb => false,
        :kper9 => false,
        :bbper9 => false,
        :fip => false,
        :war => false,
        :dra => false
      }
    }

    defaults
  end
end
