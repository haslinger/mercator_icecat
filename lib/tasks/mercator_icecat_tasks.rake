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
  end
end