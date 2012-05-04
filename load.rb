require_relative "lib/vpopmail"

vp = Vpopmail.new()

#info = vp.dominfo
#p vp.get_ml(vp.dhash("aushop.gr.jp"))
#p vp.get_trans(vp.dhash("aushop.gr.jp"))
#p vp.summary()

p vp.addr_list(vp.dhash["mizui.net"])