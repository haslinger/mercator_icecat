# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :metadatum, :class => 'MercatorIcecat::Metadatum' do
    path              "export/freexml.int/INT/20879456.xml"
    icecat_updated_at "2014-03-26 12:11:12"
    quality           "ICECAT"
    supplier_id       1
    icecat_product_id 20879456
    prod_id           "F0Z52EA"
    product_number    "255 G2"
    cat_id            151
    on_market         1
    model_name        "255 G2"
    product_view      132
    product
  end
end
