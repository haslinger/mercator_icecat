module ProductExtensions

  extend ActiveSupport::Concern

  included do
    has_many :icecat_metadata, :class_name => "MercatorIcecat::Metadatum",
             foreign_key: :product_id, primary_key: :id, inverse_of: :product

    scope :without_icecat_metadata, -> { includes(:icecat_metadata ).where( icecat_metadata: { product_id: nil } ) }
  end

  # --- Instance Methods --- #

  # FIXME! HAS 20140413 This is highly customer specific
  def icecat_article_number
    self.number =~ /^HP-(.+)$/
    $1 || self.number
  end

  def icecat_vendor
    self.article_number =~ /^HP-(.+)$/
    $1 ? "1" : nil
  end

  def icecat_product_id
    icecat_metadata.first.icecat_product_id if icecat_metadata.any?
  end

  def download_icecat
    metadatum = MercatorIcecat::Metadatum.find_by_product_id(self.id)
    metadatum.download(overwrite: true)
    metadatum.update_product
  end
end