module MercatorIcecat
  class Engine < ::Rails::Engine
    isolate_namespace MercatorIcecat

    config.icecat = true
  end
end
