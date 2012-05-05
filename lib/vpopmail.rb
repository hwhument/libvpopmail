require "open3"

# vpopmail is a wrapper for vpopmail command and common management operations
#
class Vpopmail
  attr_reader :dir, :lasterr

  # determine the vpopmail directory
  def initialize (dir = "/home/vpopmail/")
    @dir = dir
  end

  # create a domain hash from domain name has the same structure as dominfo() returns
  def dhash(dname)
    {
      :domain => dname,
      "dir" => @dir + 'domains/' + dname
    }
  end

  # A command wrapper for
  # find domain info
  # return a list of domain infomation like:
  # [
  #   {
  #      :domain => 'frash.co.jp',
  #      'dir' => '/home/vpopmail/domains/frash.co.jp',
  #      'users' => 18,
  #      ...
  #    }
  #   ...
  # ]
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

  ## get a list of available domains
  def domlist
    rslt = Array.new()
    dominfo.each do |d|
      rslt << d[:domain]
    end
    rslt
  end

  # get all mailling list under a specific domain
  def ml_list(dom = nil)
    alist = Array.new()

    # build domain list, if parameter is empty, get all domain first
    domlist = Array.new()
    if dom
      domlist << dom
    else
      domlist = dominfo()
    end

    # for each domain, find .qmail-ml name inside it's directory
    domlist.each do |d|
      Dir.new(d["dir"]).each do |f|
        if md = /^\.qmail\-(.+)/.match(f)
          alist << md[1] + '@' + d[:domain]
        end
      end
    end
    alist
  end

  # get all mail transfer information
  # return a array of mail addresses with mail transfer enabled
  def trans_list(dom = nil)
    tlist = Array.new()

    # build domain list, if parameter is empty, get all domain first
    domlist = Array.new()
    if dom
      domlist << dom
    else
      domlist = dominfo()
    end

    domlist.each do |d|
      Dir.new(d["dir"]).each do |f|
        abs = d["dir"] + '/' + f
        if File.directory?(abs)
          Dir.new(abs).each do |inf|
            # absinf = abs + '/' + inf
            tlist << f + '@' + d[:domain]  if /^\.qmail$/.match(inf)
          end
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
  #   mls: 20       # mailing list number
  #   trans: 29     # number of mail addresses with transfer
  # }
  def summary
    summary = Hash.new()

    # get domain info using the vdominfo command
    dinfo = dominfo()
    summary["domains"] = dinfo.count()

    # initialize address and mailing list number to zero
    summary["addrs"] = summary["mls"] = summary["trans"] = 0
    dinfo.each do |d|
      summary["addrs"] += d["users"].to_i
      mlist = get_ml(d)
      tlist = get_trans(d)
      summary["mls"] += mlist.count()
      summary["trans"] += tlist.count()
    end

    summary
  end

  # Get all email address list
  # param: dom if a domain object specified, return list in the domain
  def addr_list(dom = nil)
    rslt = Array.new()
    domlist = Array.new()

    if dom
      domlist << dom
    else
      domlist = dominfo()
    end

    lastname = Hash.new()
    domlist.each do |d|
      begin
        Open3.popen3( @dir + "bin/vuserinfo -D #{d[:domain]}" ) do |i, o, e, t|
          while line = o.readline
            line.chomp
            if md = /^name:\s(.+)/.match(line)
              if lastname.has_key?(:name)
                rslt << lastname
                lastname = Hash.new()
              end
              lastname[:name] = md[1]
            end

            # only parse output for information under some domain
            if lastname.has_key?(:name)
              if md = /^([\w\s]+):\s*(.+)/.match(line)
                lastname[md[1]] = md[2]
              end
            end
          end
        end

        rslt << lastname if lastname.has_key?(:name)
      rescue EOFError
        # do nothing for eof error (because this is always happen as a pipe)
      end
    end

    rslt
  end

  ##
  #
  #
  def _run_cmd(cmd)
    if /[\\\|\&\;\>\<\#]/.match(cmd)
      @lasterr = "Error: for security concerns, special characters like \\/|/&/;/</>/# are not allowed."
      return false
    end

    begin
      so, se, s = Open3.capture3(cmd)
      if s.success?
        return true
      else
        @lasterr = se + so
        return false
      end
    rescue EOFError
      # do nothing for eof error (because this is always happen as a pipe)
    end
  end

  # add a user address,
  # param: addr is the full address as 'name@domain.com'
  # this method merely wraps vpopmail's vadduser command and return what it returns when error occured.
  def adduser(addr, pass) _run_cmd(@dir + "bin/vadduser #{addr} #{pass}") end

  # delete a user address
  def deluser(addr) _run_cmd(@dir + "bin/vdeluser #{addr}") end

  # change user password
  def chpass(addr, pass) _run_cmd(@dir + "bin/vpasswd #{addr} #{pass}") end

  # add a vdomain
  def adddomain(domain) _run_cmd(@dir + "bin/vadddomain #{domain}") end

  # delete a vdomain
  def deldomain(domain) _run_cmd(@dir + "bin/vdeldomain #{domain}") end

  # return the mailing list setup filename and contents of a mailing list
  # return nil if mailing list file does not exists
  # {
  #   "file" => '/home/vpopmail/domains/mizui.net/.qmail-mlist',
  #   "is_exists" => true,
  #   "list" => ["huang@mizui.net", "wei@mizui.net", ...]
  # }
  #
  #
  def mlinfo(ml)
    # first, separate the domain name and ml name:
    name,dname = ml.split(/\@/)
    if dname.empty?
      @lasterr = "Error: invalid mailing list name."
      return nil
    end

    # check whether the domain is exists.
    domain = {}

    # first get all domain list
    dominfo.each do |d|
      if d[:domain] == dname then domain = d end
    end

    # if no domain returned from dominfo, return error
    unless domain.has_key?(:domain)
      @lasterr = "Error: unknown domain #{dname}"
      return nil
    end

    rslt = Hash.new()

    # cat the mailing list file, check it's status
    ml_file = domain["dir"] + "/.qmail-" + name
    rslt["file"] = ml_file

    rslt["is_exists"] = false
    rslt["is_exists"] = true if File.exists?(ml_file)

    # the array of email addresses get transferred by the mailing list
    arr_list = Array.new()
    # open the file and get the file contents
    File.open(ml_file, "r") do |fh|
      while ln = fh.gets()
        ln.chomp!
        if md = /^\&(.+)/.match(ln)
            puts md.inspect
            arr_list << md[1]
        end
      end
    end

    rslt["list"] = arr_list
    rslt
  end

  # edit (add when it is not exists) mailing list: create a file inside the domain's directory
  # and put the transfer email address inside
  # param: ml is the full name of the email address such as 'god@heaven.com'
  #        content is a text file contains email address each line, the heading & is optional
  #        if `is_edit` set to true, raise error when the targeted mailing list file do not exists.
  def editml(ml, content, is_edit = false)

    hmlinfo = mlinfo(ml)
    return false unless hmlinfo

    ml_file = hmlinfo["file"]
    if is_edit and !File.exist?(ml_file)
      @lasterr = "Error: mailing list #{ml} does not exists."
      return false
    end

    # write contents to the file
    File.open(ml_file, "w") do |fh|
      content.split(/\s*,\s*/).each do |ln|
        ln.chomp
        ln.gsub! /^\&/
        ln = "&" + ln if /\@/.match(ln)
        fh.write ln + "\n"
      end
    end

    true
  end

  # delete a mailing list setup file, but leave a backup
  def delml(ml)
    hmlinfo = mlinfo(ml)
    return false unless hmlinfo

    ml_file = hmlinfo["file"]
    unless File.exists?(ml_file)
      @lasterr = "Error: mailing list file for #{ml} does not exists."
      return false
    end

    ml_backfile = domain["dir"] + "/~.qmail-" + name + "~back~"
    require 'fileutils'
    FileUtils.mv(ml_file, ml_backfile)
  end
end
