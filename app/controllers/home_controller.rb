class HomeController < ApplicationController
  def index
    @leagues = League.all
  end
end
