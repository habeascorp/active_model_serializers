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

        def flatten(root)
          root = root.each_with_object({}) do |(key, item), hash|
            if item.is_a?(Array)
              new_key = ids_name_for(key)
              hash[new_key] = item.map{ |i| add(key, flatten(i)); i[:id] }
            elsif item.is_a?(Hash)
              new_key = id_name_for(key)
              add(key, flatten(item))
              hash[new_key] = item[:id]
            else
              hash[key] = item
            end
          end
        end

        def add(key, data)
          unless associations_contain?(data, key)
            if _flattened[key].is_a?(Hash)
              # make array
              value = _flattened[key]
              _flattened[key] = [value, data]
            else
              # already is array
              _flattened[key] ||= []
              # make sure that we aren't adding the same object with different data
              old = _flattened[key].select{ |i| i[:id] == data[:id] }.first
              # if we are, merge - new object will have additional associations
              # (list of ids for each relationship)
              if old
                _flattened[key].delete(old)
                data = old.merge(data)
              end

              _flattened[key] << data
            end
          end
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

        # adds a set of objects to the @serialized structure,
        # while checking to make sure that a particular object
        # isn't already tracked.
        def append_to_serialized(objects)
          objects ||= {}

          objects.each do |association_name, data|
            _flattened[association_name] ||= []

            if data.is_a?(Array)
              data.each do |sub_data|
                append_to_serialized(association_name => sub_data)
              end
            else
              unless associations_contain?(data, association_name)
                add(association_name, data)
              end
            end
          end
        end

        # checks if the item exists in the current flattened object
        def associations_contain?(item, key)
          return false if _flattened[key].nil?

          _flattened[key] == item || _flattened[key].include?(item)
        end

      end
    end
  end
end
