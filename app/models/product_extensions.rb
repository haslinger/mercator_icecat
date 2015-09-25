module ProductExtensions

  extend ActiveSupport::Concern

  included do
    has_many :icecat_metadata, :class_name => "MercatorIcecat::Metadatum",
             foreign_key: :product_id, primary_key: :id, inverse_of: :product

    scope :without_icecat_metadata, -> { includes(:icecat_metadata ).where( icecat_metadata: { product_id: nil } ) }


    def self.update_from_icecat(from_today: true, only_missing: false)
      if only_missing
        @products = Product.includes(:values).where( :values => { :product_id => nil } )
        # puts "Updating " + @products.count.to_s + " products without values ..."
      else
        @products = Product.all
      end

      @products.each_with_index do |product, index|
        # puts "Number: " + index.to_s
        product.update_from_icecat(from_today: from_today)
      end
    end
  end


  # --- Instance Methods --- #

  def icecat_article_number
    if self.alternative_number.present?
      return self.alternative_number
    elsif
      # HAS 20140413 This is HP-specific
      self.number =~ /^HP-(.+)$/
      $1
    else
      self.number
    end
  end


  def icecat_vendor
    # HAS 20140413 This is HP-specific
    self.number =~ /^HP-(.+)$/ || self.alternative_number =~ /^HP-(.+)$/
    $1 ? "1" : nil
  end


  def icecat_product_id
    icecat_metadata.first.icecat_product_id if icecat_metadata.any?
  end


  def update_from_icecat(from_today: true, initial_import: false)
    @metadatum = MercatorIcecat::Metadatum.find_by_prod_id(self.icecat_article_number)
    return unless @metadatum

    if from_today
      return unless @metadatum.updated_at > Time.now - 1.day
    end

#    puts "Download " + number + " from Icecat."
    @metadatum.download(overwrite: true)
#    puts "Updating product relations."
    @metadatum.update_product(product: self,
                              initial_import: initial_import)
#    puts "Updating product."
    @metadatum.update_product_relations(product: self)

    @metadatum.import_missing_image(product: self) unless self.photo_file_name
    return true #Just to see, if we are done
  end
end