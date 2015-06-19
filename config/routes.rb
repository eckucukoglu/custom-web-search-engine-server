Rails.application.routes.draw do
	root 'index#index'

	match '/new_collection',						to: 'index#new_collection',			  	via: 'get'
	match '/save_collection',						to: 'index#save_collection',		  	via: 'post'
	match '/search_query',						    to: 'index#search_query',		  		via: 'post'
end
