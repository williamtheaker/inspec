require "inspec/secrets/yaml"
require "inspec/utils/waivers/csv_file_reader"
require "inspec/utils/waivers/json_file_reader"

module Inspec
  class WaiverFileReader

    def self.fetch_waivers_by_profile(profile_id, files)
      read_waivers_from_file(profile_id, files) if @waivers_data.nil? || @waivers_data[profile_id].nil?
      @waivers_data[profile_id]
    end

    def self.read_waivers_from_file(profile_id, files)
      @waivers_data ||= {}
      output = {}

      files.each do |file_path|
        data = read_from_file(file_path)
        output.merge!(data) if !data.nil? && data.is_a?(Hash)

        if data.nil?
          raise Inspec::Exceptions::WaiversFileNotReadable,
              "Cannot find parser for waivers file." \
              "Check to make sure file has the appropriate extension."
        end
      rescue Inspec::Exceptions::WaiversFileNotReadable, Inspec::Exceptions::WaiversFileInvalidFormatting => e
        Inspec::Log.error "Error reading waivers file #{file_path}.#{e.message}"
        Inspec::UI.new.exit(:usage_error)
      end

      @waivers_data[profile_id] = output
    end

    def self.read_from_file(file_path)
      data = nil
      file_extension = File.extname(file_path)
      if [".yaml", ".yml"].include? file_extension
        data = Secrets::YAML.resolve(file_path)
        data = data.inputs unless data.nil?
        validate_json_yaml(data)
      elsif file_extension == ".csv"
        data = Waivers::CSVFileReader.resolve(file_path)
        headers = Waivers::CSVFileReader.headers
        validate_headers(headers)
      elsif file_extension == ".json"
        data = Waivers::JSONFileReader.resolve(file_path)
        validate_json_yaml(data) unless data.nil?
      end
      data
    end

    def self.all_fields
      %w{control_id justification expiration_date run}
    end

    def self.validate_headers(headers, json_yaml = false)
      required_fields = json_yaml ? %w{justification} : %w{control_id justification}

      # In case of invalid headers raise error to provide valid waiver file.
      unless (required_fields - headers).empty?
        raise Inspec::Exceptions::WaiversFileInvalidFormatting,
            "\n Missing required parameters: #{required_fields}.\n Valid parameters are #{all_fields}."
      end
      Inspec::Log.warn "Invalid column headers: Column can't be nil" if (headers.include? nil) && !json_yaml
      Inspec::Log.warn "Extra parameters: #{(headers - all_fields)}" unless (headers - all_fields).empty?
    end

    def self.validate_json_yaml(data)
      headers = []
      data.each_value do |value|
        # In case of yaml or json we need to validate headers/parametes for each value
        validate_headers(value.keys, true)
        headers.push value.keys
      end
    end
  end
end