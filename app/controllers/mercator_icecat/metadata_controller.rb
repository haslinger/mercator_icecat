module MercatorIcecat
  class MetadataController < ApplicationController

    hobo_model_controller "MercatorIcecat::Metadatum"
    auto_actions :all
  end
end