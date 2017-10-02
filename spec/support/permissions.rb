# Helper methods to go with Pundit's "permissions" matcher.

# Focus on this group of permissions
def fpermissions(*list, &block)
  fdescribe(list.to_sentence, permissions: list, caller: caller) do
    instance_eval(&block)
  end
end

# Disable this group of permissions
def xpermissions(*list, &block)
  xdescribe(list.to_sentence, permissions: list, caller: caller) do
    instance_eval(&block)
  end
end
