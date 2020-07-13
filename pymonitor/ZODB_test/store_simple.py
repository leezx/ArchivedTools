#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2017-03-02 00:30:29
# @Author  : Your Name (you@example.org)
# @Link    : http://example.org
# @Version : $Id$

# store_simple.py - place some simple data in a ZODB
        
from myzodb import ZDatabase, transaction
projectlocation = "/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db"
zodbobj = ZDatabase(projectlocation)
zodbroot = zodbobj.dbroot
zodbroot['a_number'] = 3
zodbroot['a_string'] = 'Gift'
zodbroot['a_list'] = [1, 2, 3, 5, 7, 12]
zodbroot['a_dictionary'] = { 1918: 'Red Sox', 1919: 'Reds' }
zodbroot['deeply_nested'] = {
  1918: [ ('Red Sox', 4), ('Cubs', 2) ],
  1919: [ ('Reds', 5), ('White Sox', 3) ],
  }
for key in zodbroot.keys():
    print(key, zodbroot[key])

transaction.commit()
zodbobj.close()
