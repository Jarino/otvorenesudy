module Probe
  module Index
    extend ActiveSupport::Concern

    included do
      include Tire::Model::Search
      include Tire::Model::Callbacks

      settings
    end

    module ClassMethods
      include Probe::Helpers::Index

      def config
        Probe::Configuration
      end

      def settings(params = {})
        settings = config.index

        settings.deep_merge!(params)

        tire.settings.deep_merge!(settings)
      end

      def mapping
        unless block_given?
          return @mapping
        else
          @mapping      = Hash.new
          @sort_fields  = Array.new

          yield

          tire.mapping do
            @mapping.each do |field, value|
              options  = value[:options]

              type     = options[:type]     || :string
              analyzer = options[:analyzer] || 'text_analyzer'

              case value[:type]
              when :mapped
                indexes field, options.merge!(index: :not_analyzed)
              when :analyzed
                indexes field, options.deep_merge!(
                  type:   :multi_field,
                  fields: {
                    analyzed:  { type: type,  analyzer: analyzer },
                    untouched: { type: type,  index: :not_analyzed }
                  }
                )
              when :nested
                indexes field, type: :nested, &value[:block]
              end
            end
          end
        end
      end

      def facets
        @facet_definitions ||= []

        yield if block_given?

        @facets ||= Probe::Facets.new(@facet_definitions)
      end

      private

      def map(field, options = {})
        @mapping[field] = {}

        @mapping[field][:type]    = :mapped
        @mapping[field][:options] = options
      end

      def analyze(field, options = {})
        @mapping[field] = {}

        @mapping[field][:type]    = :analyzed
        @mapping[field][:options] = options
      end

      def nested(field, options = {}, &block)
        @mapping[field] = {}

        @mapping[field][:type]    = :nested
        @mapping[field][:options] = options
        @mapping[field][:block]   = block
      end

      def facet(name, options = {})
        type = options[:type]

        field = options[:field] || name

        options.merge! base: self

        @facet_definitions << create_facet(type, name, field, options)
      end

      def sort_by(*args)
        @sort_fields = *args
      end
    end
  end
end