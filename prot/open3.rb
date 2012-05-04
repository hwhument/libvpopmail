require "open3"

begin
  Open3.popen3( "/home/vpopmail/bin/vdominfo" ) do |i, o, e, t|
    while line = o.readline
      line.chomp
      if md = /^domain:\s(.+)/.match(line)
        puts md[1]
      end
    end
  end
rescue EOFError
  # ignore trivilal EOF error for command pipes 
end
