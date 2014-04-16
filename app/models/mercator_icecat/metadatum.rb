# encoding: utf-8

require 'saxerator'
require 'open-uri'
require 'string_extensions'

module MercatorIcecat
  class Metadatum < ActiveRecord::Base

    hobo_model # Don't put anything above this

    fields do
      path              :string
      icecat_updated_at :datetime
      quality           :string
      supplier_id       :string
      icecat_product_id :string, :index => true
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

    def self.download(overwrite: false)
      metadata = self.where{ product_id != nil }
      metadata.each do |metadatum|
        if metadatum.download(overwrite: overwrite)
          ::JobLogger.info("XML Metadatum " + metadatum.prod_id.to_s + " downloaded.")
        else
          ::JobLogger.info("XML Metadatum " + metadatum.prod_id.to_s + " exists (no overwrite)!")
        end
      end
    end

    def self.update_products
      metadata = self.where{ product_id != nil }.order(id: :asc)
      metadata.each do |metadatum|
        metadatum.update_product
      end
    end

    def self.update_product_relations
      metadata = self.where{ product_id != nil }.order(id: :asc)
      metadata.each do |metadatum|
        metadatum.update_product_relations
      end
    end

    def self.import_missing_images
      metadata = self.includes(:product).where{product.id != nil}
                     .where{product.photo_file_name == nil}.references(:product).order(id: :asc)
      metadata.each do |metadatum|
        metadatum.import_missing_image
      end
    end


    # --- Instance Methods --- #

    def download(overwrite: false)
      unless overwrite
        return false if File.exist?(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml"))
      end

      if self.path
        # force_encoding fixes: Encoding::UndefinedConversionError: "\xC3" from ASCII-8BIT to UTF-8
        io = open(Access::BASE_URL + "/" + self.path, Access.open_uri_options).read.force_encoding('UTF-8')
        file = File.new(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml"), "w")
        io.each_line do |line|
          file.write line
        end

        file.close
        return true
      else
        return false
      end
    end

    def update_product
      # :en => lang_id = 1, :de => lang_id = 4
      file = open(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml")).read
      product_nodeset = Nokogiri::XML(file).xpath("//ICECAT-interface/Product")[0]
      product = self.product

      description_de = try_to { product_nodeset.xpath("ProductDescription[@langid='4']")[0]["ShortDesc"].fix_utf8 }
      description_en = try_to { product_nodeset.xpath("ProductDescription[@langid='1']")[0]["ShortDesc"].fix_utf8 }
      long_description_de = try_to { product_nodeset.xpath("ProductDescription[@langid='4']")[0]["LongDesc"].fix_utf8 }
      long_description_en = try_to { product_nodeset.xpath("ProductDescription[@langid='1']")[0]["LongDesc"].fix_utf8 }
      warranty_de = try_to { product_nodeset.xpath("ProductDescription[@langid='4']")[0]["WarrantyInfo"].fix_utf8 }
      warranty_en = try_to { product_nodeset.xpath("ProductDescription[@langid='1']")[0]["WarrantyInfo"].fix_utf8 }

      product.update(# title_de: product_nodeset["Title"],
                     # title_en: product_nodeset["Title"],
                     description_de: description_de,
                     description_en: description_en,
                     long_description_de: long_description_de,
                     long_description_en: long_description_en,
                     warranty_de: warranty_de,
                     warranty_en: warranty_en)

      property_groups_nodeset = product_nodeset.xpath("CategoryFeatureGroup")
      property_groups_nodeset.each do |property_group_nodeset|
        icecat_id = property_group_nodeset["ID"]
        name_en = try_to { property_group_nodeset.xpath("FeatureGroup/Name[@langid='1']")[0]["Value"].fix_utf8 }
        name_de = try_to { property_group_nodeset.xpath("FeatureGroup/Name[@langid='4']")[0]["Value"].fix_utf8 }
        name_de ||= name_en # English, if German not available
        name_de ||= try_to { property_group_nodeset.xpath("FeatureGroup/Name")[0]["Value"].fix_utf8 }
                    # anything if neither German nor English available

        property_group = ::PropertyGroup.find_by_icecat_id(icecat_id)
        unless property_group
          property_group = ::PropertyGroup.new(icecat_id: icecat_id,
                                               name_de: name_de,
                                               name_en: name_en,
                                               position: icecat_id) # no better idea ...
          if property_group.save
            ::JobLogger.info("PropertyGroup " + icecat_id.to_s + " created.")
          else
            ::JobLogger.error("PropertyGroup " + icecat_id.to_s + " could not be created: " + property_group.errors.first.to_s)
          end
        end
      end

      product.values.destroy_all

      features_nodeset = product_nodeset.xpath("ProductFeature")
      features_nodeset.each do |feature|
        # icecat_presentation_value = feature.xpath("Presentation_Value") # not used here
        icecat_feature_id = feature.xpath("Feature")[0]["ID"].to_i
        icecat_value = feature["Value"]
        icecat_feature_group_id = feature["CategoryFeatureGroup_ID"]

        name_en = try_to { feature.xpath("Feature/Name[@langid='1']")[0]["Value"].fix_utf8 }
        name_de = try_to { feature.xpath("Feature/Name[@langid='4']")[0]["Value"].fix_utf8 }
        name_de ||= name_en # English, if German not available
        name_de ||= try_to { feature.xpath("Feature/Name")[0]["Value"].fix_utf8 } # anything if neither German nor English available

        unit_en = try_to { feature.xpath("Feature/Measure/Signs/Sign[@langid='1']")[0].content.fix_utf8 }
        unit_de = try_to { feature.xpath("Feature/Measure/Signs/Sign[@langid='4']")[0].content.fix_utf8 }
        unit_de ||= unit_en # English, if German not available
        unit_de ||= try_to { feature.xpath("Feature/Measure/Signs/Sign")[0].content.fix_utf8 }
                    # anything if neither German nor English available

        property_group = PropertyGroup.find_by_icecat_id(icecat_feature_group_id)

        property = Property.where(icecat_id: icecat_feature_id).first
        unless property
          property = Property.new(icecat_id: icecat_feature_id,
                                  position: icecat_feature_id,
                                  name_de: name_de,
                                  name_en: name_en,
                                  datatype: icecat_value.icecat_datatype)
          if property.save
            ::JobLogger.info("Property " + property.id.to_s + " saved.")
          else
            ::JobLogger.error("Property could not be saved:" + property.errors.first.to_s)
          end
        end

        value = Value.where(property_group_id: property_group.id, property_id: property.id,
                            product_id: product.id, state: icecat_value.icecat_datatype).first
        unless value
          value = Value.new(property_group_id: property_group.id, property_id: property.id, product_id: product.id)
          value.state = icecat_value.icecat_datatype
        end

        if icecat_value.icecat_datatype == "flag"
          value.flag = ( icecat_value == "Y" )
        end

        if icecat_value.icecat_datatype == "numeric"
          value.amount = icecat_value.to_f
          value.unit_de = try_to { unit_de.fix_utf8 }
          value.unit_en = try_to { unit_en.fix_utf8 }
        end

        if icecat_value.icecat_datatype == "textual"
          value.title_de = try_to { icecat_value.truncate(252).fix_utf8 }
          value.title_en = try_to { icecat_value.truncate(252).fix_utf8 }
          value.unit_de = try_to { unit_de.fix_utf8 }
          value.unit_en = try_to { unit_en.fix_utf8 }
        end

        if value.save
          ::JobLogger.info("Value " + value.id.to_s + " saved.")
        else
          ::JobLogger.error("Value could not be saved:" + value.errors.first)
        end
      end

      ::JobLogger.info("=== Metadatum " + id.to_s + " updated Product " + product_id.to_s + " ===")
    end

    def delete_relations
      product = self.product
      relations_count = product.productrelations.count
      product.productrelations.destroy_all
      supplies_count = product.supplyrelations.count
      product.supplyrelations.destroy_all
      ::JobLogger.info(relations_count.to_s + " Productrel., " +
                       supplies_count.to_s + " Supplyrel. deleted for Product " + product.id.to_s +
                       " Metadatum " + self.id.to_s)
    end

    def update_product_relations
      file = open(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml")).read
      product_nodeset = Nokogiri::XML(file).xpath("//ICECAT-interface/Product")[0]
      product = self.product
      cat_id = self.cat_id

      self.delete_relations

      unknown_products = 0
      icecat_ids = []
      product_nodeset.xpath("ProductRelated").each do |relation|
        icecat_ids << try_to { relation.xpath("Product")[0]["ID"].to_i }
      end

      related_metadata = Metadatum.where(icecat_product_id: icecat_ids)
      related_metadata.each do |related_metadatum|
        related_product_id = try_to { related_metadatum.product_id.to_i }

        if related_product_id > 0
          if related_metadatum.cat_id == cat_id
            product.productrelations.new(related_product_id: related_product_id)
          else
            product.supplyrelations.new(supply_id: related_product_id)
          end
        else
          unknown_products += 1
        end
      end

      if product.save(validate: false) # FIXME!: This time without validations ...
        ::JobLogger.info("Product " + product.id.to_s + ": " +
                         product.productrelations.count.to_s + " Productrel. " +
                         product.supplyrelations.count.to_s + ", Supplyrel. created, " +
                         unknown_products.to_s + " unknown.")
      else
        ::JobLogger.error("Product " + product.id.to_s + " could not be updated")
      end
    end

    def import_missing_image
      file = open(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml")).read
      product_nodeset = Nokogiri::XML(file).xpath("//ICECAT-interface/Product")[0]

      product = self.product
      return nil if product.photo_file_name # no overwriting intended

      path = product_nodeset["HighPic"]

      begin
        io = StringIO.new(open(path, Access.open_uri_options).read)
        io.class.class_eval { attr_accessor :original_filename }
        io.original_filename = path.split("/").last

        product.photo = io

        if product.save(validate: false) # FIXME!: This time without validations ...
          ::JobLogger.info("Image  " + path.split("/").last + " for Product " + product.id.to_s + " saved." )
        else
          ::JobLogger.error("Image  " + path.split("/").last + " for Product " + product.id.to_s + " could not be saved!" )
        end
      rescue Exception => e
        ::JobLogger.warn("Image  " + path + " could not be loaded!" )
        ::JobLogger.warn(e)
      end
    end

  end
end