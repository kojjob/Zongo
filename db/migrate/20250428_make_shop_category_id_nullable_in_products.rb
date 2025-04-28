class MakeShopCategoryIdNullableInProducts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :products, :shop_category_id, true
  end
end
