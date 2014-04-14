class Admin::MetadataController < Admin::AdminSiteController

  def self.model
    MercatorIcecat::Metadatum
  end

  def self.model_name
    mercator_icecat_metadata
  end

  include Hobo::Controller::Model
  auto_actions :all
end
