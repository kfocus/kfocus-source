import random
import sys

test1 = """Profile;Ghz;Governor;;LEDs
High;4.70;perf;0;yes
Normal;4.70;perf;0;yes
Studio;4.70;save;0;yes
Medium;4.70;perf;0;yes
Low;4.70;save;0;yes
Frugal;4.70;perf;0;no
YoYo;4.70;perf;0;no
"""

test2 = """Linear ( the first text )
Soft ( the second text )
Max ( the third text )"""

if sys.argv[1] == 'profiles':
    print(test1)

if sys.argv[1] == 'fanprofiles':
    print(test2)

if sys.argv[1] == 'currentprofile':
    # print(open('/home/niccolove/Cache/kfocus/data').read())
    print(open('./data-file-01').read())

if sys.argv[1] == 'setprofile':
    # open('/home/niccolove/Cache/kfocus/data', 'w').write(sys.argv[2])
    open('./data-file-01', 'w').write(sys.argv[2])

if sys.argv[1] == 'currentfanprofile':
    # print(open('/home/niccolove/Cache/kfocus/data2').read())
    print(open('./data-file-02').read())

if sys.argv[1] == 'setfanprofile':
    # open('/home/niccolove/Cache/kfocus/data2', 'w').write(sys.argv[2])
    open('./data-file-02', 'w').write(sys.argv[2])

