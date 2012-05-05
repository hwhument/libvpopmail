require_relative "lib/vpopmail"

vp = Vpopmail.new()

#info = vp.dominfo
#p vp.ml_list(vp.dhash("aushop.gr.jp"))
#p vp.trans_list(vp.dhash("aushop.gr.jp"))
#p vp.summary()

#p vp.addr_list(vp.dhash("mizui.net"))

#ret = vp.deluser("huangw2@mizui.net")
#p vp.lasterr unless ret

ret = vp.editml("sanny@mizui.net", "huang1@humentsoft.com\nhuangw2@humentsoft.com")
p vp.lasterr unless ret