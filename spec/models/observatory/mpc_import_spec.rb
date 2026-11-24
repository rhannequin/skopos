# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observatory::MpcImport, type: :model do
  describe "#import" do
    it "imports the ground-based observatories" do
      Observatory::MpcImport.new(mpc_list).import

      expect(Observatory.order(:code).pluck(:code, :name)).to eq([
        ["000", "Greenwich"],
        ["511", "Haute Provence"],
        ["H32", "Texas A&M Physics Observatory, College Station"],
        ["M22", "ATLAS South Africa, Sutherland"]
      ])
    end

    it "reads the longitude and parallax constants" do
      Observatory::MpcImport.new(mpc_list).import

      expect(Observatory.find_by!(code: "M22")).to have_attributes(
        longitude: 20.81033,
        parallax_cos: 0.845561,
        parallax_sin: -0.532616
      )
    end

    it "removes the observatories that are no longer listed" do
      create(:observatory, code: "X99")

      Observatory::MpcImport.new(mpc_list).import

      expect(Observatory.exists?(code: "X99")).to be(false)
    end

    it "refuses a list without observatories" do
      create(:observatory, code: "511")

      import = Observatory::MpcImport.new("<html>Service unavailable</html>")

      expect { import.import }
        .to raise_error(Observatory::MpcImport::EmptyListError)
      expect(Observatory.exists?(code: "511")).to be(true)
    end

    it "refuses a list much shorter than the stored one" do
      20.times { create(:observatory) }

      expect { Observatory::MpcImport.new(mpc_list).import }
        .to raise_error(Observatory::MpcImport::TruncatedListError)
      expect(Observatory.count).to eq(20)
    end

    it "updates existing observatories" do
      create(:observatory, code: "511", name: "Old name")

      Observatory::MpcImport.new(mpc_list).import

      expect(Observatory.find_by!(code: "511").name).to eq("Haute Provence")
    end
  end

  describe ".fetch" do
    it "imports the list served by the MPC as UTF-8" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return(mpc_list.b)
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      Observatory::MpcImport.fetch

      name = Observatory.find_by!(code: "511").name
      expect(name.encoding).to eq(Encoding::UTF_8)
    end

    it "fails when the MPC answers with an error" do
      response = Net::HTTPServiceUnavailable
        .new("1.1", "503", "Service Unavailable")
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      expect { Observatory::MpcImport.fetch }
        .to raise_error(Net::HTTPFatalError)
    end
  end

  describe ".fetch_if_empty" do
    it "imports the list when there is no observatory yet" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return(mpc_list)
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      Observatory::MpcImport.fetch_if_empty

      expect(Observatory.count).to eq(4)
    end

    it "does not call the MPC when observatories are already there" do
      create(:observatory)
      allow(Observatory::MpcImport).to receive(:fetch)

      Observatory::MpcImport.fetch_if_empty

      expect(Observatory::MpcImport).not_to have_received(:fetch)
    end
  end

  def mpc_list
    file_fixture("mpc_observatory_codes.html").read
  end
end
