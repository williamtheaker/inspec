# Unlike a normal cli_command plugin (which defines a cli cubcommand group)
# we want to define a top-level command. So we re-open the CLI class and
# define a method there.

# This is shenanigans.

require "inspec/base_cli"

module Inspec
  class InspecCLI < Inspec::BaseCLI
    desc "suggest [SET] [OPTIONS]", "Recommends which profiles should be run on the target system"

    option :target, aliases: :t, type: :string,
      desc: "Simple targeting option using URIs, e.g. ssh://user:pass@host:port"
    option :reporter, type: :array,
      banner: "suggest-progress suggest-text",
      desc: "Enable one or more output reporters: suggest-progress, suggest-debug, suggest-text"

    def suggest(*requested_sets)
      # TODO: allow cfg path to be overridden
      cfg = YAML.load_file(File.join(Inspec.src_root, "etc", "suggest.yaml"))

      # Get list of sets
      set_names = cfg["sets"].map { |s| s["name"] }
      if requested_sets.empty?
        # Do all
        requested_sets = set_names
      else
        requested_sets.each do |set_name|
          unless set_names.include?(set_name)
            ui.error("Set name '#{set_name}' is not recognized. Known set names: #{set_names.join(", ")}")
            ui.exit(:usage_error)
          end
        end
      end

      # TODO: consider signed profiles
      profiles = requested_sets.map { |s| File.join(Inspec.src_root, "etc", "suggest", s) }

      exec_args = []
      exec_args << ["-t", options[:target]] if options[:target]
      exec_args << ["--reporter", options[:reporter] ? options[:reporter] : ["suggest-progress", "suggest-text"]]

      arguments = ["exec", profiles, exec_args].flatten
      Inspec::InspecCLI.start(arguments, enforce_license: true)
    end
  end
end