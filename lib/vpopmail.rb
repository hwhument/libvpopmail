# vpopmail: a wrapper for vpopmail management commandline
#
# @author Huang Wei <huang@huentsoft.com>
# @date 2012/05/03

## Vpopmail is a wrapper module for vpopmail command line tools.
module Vpopmail

  # define the directory holds all vpopmail commmand executables
  VPOPMAIL_BIN = "/home/vpopmail/bin/"

  # so `vadduser` should located at `VPOPMAIL_BIN + "vadduser"`

  ## list all available commands for vpopmail
  def self.known_cmds
    %w(dominfo)
  end

  ## build the full path for a command
  def self.cmd(cmd_name)
    carray = self.known_cmds
    raise "Unknown command #{cmd_name}" unless carray.include?(cmd_name)
    VPOPMAIL_BIN + cmd_name
  end
end
