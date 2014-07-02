if node.attribute?('_vhost_test')
  vhost_nginx node[:_vhost_test][:name] do
    if node[:_vhost_test].key?(:action)
      if node[:_vhost_test][:action].is_a?(Array)
        lwrp_action = node[:_vhost_test][:action].to_a.map { |v| v.to_sym }
      elsif node[:_vhost_test][:action].is_a?(String)
        lwrp_action = node[:_vhost_test][:action].to_sym
      else
        lwrp_action = node[:_vhost_test][:action]
      end
      action lwrp_action
    end
    node[:_vhost_test].each_pair do |key, value|
      key_symb = key.to_sym
      if key_symb != :name && key_symb != :action
        if attribute_names.include?(key_symb) || !value.is_a?(Array)
          send(key.to_sym, value)
        else
          value.each do |val|
            if val.is_a?(Array)
              send(key.to_sym, *val)
            else
              send(key.to_sym, val)
            end
          end
        end
      end
    end
  end
end