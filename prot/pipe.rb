f = open("|/home/vpopmail/bin/vdominfo")

begin
  while line = f.readline	
    if md = /^domain:\s*(.+)/.match(line)
      puts md.inspect
    end
  end
rescue => err

end
