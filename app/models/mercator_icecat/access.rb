require 'open-uri'

module MercatorIcecat
  class Access

    attr_accessor(:user, :password, :vendor, :lang, :typ, :base_uri, :full_index_url, :daily_index_url, :open_uri_options)

    USER = CONFIG[:icecat_user]
    PASSWORD = CONFIG[:icecat_password]
    VENDOR = "HP"
    LANG = "int"
    TYP = "productxml"
    BASE_URL = "http://data.icecat.biz"
    FULL_INDEX_URL = BASE_URL + "/export/freexml/files.index.xml"
    DAILY_INDEX_URL = BASE_URL + "/export/freexml/daily.index.xml"


    # --- Class Methods --- #

    def self.open_uri_options
      {:http_basic_authentication => [self::USER, self::PASSWORD]}
    end


    def self.download_index(full: false)
      if full
        file = File.new(Rails.root.join("vendor","catalogs","files.index.xml"), "w")
        io = open( FULL_INDEX_URL, open_uri_options.merge({"Accept-Encoding" => "gzip"}) )
      else
        file = File.new(Rails.root.join("vendor","catalogs",Date.today.to_s + "-index.xml"), "w")
        io = open( DAILY_INDEX_URL, open_uri_options.merge({"Accept-Encoding" => "gzip"}) )
      end
      unzipped_io = Zlib::GzipReader.new( io )
      unzipped_io.each do |line|
        file.write line
      end
      file.close
      io.close
    end


    def self.product(product_id: nil, path: nil) # accepts product_id or path as parameter
      return open(self.product_url(product_id: product_id), open_uri_options).read if product_id
      return open(BASE_URL + "/" + path, open_uri_options).read if path
    end


    def self.product_url(product_id: nil)
      BASE_URL + "/xml_s3/xml_server3.cgi?prod_id=" + product_id + ";vendor=" + VENDOR + ";lang=" + LANG + ";output=" + TYP
    end
  end
end