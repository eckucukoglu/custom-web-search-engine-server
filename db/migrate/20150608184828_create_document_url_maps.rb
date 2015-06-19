class CreateDocumentUrlMaps < ActiveRecord::Migration
	def change
		create_table :document_url_maps do |t|
			t.integer :collection_id
			t.integer :document_id
			t.text :url
			t.timestamps
		end
	end
end
