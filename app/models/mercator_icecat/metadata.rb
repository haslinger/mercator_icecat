require 'saxerator'

module MercatorIcecat
  class Metadata < ActiveRecord::Base

    hobo_model # Don't put anything above this

    fields do
      path              :string
      icecat_updated_at :datetime
      quality           :string
      supplier_id       :string
      icecat_product_id :string
      prod_id           :string
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
        metadata = self.find_or_create_by_icecat_product_id(product["Product_ID"])
        mode = Time.now - metadata.created_at > 5 ? " updated." : " created."
        if metadata.update(path:              product["path"],
                           cat_id:            product["Catid"],
                           icecat_product_id: product["Product_ID"],
                           icecat_updated_at: product["Updated"],
                           quality:           product["Quality"],
                           supplier_id:       product["Supplier_id"],
                           prod_id:           product["Prod_ID"],
                           on_market:         product["On_Market"],
                           model_name:        product["Model_Name"],
                           product_view:      product["Product_View"])
          ::JobLogger.info("Metadata " + product["Prod_ID"].to_s + mode)
        else
          ::JobLogger.error("Metadata " + product["Prod_ID"].to_s + " could not be saved: " + metadata.errors.first )
        end
      end
      file.close
    end
  end
end