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

        model_name = product["Model_Name"].fix_utf8 if product["Model_Name"].present?
        metadatum.update(path:              product["path"],
                         cat_id:            product["Catid"],
                         icecat_product_id: product["Product_ID"],
                         icecat_updated_at: product["Updated"],
                         quality:           product["Quality"],
                         supplier_id:       product["Supplier_id"],
                         prod_id:           product["Prod_ID"],
                         on_market:         product["On_Market"],
                         model_name:        model_name,
                         product_view:      product["Product_View"]) or
          ::JobLogger.error("Metadatum " + product["Prod_ID"].to_s + " could not be saved: " + metadatum.errors.first )
      end
      file.close
    end

    def self.assign_products(only_missing: true)
      if only_missing
        products = Product.without_icecat_metadata
      else
        products = Product.all
      end

      products.each do |product|
        metadata = self.where(prod_id: product.icecat_article_number)
        metadata.each_with_index do |metadatum, index|
          metadatum.update(product_id: product.id) or ::JobLogger.error("Product " + product.number.to_s + " assigned to " + metadatum.id.to_s)
        end
      end
    end

    def self.download(overwrite: false, from_today: true)
      if from_today
        metadata = self.where{ (product_id != nil) & (updated_at > my{Time.now - 1.day})}
      else
        metadata = self.where{ product_id != nil }
      end

      amount = metadata.count
      metadata.each_with_index do |metadatum, index|
        metadatum.download(overwrite: overwrite) or ::JobLogger.info("XML Metadatum " + metadatum.prod_id.to_s + " exists (no overwrite)!")
      end
    end

    def self.update_products(from_today: true)
      metadata_who_lost_their_products = self.where{ product_id != nil }.where.not(product_id: Product.pluck("id"))
      metadata_who_lost_their_products.update_all(product_id: nil) or ::JobLogger.error("Metadata who lost teir products cannot be updated!")

      if from_today
        @yesterday = Time.now - 1.day
        metadata = self.where{ (product_id != nil) & (updated_at > my{@yesterday})}.order(id: :asc)
      else
        metadata = self.where{ product_id != nil }.order(id: :asc)
      end

      # if-clause is handy for resume after dump
      metadata.each{|metadatum| metadatum.update_product } # if metadatum.id >= 109279 }
    end

    def self.update_product_relations(from_today: true)
      if from_today
        metadata = self.where{ (product_id != nil) & (updated_at > my{Time.now - 1.day})}.order(id: :asc)
      else
        metadata = self.where{ product_id != nil }.order(id: :asc)
      end

      metadata.each{|metadatum| metadatum.update_product_relations}
    end

    def self.import_missing_images
      metadata = self.includes(:product).where{product.id != nil}
                     .where{product.photo_file_name == nil}
                     .references(:product)
                     .order(id: :asc)
      metadata.each{|metadatum| metadatum.import_missing_image }
    end


    # --- Instance Methods --- #

    def download(overwrite: false)
      if File.exist?(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml"))
        return false unless overwrite
      end

      self.path or return false

      # force_encoding fixes: Encoding::UndefinedConversionError: "\xC3" from ASCII-8BIT to UTF-8
      begin
        io = open(Access::BASE_URL + "/" + self.path, Access.open_uri_options).read.force_encoding('UTF-8')
        file = File.new(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml"), "w")
        io.each_line{|line| file.write line}
        file.close
        return true
      rescue
        ::JobLogger.error("Download error: " + Access::BASE_URL + "/" + self.path)
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

        property_group = ::PropertyGroup.find_by(icecat_id: icecat_id)
        unless property_group
          property_group = ::PropertyGroup.new(icecat_id: icecat_id,
                                               name_de: name_de,
                                               name_en: name_en,
                                               position: icecat_id) # no better idea ...
          property_group.save or ::JobLogger.error("PropertyGroup " + icecat_id.to_s + " could not be created: " + property_group.errors.first.to_s)
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

        property_group = PropertyGroup.find_by(icecat_id: icecat_feature_group_id)

        property = Property.find_by(icecat_id: icecat_feature_id)
        unless property
          property = Property.new(icecat_id: icecat_feature_id,
                                  position: icecat_feature_id,
                                  name_de: name_de,
                                  name_en: name_en,
                                  datatype: icecat_value.icecat_datatype)
          property.save or ::JobLogger.error("Property could not be saved:" + property.errors.first.to_s)
        end

        value = Value.find_by(property_group_id: property_group.id,
                              property_id: property.id,
                              product_id: product.id,
                              state: icecat_value.icecat_datatype)
        unless value
          value = Value.new(property_group_id: property_group.id,
                            property_id: property.id,
                            product_id: product.id)
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

        value.save or ::JobLogger.error("Value could not be saved:" + value.errors.first)
      end
    end

    def update_product_relations
      file = open(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml")).read
      product_nodeset = Nokogiri::XML(file).xpath("//ICECAT-interface/Product")[0]

      product = self.product
      product.productrelations.destroy_all
      product.supplyrelations.destroy_all

      icecat_ids = []
      product_nodeset.xpath("ProductRelated").each do |relation|
        icecat_ids << try_to { relation.xpath("Product")[0]["ID"].to_i }
      end

      related_metadata = Metadatum.where(icecat_product_id: icecat_ids)
      related_metadata.each do |related_metadatum|
        related_product_id = try_to { related_metadatum.product_id.to_i }

        if related_product_id > 0
          if related_metadatum.cat_id == self.cat_id
            product.productrelations.new(related_product_id: related_product_id)
          else
            product.supplyrelations.new(supply_id: related_product_id)
          end
        end
      end

      product.save(validate: false) or ::JobLogger.error("Product " + product.id.to_s + " could not be updated")
    end

    def import_missing_image
      file = open(Rails.root.join("vendor","xml",icecat_product_id.to_s + ".xml")).read
      product_nodeset = Nokogiri::XML(file).xpath("//ICECAT-interface/Product")[0]

      product = self.product
      return nil if product.photo_file_name # no overwriting intended

      path = product_nodeset["HighPic"]
      return nil if path.empty? # no image available

      begin
        io = StringIO.new(open(path, Access.open_uri_options).read)
        io.class.class_eval { attr_accessor :original_filename }
        io.original_filename = path.split("/").last

        product.photo = io
        product.save(validate: false) or ::JobLogger.error("Image  " + path.split("/").last + " for Product " + product.id.to_s + " could not be saved!" )
      rescue Exception => e
        ::JobLogger.warn("Image  " + path + " could not be loaded!" )
        ::JobLogger.warn(e)
      end
    end
  end
end