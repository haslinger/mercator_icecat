namespace :icecat do
  namespace :metadata do

    # starten als: 'bundle exec rake icecat:metadata:import_daily'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:import_daily RAILS_ENV=production'
    desc 'Import metadata from Icecat '
    task :import_daily => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:import_daily")
      MercatorIcecat::Metadatum.import(date: Date.today)
      ::JobLogger.info("Finished Job: icecat:metadata:import_daily")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:import_full'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:import_full RAILS_ENV=production'
    desc 'Import metadata from Icecat '
    task :import_full => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:import_full")
      MercatorIcecat::Metadatum.import(full: true)
      ::JobLogger.info("Finished Job: icecat:metadata:import_full")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:assign_products'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:assign_products RAILS_ENV=production'
    desc 'Import metadata from Icecat '
    task :assign_products => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:assign_products")
      MercatorIcecat::Metadatum.assign_products(only_missing: true)
      ::JobLogger.info("Finished Job: icecat:metadata:assign_products")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:download_xml'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:download_xml RAILS_ENV=production'
    desc 'Import all relevant XML files '
    task :download_xml => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:download_xml")
      MercatorIcecat::Metadatum.download
      ::JobLogger.info("Finished Job: icecat:metadata:download_xml")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:download_and_overwrite_xml'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:download_and_overwrite_xml RAILS_ENV=production'
    desc 'Import and overwrite all relevant XML files '
    task :download_and_overwrite_xml => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:download_and_overwrite_xml")
      MercatorIcecat::Metadatum.download(overwrite: true)
      ::JobLogger.info("Finished Job: icecat:metadata:download_and_overwrite_xml")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:update_products'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:update_products RAILS_ENV=production'
    desc 'Update all products from downloaded XML files.'
    task :update_products => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:update_products")
      MercatorIcecat::Metadatum.update_products
      ::JobLogger.info("Finished Job: icecat:metadata:update_products")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:update_product_relations'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:update_product_relations RAILS_ENV=production'
    desc 'Update all products from downloaded XML files.'
    task :update_product_relations => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:update_product_relations")
      MercatorIcecat::Metadatum.update_product_relations
      ::JobLogger.info("Finished Job: icecat:metadata:update_product_relations")
      ::JobLogger.info("=" * 50)
    end
  end

  namespace :catalog do
    # starten als: 'bundle exec rake icecat:catalog:download_daily'
    # in Produktivumgebungen: 'bundle exec rake icecat:catalog:download_daily RAILS_ENV=production'
    desc 'Download catalog index from Icecat '
    task :download_daily => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:catalog:download_daily")
      MercatorIcecat::Access.download_index(full: false)
      ::JobLogger.info("Finished Job: icecat:catalog:download_daily")
      ::JobLogger.info("=" * 50)
    end
  end
end