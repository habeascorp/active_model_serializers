module ActiveModel
  class Serializer
    module Adapter
      class FlatJson < Attributes
        attr_accessor :_flattened

        def serializable_hash(options = nil)
          hash = { root => super(options) }
          self._flattened = {}
          flatten(hash)
          singularize_lone_objects

          _flattened
        end

        #
        def flatten(root)
          root.each_with_object({}) do |(key, item), hash|
            if item.is_a?(Array)
              new_key = ids_name_for(key)
              hash[new_key] = item.map do |i|
                add(key, flatten(i))
                i[:id]
              end
            elsif item.is_a?(Hash)
              new_key = id_name_for(key)
              add(key, flatten(item))
              hash[new_key] = item[:id]
            else
              hash[key] = item
            end
          end
        end

        # @note _flatten[key] will always be an array
        #
        # @param [Symbol] key the type of data
        # @param [Object] data model must have id field
        def add(key, data)
          return if include?(data, key)
          # make array - if there ends up only being one of this kind
          # object, it will be un-arrayed later in singularize_lone_objects
          # if this array only contains one object
          _flattened[key] ||= []
          # make sure that we aren't adding the same object with different data
          old = _flattened[key].find { |i| i[:id] == data[:id] }
          # if data is the 'same' as old, merge
          # - new object will have additional associations
          #  (list of ids for each relationship)
          if old
            _flattened[key].delete(old)
            data = old.merge(data)
          end

          _flattened[key] << data
        end

        def ids_name_for(name)
          id_name_for(name).to_s.pluralize.to_sym
        end

        def id_name_for(name)
          name.to_s.singularize.foreign_key.to_sym
        end

        # To make keeping track of serialized objects easier,
        # they are all tracked in arrays with plural keys.
        #
        # Once the recursion is done, we don't need plural keys / arrays
        # for singular objects.
        #
        # This method converts:
        #   objects: [{data}]
        #   #  to
        #   object: {data}
        #
        # This modifies and returns @serialized
        def singularize_lone_objects
          temp = {}

          _flattened.each do |key, data|
            if data.length > 1
              temp[key.to_s.pluralize.to_sym] = data
            else
              temp[key.to_s.singularize.to_sym] = data.first
            end
          end

          self._flattened = temp
        end

        def include?(item, key)
          return false if _flattened[key].nil?
          _flattened[key] == item || _flattened[key].include?(item)
        end
      end
    end
  end
end
