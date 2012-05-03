
module Vpopmail

  ## domain management tools
  class Domain

    ## add a new domain `domain_name`
    # return boolean
    def self.add(domain_name)

    end

    ## delete the domain `domain_name`
    # return boolean
    def self.del(domain_name)

    end

    ## get all domain list in a array of hash
    # each hash contains :domain, :users (user number)
    def self.list
      dominfo = Vpopmail::cmd("vdominfo")
      output = system dominfo 

      arrdominfo = []
      lastdom = {}

      # splic output lines and extract usable info
      arrlines = output.split /\n/
      arrlines.each do |line|
        line.chmop
        if (dname = /^domain\:\s+(\w+)/.match(line)[1])
          lastdom[:domain] = dname
        end

        if(lastdom[:domain] and usernum = /^users\:\s+(\d+)/.match(line)[1])
          lastdom[:users] = usernum
          arrdominfo << lastdom
          lastdom = {}
        end

      end

      raise "error" unless $?.success?

      arrdominfo
    end

  end
end
