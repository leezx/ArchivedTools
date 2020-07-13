#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2017-03-02 00:29:00
# @Author  : Your Name (you@example.org)
# @Link    : http://example.org
# @Version : $Id$

# myzodb.py

# import ZODB
from ZODB import FileStorage, DB
import transaction

class ZDatabase(object):
    def __init__(self, path):
        self.storage = FileStorage.FileStorage(path)
        self.db = DB(self.storage)
        self.connection = self.db.open()
        self.dbroot = self.connection.root()

    def close(self):
        transaction.commit()
        self.connection.close()
        self.db.close()
        self.storage.close()

# class ZDatabase(object):
#     """This is a wrapper for ZODB interface."""
#     def Init(self, filename):
#         try:
#             self.storage = FileStorage.FileStorage(filename)
#         except:
#             return 0
#         else:
#             self.db = DB(self.storage)
#             return 1
#     def Open(self):
#         self.conn = self.db.open()
#         return self.conn.root()
#     # submit
#     def Close(self):
#         transaction.commit()
#         self.conn.close()
#     # compress the database
#     def Clean(self):
#         self.db.pack()
#     def Uninit(self):
#         # self.db.close()
#         self.storage.close()

def ZODB_test():
    projectlocation = "./test.db"
    # zodbobj = ZDatabase()
    zodbobj = ZDatabase(projectlocation)
    zodbroot = zodbobj.dbroot
    # if not zodbobj.Init(projectlocation):
    #     print("Cannot open " + projectlocation)
    #     return
    # zodbroot = zodbobj.Open()
    
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
    zodbobj.close()
    # zodbobj.Uninit()

if __name__=='__main__':
    ZODB_test()