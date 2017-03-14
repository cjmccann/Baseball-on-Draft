class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new 

    can :manage, League, :user_id => user.id
    can :manage, Team, :user_id => user.id
    can :manage, SettingManager, :user_id => user.id
    can :manage, DraftHelper, :user_id => user.id
    can :manage, Player, :user_id => user.id
  end
end
