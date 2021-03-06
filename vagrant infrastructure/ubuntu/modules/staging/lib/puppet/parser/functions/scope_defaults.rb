module Puppet::Parser::Functions
  newfunction(:scope_defaults, type: :rvalue, doc: <<-EOS
Determine if specified resource defaults have a attribute defined in
current scope.
EOS
             ) do |arguments|
    raise(Puppet::ParseError, 'scope_defaults(): Wrong number of arguments ' \
      "given (#{arguments.size} for 2)") if arguments.size != 2

    # auto capitalize puppet resource for lookup:
    res_type = arguments[0].split('::').map(&:capitalize).join('::')
    res_attr = arguments[1]

    return lookupdefaults(res_type).key?(res_attr.to_sym)
  end
end
