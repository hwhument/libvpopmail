require "open3"

# vpopmail is a wrapper for vpopmail command and common management operations
#
class Vpopmail
  attr_reader :dir

  # determine the vpopmail directory
  def initialize (dir = "/home/vpopmail/")
    @dir = dir
  end

  # create a domain hash from domain name has the same structure as dominfo() returns
  def dhash(dname)
    {
      :domain => dname,
      "dir" => @dir + '/' + dname
    }
  end

  # A command wrapper for
  # find domain info
  def dominfo
    rslt = Array.new()
    lastdomain = Hash.new()
    begin
      # open a pipe for vpopmail build in vdominfo binarray
      vdominfo_cmd = @dir + "bin/vdominfo"
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

    # don't forget the last one
    rslt << lastdomain if lastdomain.has_key?(:domain)
    rslt
  end

  # get all mailling list under a specific domain
  def get_ml(dom)
    alist = Array.new()
    Dir.new(dom["dir"]).each do |f|
      if md = /^\.qmail\-(.+)/.match(f)
        alist << md[1] + '@' + dom[:domain]
      end
    end
    alist
  end

  # get all mail transfer information
  def get_trans(dom)
    tlist = Array.new()
    Dir.new(dom["dir"]).each do |f|
      abs = dom["dir"] + '/' + f
      if File.directory?(abs)
        Dir.new(abs).each do |inf|
          # absinf = abs + '/' + inf
          tlist << inf + '@' + dom[:domain]  if /^\.qmail$/.match(inf)
        end
      end
    end
    tlist
  end

  # find summary
  # return format example:
  #
  # {
  #   domains: 12
  #   addrs: 88
  #   mls: 20
  # }
  def summary
    summary = Hash.new()

    # get domain info using the vdominfo command
    dinfo = dominfo()
    summary["domains"] = dinfo.count()

    summary["addrs"] = summary["mls"] = 0
    info.each do |d|
      summary["addrs"] = d["users"].to_i
      mlist = get_ml(d)
      summary["mls"] += mlist.count()
    end

    summary
  end

end
