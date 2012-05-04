require_relative "lib/vpopmail"

vp = Vpopmail.new()

#info = vp.dominfo
p vp.get_ml(vp.dhash("aushop.gr.jp"))
