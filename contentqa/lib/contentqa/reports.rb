require 'v1/repository'
require 'fileutils'

module Contentqa

  module Reports
    @dashboard_db = V1::Repository.database(V1::Repository.cluster_endpoint('reader', 'dashboard'))
    @dpla_db = V1::Repository.database(V1::Repository.cluster_endpoint('reader', 'dpla'))
    @base_path = File.expand_path("../../../../tmp/qa_reports", __FILE__)
    FileUtils.mkpath(@base_path) unless File.directory?(@base_path)

    def self.all_created?(id)
      path = File.expand_path(File.join(@base_path, id))
      count = Dir[File.join(path, '**', '*')].count {|file| File.file?(file) && !file.ends_with?(".zip") }
      
      if id =~ /global/
        count == find_report_types('global').length
      else
        count == find_report_types('provider').length
      end
    end

    # Get the document describing an ingest from the dashboard database
    def self.find_ingest(id)
      @dashboard_db.get(id)
    end

    # Get the list of available reports (defined as the qa_reports views in the dpla database)
    def self.find_report_types(type=nil)
      keys = @dpla_db.get('_design/qa_reports')['views'].keys.sort

      keys = keys.inject([]) do |memo, type|
        memo.push(type, type + '_count', type + '_count_global')
        memo
      end

      if type == "provider"
        keys.select{|k| k !~ /global/}
      elsif type == "global"
        keys.select{|k| k =~ /global/}
      else
        keys
      end
    end

    # Get the list of providers for whom data has been ingested
    def self.find_providers
      @dashboard_db.view('all_ingestion_docs/by_provider_name', {:include_docs => true})['rows']
    end

    # Find the list containing the most recent ingest for each provider
    def self.find_last_ingests
      output = []
      last = nil
      sorted = self.find_providers.sort do |x,y|
        x['key'] == y['key'] ? y['value'] <=> x['value'] : x['key'] <=> y['key']
      end
      sorted.each do |a|
        output << a if a['key'] != last
        last = a['key']
      end
      output
    end

    # Get the sum of the all ingestion sequences
    def self.get_global_reports_id
      sum = find_last_ingests.map {|k| k["doc"]["ingestionSequence"]}.sum
      "global_#{sum}"
    end

    # Get a File::Stat object for the report if it has been generated
    def self.get_report(id, view)
      path = report_path id, view
      File.stat(path) if (path && File.exists?(path))
    end

    def self.is_safe_path?(path)
      path.match Regexp.new('^' + Regexp.escape(@base_path))
    end
    
    # Get the path on disk where report would exists. Reports are organized by ingestion document id and report name
    def self.report_path(id, view)
      path = File.expand_path(File.join(@base_path, id, view))
      path if (is_safe_path?(path) && find_report_types.include?(view))
    end

    # Get the path to the zip containing all reports
    def self.all_reports_path(id)
      if id =~ /global/
        provider = "global"
      else
        provider = find_ingest(id)['provider']
      end
      path = File.expand_path(File.join(@base_path, id, "#{provider}.zip"))
      path if is_safe_path?(path)
    end

    # Filter dpla_db request result for provider report
    def self.filter(result, view)
      provider_result = {}

      result['rows'].each do |row|
        if is_group_view?(view)
          # Remove the provider from the row key if it's a compound key
          key = row['key'].kind_of?(Array) ? row['key'].last : row['key']
          value = row['value']
          provider_result[key] = value 
        else
          key = row['key'].last
          value = row['key'][-2]
          provider_result[key] = value 
        end   
      end
      provider_result
    end

    # Aggregate dpla_db request result for global report
    def self.aggregate(result) 
      global_result = {}
      global_result.default = 0

      result['rows'].each do |row|
        key = row['key'].last
        value = row['value'].to_i
        global_result[key] += value
      end

      global_result
    end

    # Convert one key/value JSON response pair into a line for a CSV file
    def self.csvify(key, value)
      "\"#{key}\",\"#{value.to_s}\"\n"
    end

    # Temporary file location while downloading
    def self.download_path(path)
      path + ".downloading"
    end

    def self.is_group_view?(view_name)
      view_name =~ /_count/
    end

    def self.is_global_view?(view_name)
      view_name =~ /_global/
    end

    # Create a report
    def self.create_report(id, view)
      path = report_path id, view
      if path 
        FileUtils.mkpath File.dirname(path) unless File.exists? File.dirname(path)

        result = request_result(id, view)
 
        File.open(download_path(path), "w") do |f|
          result.each do |key, value| 
            f << csvify(key, value)  
          end
        end
        
        FileUtils.mv download_path(path), path
      end

    end

    # Compress all files in a path
    def self.compress(path, archive)
      FileUtils.chdir(path)
      `zip #{archive} *`
    end

    # Get zipped reports
    def self.get_zipped_reports(id, provider)
      path = File.expand_path(File.join(@base_path, id))
      archive = "#{provider}.zip"
      archive_path = File.expand_path(File.join(path, archive))
      
      if !File.exists?(archive_path) || !File.stat(archive_path)
        compress(path, archive)
      end

      File.stat(archive_path)
    end

    def self.ingestion_running?
      @dashboard_db.view("all_ingestion_docs/for_active_ingestions")["total_rows"] > 0
    end

    # Returns a hash of options for a @dpla_db.view request
    def self.request_options(id, view)
      options = {}
      if !is_global_view?(view)
        provider = find_ingest(id)['provider']
        options = {:startkey => [provider, "_"], :endkey => [provider, "Z"]}
      end

      if is_group_view?(view)
        options[:group_level] = "2"
      else
        options[:reduce] = false
      end

      options
    end

    # Returns a qa report view name for a @dpla_db.view request
    def self.request_view_name(view)
      design_view = view.gsub(/_global$/,"").gsub(/_count$/,"")
      "qa_reports/#{design_view}"
    end
    
    def self.request_result(id, view)
      view_name = request_view_name(view)
      options = request_options(id, view)
      result = @dpla_db.view(view_name, options)

      if is_global_view?(view)
        aggregate(result)
      else
        filter(result, view)
      end
    end

  end

end
