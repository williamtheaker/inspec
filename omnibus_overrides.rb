# THIS IS NOW HAND MANAGED, JUST EDIT THE THING

# grab the current train release from rubygems.org
train_stable = /^train \((.*)\)/.match(`gem list ^train$ --remote`)[1]
override "train", version: "v#{train_stable}"
override "ruby", version: "2.7.6"

# Mac m1
override "openssl", version: "1.1.1m" if mac_os_x?
override "ruby-msys2-devkit", version: "2.7.6-1"
