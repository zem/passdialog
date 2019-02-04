#!/usr/bin/python3
#
# Copyright 2019 1553A52AE25725279D8A499175E880E6DC59190F
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
import locale
from dialog import Dialog
import os, fnmatch
import re
import time

def grep(pattern,word_list):
	expr = re.compile('.*?'+pattern)
	return [elem for elem in word_list if expr.match(elem)]

d=Dialog()
#d.set_backgound_title("find a password entry")

code, answer = d.inputbox("Input your query", 
		width=(os.get_terminal_size().columns-30),
		init=""
	)

if (code != "ok"):
	print(code)
	exit(1)

passdir=os.getenv("PASSWORD_STORE_DIR", os.getenv("HOME")+"/.password-store")
os.chdir(passdir)


# find password store entrys 
passwords=[]
for root, dirs, files in os.walk("."):
	for name in files:
		if (fnmatch.fnmatch(name, "*.gpg")):
			f=os.path.join(root, name)
			f=f[2:]
			f=f[:-4]
			passwords.append(f)

passwords.sort()

i=1
choices=[]
chdict={}
for p in grep(answer, passwords):
	istr=str(i)
	item=istr[-1:]+"_"+istr
	choices.append((item, p))
	chdict[item]=p
	i=i+1

code, answer = d.menu("Select remains", 
		height=(os.get_terminal_size().lines-3), 
		menu_height=(os.get_terminal_size().lines-8), 
		width=(os.get_terminal_size().columns-4),
		choices=choices,
		clear=True
	)

if (code != "ok"):
	print(code)
	exit(1)

print(((" " * os.get_terminal_size().columns) + "\n") * os.get_terminal_size().lines)
os.system("pass -c "+chdict[answer])
print("\n" * int(os.get_terminal_size().lines / 2) )

time.sleep(47)

