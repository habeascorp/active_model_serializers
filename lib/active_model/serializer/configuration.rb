module ActiveModel
  class Serializer
    module Configuration
      include ActiveSupport::Configurable
      extend ActiveSupport::Concern

      included do |base|
        base.config.array_serializer = ActiveModel::Serializer::ArraySerializer
        base.config.adapter = :attributes
        base.config.jsonapi_resource_type = :plural
        base.config.sideload_associations = false
      end
    end
  end
end
