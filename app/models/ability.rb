class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new 

    can :manage, League, :user_id => user.id
    can :manage, Team, :user_id => user.id
  end
end
