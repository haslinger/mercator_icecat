namespace :icecat do
  namespace :metadata do

    # starten als: 'bundle exec rake icecat:metadata:import_daily'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:import_daily RAILS_ENV=production'
    desc 'Import metadata from Icecat '
    task :import_daily => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:import_daily")
      MercatorIcecat::Metadata.import(date: Date.today)
      ::JobLogger.info("Finished Job: icecat:metadata:import_daily")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:import_full'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:import_full RAILS_ENV=production'
    desc 'Import metadata from Icecat '
    task :import_full => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:import_full")
      MercatorIcecat::Metadata.import(full: true)
      ::JobLogger.info("Finished Job: icecat:metadata:import_full")
      ::JobLogger.info("=" * 50)
    end

    # starten als: 'bundle exec rake icecat:metadata:assign_products'
    # in Produktivumgebungen: 'bundle exec rake icecat:metadata:assign_products RAILS_ENV=production'
    desc 'Import metadata from Icecat '
    task :assign_products => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: icecat:metadata:assign_products")
      MercatorIcecat::Metadata.assign_products(only_missing: true)
      ::JobLogger.info("Finished Job: icecat:metadata:assign_products")
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