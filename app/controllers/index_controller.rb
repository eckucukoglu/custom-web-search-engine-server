class IndexController < ApplicationController

	def index
		@collections = Collections.all
	end

	def new_collection
		@collection = Collections.new
	end

	def save_collection
		command = "java -classpath #{Rails.root}/java/custom-wse.jar wse.CreateCorpus -url " + params[:collections][:seed_url] + " -depth " + params[:collections][:max_depth] + " -pages " + params[:collections][:max_pages]
		output = `#{command}`

		latest_log_file_saved = Dir.glob("/home/arcelik/git/custom_web_search_engine_server/data/logs/*.log").max_by {|f| File.mtime(f)}
		collection_id = latest_log_file_saved.split("/logs/")[1].split(".")[0].to_i
		number_of_pages_retrieved = Dir["/home/arcelik/git/custom_web_search_engine_server/data/collections/"+ collection_id.to_s + "/*"].length
		
		collection = Collections.new(collection_params)
		collection.save()
		collection.update_attribute(:no_of_pages_retrieved, number_of_pages_retrieved)
		collection.update_attribute(:collection_id,collection_id)

		map_file = File.open("/home/arcelik/git/custom_web_search_engine_server/data/logs/" + collection_id.to_s + ".url.map").read
		map_file = map_file.split("\n")
		map_file.each do |line|
			line = line.split("\t")
			document_url_map = DocumentUrlMaps.new(:collection_id => collection_id, :document_id => line[0].to_i, :url => line[1])
			document_url_map.save
		end
		redirect_to root_path
	end

	def search_query
		@query = params[:query]
		collection_id = Collections.find_by_id(params[:collection_id_field].to_i).collection_id
		@results = []
		if not params[:mmr]
			if params[:wand]
				command = "java -classpath #{Rails.root}/java/custom-wse.jar wse.SearchQuery -query " + params[:query] + " -cid " + collection_id.to_s + " -w"
			else
				command = "java -classpath #{Rails.root}/java/custom-wse.jar wse.SearchQuery -query " + params[:query] + " -cid " + collection_id.to_s
			end
			output = `#{command}`
			output.split(" ").each do |o|
				doc_url_map = DocumentUrlMaps.where(:collection_id => collection_id,:document_id=>o.to_i)
				@results.push(doc_url_map.first.url)
			end
		else
			if params[:wand]
				command = "java -classpath #{Rails.root}/java/custom-wse.jar wse.SearchQuery -query " + params[:query] + " -cid " + collection_id.to_s + " -k 20 -w"
			else
				command = "java -classpath #{Rails.root}/java/custom-wse.jar wse.SearchQuery -query " + params[:query] + " -cid " + collection_id.to_s + " -k 20"
			end
			output = `#{command}`

			mmr_input_directory_name = "#{Rails.root}/data/mmr_input"
			Dir.mkdir(mmr_input_directory_name) unless File.exists?(mmr_input_directory_name)
			mmr_output_directory_name = "#{Rails.root}/data/mmr_output"
			Dir.mkdir(mmr_output_directory_name) unless File.exists?(mmr_output_directory_name)
			
			output.split(" ").each do |in_res|
				file_name = "#{Rails.root}/data/collections/" + collection_id.to_s + "/" + in_res
				# puts file_name
				FileUtils.cp file_name, mmr_input_directory_name
			end

			Dir.chdir "#{Rails.root}/java/mmr/"
			command = "#{Rails.root}/java/mmr/./run TestDiversity " + mmr_input_directory_name + " " + mmr_output_directory_name + " '" + params[:query] + "'"
			output = `#{command}`
			Dir.chdir "#{Rails.root}"
			FileUtils.rm_r mmr_input_directory_name
			FileUtils.rm_r mmr_output_directory_name
			output.split("\n").each do |o|
				doc_url_map = DocumentUrlMaps.where(:collection_id => collection_id,:document_id=>o.to_i)
				@results.push(doc_url_map.first.url)
			end

			# /home/arcelik/git/custom_web_search_engine_server/java/mmr/./run TestDiversity 
			# /home/arcelik/git/custom_web_search_engine_server/data/directory_for_mmr 
			# /home/arcelik/git/custom_web_search_engine_server/data/directory_for_mmr_results/ 'solay system'


			# @results = initial_results

		end
	end

	private
	def collection_params
		params.require(:collections).permit(:seed_url, :max_depth, :max_pages)
	end
end
