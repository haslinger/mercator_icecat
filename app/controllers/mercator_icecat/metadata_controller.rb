module MercatorIcecat
  class MetadataController < ApplicationController

    hobo_model_controller MercatorIcecat::Metadata
    auto_actions :all
  end
end