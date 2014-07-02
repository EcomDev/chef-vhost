class Chef
  class Resource
    class LWRPBase

      def init_default_attribute_value(variable, default_data, default_symbol)
        value = send(variable.to_sym)
        if value == default_symbol && default_data.key?(variable)
          default_value = default_data[variable]
          if default_value.is_a?(Array)
            value = default_value.to_a
          elsif default_value.is_a?(Hash)
            value = default_value.to_hash
          else
            value = default_value
          end
          send(variable.to_sym, value) # It doesn't set default nil values
        end
      end

      def dump_attribute_values(default_data, default_symbol)
        values = Hash.new
        self.attribute_names.each do |key|
          init_default_attribute_value(key, default_data, default_symbol)
          value = send(key.to_sym)
          if value == default_symbol
            value = nil
          end
          values[key] = value
        end
        values
      end

      def attribute_names
         return @attribute_names if @attribute_names
         @attribute_names = Array.new
         methods.select {|name| name.to_s.match(/^_set_or_return_/)}
         .each { |method| @attribute_names << method.to_s.sub(/^_set_or_return_/, '').to_sym }
         @attribute_names
      end

      def update_from_resources(resources = [])
         updated_by_last_action(resources.any? { |r| r.updated_by_last_action? })
         self
      end
    end
  end
end