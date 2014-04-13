module MercatorIcecat
  class MetadataController < MercatorIcecat::ApplicationController

    hobo_model_controller
    auto_actions :all
  end
end