namespace :icecat do
  namespace :metadata do

    # starten als: bundle exec rake icecat:metadata:import_full RAILS_ENV=production
    desc 'Import metadata from Icecat '
    task :import_full => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:import_full")
      MercatorIcecat::Metadatum.import_catalog(full: true)
      ::JobLogger.info("Finished Job: icecat:metadata:import_full")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:metadata:import_daily RAILS_ENV=production
    desc 'Import metadata from Icecat '
    task :import_daily => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:import_daily")
      MercatorIcecat::Metadatum.import_catalog(date: Date.today)
      ::JobLogger.info("Finished Job: icecat:metadata:import_daily")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:metadata:assign_products RAILS_ENV=production
    desc 'Assign Products to Metadata '
    task :assign_products => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:assign_products")
      MercatorIcecat::Metadatum.assign_products(only_missing: true)
      ::JobLogger.info("Finished Job: icecat:metadata:assign_products")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:metadata:download_and_overwrite_xml RAILS_ENV=production
    desc 'Import and overwrite all XML files '
    task :download_and_overwrite_xml => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:download_and_overwrite_xml")
      MercatorIcecat::Metadatum.download(overwrite: true, from_today: false)
      ::JobLogger.info("Finished Job: icecat:metadata:download_and_overwrite_xml")
      ::JobLogger.info("=" * 50)
    end

    # starten als: rake icecat:metadata:download_daily_xml RAILS_ENV=production
    desc 'Import the XML files from the last 25 hours'
    task :download_daily_xml => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:download_daily_xml")
      MercatorIcecat::Metadatum.download(overwrite: true, from_today: true)
      ::JobLogger.info("Finished Job: icecat:metadata:download_daily_xml")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:metadata:update_products RAILS_ENV=production
    desc 'Update all products, properties, property groups and values from downloaded XML files.'
    task :update_products => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:update_products")
      ::Product.update_from_icecat(from_today: false)
      ::JobLogger.info("Finished Job: icecat:metadata:update_products")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:metadata:update_todays_products RAILS_ENV=production
    desc 'Update todays products, properties, property groups and values from downloaded XML files.'
    task :update_todays_products => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:update_todays_products")
      ::Product.update_from_icecat(from_today: true)
      ::JobLogger.info("Finished Job: icecat:metadata:update_todays_products")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:metadata:daily_update RAILS_ENV=production
    desc 'Daily Update '
    task :daily_update => :environment do
      # The first daily run after installation re-downloads all xml files, that's OK.

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:catalog:daily_update")

      ::JobLogger.info("Started Task: icecat:catalog:download_daily")
      MercatorIcecat::Access.download_index(full: false)
      ::JobLogger.info("Finished Task: icecat:catalog:download_daily")

      ::JobLogger.info("Started Task: icecat:metadata:import_daily")
      MercatorIcecat::Metadatum.import_catalog(date: Date.today)
      ::JobLogger.info("Finished Task: icecat:metadata:import_daily")

      ::JobLogger.info("Started Task: icecat:metadata:assign_products")
      MercatorIcecat::Metadatum.assign_products(only_missing: true)
      ::JobLogger.info("Finished Task: icecat:metadata:assign_products")

      ::JobLogger.info("Started Task: icecat:metadata:download_daily_xml")
      MercatorIcecat::Metadatum.download(overwrite: true, from_today: true)
      ::JobLogger.info("Finished Task: icecat:metadata:download_daily_xml")

      ::JobLogger.info("Started Task: icecat:metadata:update_todays_products")
      ::Product.update_from_icecat(from_today: true)
      ::JobLogger.info("Finished Task: icecat:metadata:update_todays_products")

      ::JobLogger.info("Started Task: properties:dedup")
      ::Property.dedup()
      ::JobLogger.info("Finished Task: properties:dedup")

      ::JobLogger.info("Started Task: property_groups:dedup")
      ::PropertyGroup.dedup()
      ::JobLogger.info("Finished Task: property_groups:dedup")

      ::JobLogger.info("Finished Job: icecat:catalog:daily_update")
      ::JobLogger.info("=" * 50)
    end
  end

  namespace :catalog do
    # starten als: bundle exec rake icecat:catalog:download_full RAILS_ENV=production
    desc 'Download full catalog index from Icecat '
    task :download_full => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:catalog:download_full")
      MercatorIcecat::Access.download_index(full: true)
      ::JobLogger.info("Finished Job: icecat:catalog:download_full")
      ::JobLogger.info("=" * 50)
    end

    # starten als: bundle exec rake icecat:catalog:download_daily RAILS_ENV=production
    desc 'Download daily catalog index from Icecat '
    task :download_daily => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:catalog:download_daily")
      MercatorIcecat::Access.download_index(full: false)
      ::JobLogger.info("Finished Job: icecat:catalog:download_daily")
      ::JobLogger.info("=" * 50)
    end
  end
end