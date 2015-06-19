class CreateCollections < ActiveRecord::Migration
	def change
		create_table :collections do |t|
			t.text :seed_url
			t.integer :max_depth
			t.integer :max_pages
			t.integer :no_of_pages_retrieved
			t.timestamps
		end
	end
end
