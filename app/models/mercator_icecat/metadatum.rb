require 'saxerator'
require 'open-uri'

module MercatorIcecat
  class Metadatum < ActiveRecord::Base

    hobo_model # Don't put anything above this

    fields do
      path              :string
      icecat_updated_at :datetime
      quality           :string
      supplier_id       :string
      icecat_product_id :string
      prod_id           :string, :index => true
      product_number    :string
      cat_id            :string
      on_market         :string
      model_name        :string
      product_view      :string
      timestamps
    end
    attr_accessible :path, :cat_id, :product_id, :icecat_updated_at, :quality, :supplier_id,
                    :prod_id, :on_market, :model_name, :product_view, :icecat_product_id

    belongs_to :product, :class_name => "Product"

    # --- Permissions --- #

    def create_permitted?
      acting_user.administrator?
    end

    def update_permitted?
      acting_user.administrator?
    end

    def destroy_permitted?
      acting_user.administrator?
    end

    def view_permitted?(field)
      true
    end

    # --- Class Methods --- #

    def self.import(full: false, date: Date.today)
      if full
        file = File.open(Rails.root.join("vendor","catalogs","files.index.xml"), "r")
      else
        file = File.open(Rails.root.join("vendor","catalogs",date.to_s + "-index.xml"), "r")
      end

      parser = Saxerator.parser(file) do |config|
        config.put_attributes_in_hash!
      end

      # Hewlett Packard has Supplier_id = 1
      parser.for_tag("file").with_attribute("Supplier_id", "1").each do |product|
        metadatum = self.find_or_create_by_icecat_product_id(product["Product_ID"])
        mode = Time.now - metadatum.created_at > 5 ? " updated." : " created."
        if metadatum.update(path:              product["path"],
                           cat_id:            product["Catid"],
                           icecat_product_id: product["Product_ID"],
                           icecat_updated_at: product["Updated"],
                           quality:           product["Quality"],
                           supplier_id:       product["Supplier_id"],
                           prod_id:           product["Prod_ID"],
                           on_market:         product["On_Market"],
                           model_name:        product["Model_Name"],
                           product_view:      product["Product_View"])
          ::JobLogger.info("Metadatum " + product["Prod_ID"].to_s + mode)
        else
          ::JobLogger.error("Metadatum " + product["Prod_ID"].to_s + " could not be saved: " + metadatum.errors.first )
        end
      end
      file.close
    end

    def self.assign_products(only_missing: true)
      if only_missing
        products = Product.without_icecat_metadata
        ::JobLogger.warn(products.count.to_s + " products without metadata.")
      else
        products = Product.all
      end

      products.each do |product|
        metadata = self.where(prod_id: product.icecat_article_number)
        metadata.each do |metadatum|
          if metadatum.update(product_id: product.id)
            ::JobLogger.info("Product " + product.number.to_s + " assigned to " + metadatum.id.to_s)
          else
            ::JobLogger.error("Product " + product.number.to_s + " assigned to " + metadatum.id.to_s)
          end
        end
      end

      products = Product.without_icecat_metadata
      ::JobLogger.warn(products.count.to_s + " products without metadata.")
    end

    def self.download
      metadata = self.where{ product_id != nil }
      metadata.each do |metadatum|
        if metadatum.download
          ::JobLogger.info("XML Metadatum " + metadatum.prod_id.to_s + " downloaded.")
        else
          ::JobLogger.info("XML Metadatum " + metadatum.prod_id.to_s + " exists (no overwrite)!")
        end
      end
    end

    # --- Instance Methods --- #

    def download(overwrite: false)
      unless overwrite
        return false if File.exist?(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml"))
      end
      io = open(Access::BASE_URL + "/" + self.path, Access.open_uri_options).read if self.path
      file = File.new(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml"), "w")
      io.each_line do |line|
        # unpack.pack fixes: Encoding::UndefinedConversionError: "\xC3" from ASCII-8BIT to UTF-8
        file.write line.unpack('U*').pack('U*')
      end
      file.close
      io.close
      return true
    end

    def import
      # :en => lang_id = 1, :de => lang_id = 4
      file = open(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml")).read
      nodeset = Nokogiri::XML(file).xpath("//ICECAT-interface/Product")[0]
      product = self.product

      product.update(title_de: nodeset["Title"],
                     title_en: nodeset["Title"],
                     description_de: nodeset.xpath("//ProductDescription[@langid='4']")[0]["ShortDesc"],
                     description_en: nodeset.xpath("//ProductDescription[@langid='1']")[0]["ShortDesc"],
                     long_description_de: nodeset.xpath("//ProductDescription[@langid='4']")[0]["LongDesc"],
                     long_description_en: nodeset.xpath("//ProductDescription[@langid='1']")[0]["LongDesc"],
                     warranty_de: nodeset.xpath("//ProductDescription[@langid='4']")[0]["WarrantyInfo"],
                     warranty_en: nodeset.xpath("//ProductDescription[@langid='1']")[0]["WarrantyInfo"])

      debugger

      file.close
    end
  end
end