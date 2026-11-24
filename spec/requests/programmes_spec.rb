# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Programmes", type: :request do
  describe "GET /" do
    it "shows the form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Calculer la semaine")
    end
  end

  describe "GET /programme" do
    it "shows every night of the week with its targets" do
      create(:observatory, code: "511", name: "Haute Provence",
        longitude: 5.7157, parallax_cos: 0.72140, parallax_sin: 0.69034)

      get programme_path, params: {programme: programme_params}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lundi 23 novembre")
      expect(response.body).to include("Dimanche 29 novembre")
      expect(response.body).to include("Betelgeuse")
      expect(response.body).to include("17:46")
    end

    it "marks a target that never rises above 20° as too low" do
      create(:observatory, code: "511", name: "Haute Provence",
        longitude: 5.7157, parallax_cos: 0.72140, parallax_sin: 0.69034)
      params = programme_params
        .merge(targets_text: "Southern 05:00:00 -60:00:00 10")

      get programme_path, params: {programme: params}

      expect(response.body).to include("trop basse")
      expect(response.body).not_to include("faisable")
    end

    it "accepts coordinates written with a comma and no altitude" do
      params = programme_params
        .except(:observatory_code)
        .merge(latitude: "43,93", longitude: "5,71", limiting_magnitude: "13,5")

      get programme_path, params: {programme: params}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("43,9300°, 5,7100°")
      expect(response.body).to include("13,5")
    end

    it "shows what is wrong with the form on the page" do
      params = programme_params.merge(observatory_code: "ZZZ")

      get programme_path, params: {programme: params}

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("ne correspond à aucun observatoire du MPC")
    end
  end

  def programme_params
    {
      observatory_code: "511",
      aperture: "300",
      limiting_magnitude: "13.5",
      week_start: "2026-11-23",
      targets_text: "Betelgeuse 05:55:10.30536 +07:24:25.4304 0.5"
    }
  end
end
