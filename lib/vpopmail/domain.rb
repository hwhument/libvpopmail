
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
    def self.list()
      %x[Vpopmail::cmd("dominfo")]
    end

  end
end