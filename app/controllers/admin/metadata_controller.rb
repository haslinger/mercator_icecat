class Admin::MetadataController < Admin::AdminSiteController

  hobo_model_controller MercatorIcecat::Metadatum
  auto_actions :all
end
