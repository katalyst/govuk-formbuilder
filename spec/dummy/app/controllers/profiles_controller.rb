# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[show edit update destroy]

  attr_reader :profiles, :profile

  def index
    @profiles = Profile.all

    render(locals: { profiles: })
  end

  def show
    render(locals: { profile: })
  end

  def new
    @profile = Profile.new

    render(locals: { profile: })
  end

  def edit
    render(locals: { profile: })
  end

  def create
    @profile = Profile.new(profile_params)

    if profile.save
      redirect_to(profile, status: :see_other)
    else
      render(:new, locals: { profile: }, status: :unprocessable_entity)
    end
  end

  def update
    if profile.update(profile_params)
      redirect_to(profile, status: :see_other)
    else
      render(:edit, locals: { profile: }, status: :unprocessable_entity)
    end
  end

  def destroy
    profile.destroy

    redirect_to(profiles_path, status: :see_other)
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(
      :name, :email, :bio, :active, :age, :status, :country,
      :description, :avatar, :cv,
      # govuk_date_field submits multiparameter date components
      "born_on(1i)", "born_on(2i)", "born_on(3i)"
    )
  end
end
