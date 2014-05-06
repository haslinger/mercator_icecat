require 'spec_helper'

describe MercatorIcecat::Metadatum do
  it "is valid with path, icecat_updated_at, quality, supplier_id,
      icecat_product_id, prod_id, product_number, cat_id, on_market, model_name,
      product_view, product" do
    expect(build(:metadatum)).to be_valid
  end

  it {should belong_to(:product)}
end