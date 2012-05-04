require "open3"

# vpopmail is a wrapper for vpopmail command and common management operations
#
class Vpopmail
  attr_reader :dir

  # determine the vpopmail directory
  def initialize (dir = "/home/vpopmail/")
    @dir = dir
  end

  # A command wrapper for
  # find domain info
  def dominfo
    rslt = Array.new()
    lastdomain = Hash.new()
    begin
      # open a pipe for vpopmail build in vdominfo binarray
      vdominfo_cmd = @dir + "vdominfo"
      Open3.popen3( vdominfo_cmd ) do |i, o, e, t|
        while line = o.readline
          line.chomp
          if md = /^domain:\s(.+)/.match(line)
            rslt << lastdomain if lastdomain.has_key?(:domain)
            lastdomain = Hash.new()
            lastdomain[:domain] = md[1]
          end

          # only parse output for information under some domain
          if lastdomain.has_key?(:domain)
            if md = /^(\w+):\s*(.+)/.match(line)
              lastdomain[md[1]] = md[2]
            end
          end

        end
      end
    rescue EOFError
      # ignore trivilal EOF error for command pipes
    end
    rslt << lastdomain
    rslt
  end

  # find summary
  def summary

  end

end
