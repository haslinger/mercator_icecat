class Admin::MetadataController < Admin::AdminSiteController

  def self.model
    MercatorIcecat::Metadatum
  end

  def self.model_name
    mercator_icecat_metadata
  end

  hobo_model_controller
  auto_actions :all
end
