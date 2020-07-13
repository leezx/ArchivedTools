#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2017-03-03 10:14:26
# @Author  : Your Name (you@example.org)
# @Link    : http://example.org
# @Version : $Id$

from pymonitor import *

def test_class_ZDatabase():
    projectlocation = "/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db"
    #---------write---------
    zodbobj = ZDatabase()
    if not zodbobj.Init(projectlocation):
        print("Cannot open " + projectlocation)
        logging.warning("--FileStorage Fail--")
        return
    else:
        logging.info("--Init() OK--")
    zodbroot = zodbobj.Open()
    logging.info("--Open() OK--")
    # zodbroot = zodbobj.dbroot
    zodbroot['a_number'] = 3
    zodbroot['a_string'] = 'Gift'
    zodbroot['a_list'] = [1, 2, 3, 5, 7, 12]
    zodbroot['a_dictionary'] = { 1918: 'Red Sox', 1919: 'Reds' }
    zodbroot['deeply_nested'] = {
      1918: [ ('Red Sox', 4), ('Cubs', 2) ],
      1919: [ ('Reds', 5), ('White Sox', 3) ],
      }
    zodbobj.Close()
    zodbobj.Clean()
    zodbobj.Uninit()
    logging.info("--Close() & Uninit() & Clean()  OK--")
    logging.info("--Read is OK--")
    #-------read----------
    zodbobj = ZDatabase()
    if not zodbobj.Init(projectlocation):
        print("Cannot open " + projectlocation)
        return
    zodbroot = zodbobj.Open()
    for key in zodbroot.keys():
        print(key, zodbroot[key])
    zodbobj.Close()
    # zodbobj.Clean()
    zodbobj.Uninit()
    logging.info("--Write is OK--")
    
def test_class_configFile():
    # delete and modify "~/.pymonitor.conf" file to test
    # ConfigFileObj = configFile()
    logging.info("--__init__() is OK--")
    ConfigFileObj.Update()
    logging.info("--Update() is OK--")
    # confighandle = ConfigFileObj.getHandle()
    logging.info("--getHandle() is OK--")
    projectname = "test1"
    projectlocation = "/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db"
    confighandle.set('project', 'test1', '/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db')
    ConfigFileObj.Update()
    # need to test cronList() first
    try:
        # keep some prj in ~/.pymonitor.conf
        # test1 = /ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db
        ConfigFileObj.addPrj(projectname, projectlocation)
    except:
        logging.warning("--addPrj() Failed--")
    else:
        logging.info("--addPrj() is OK--")
    # ---------------------------
    # can only run one, at once
    # ---------------------------
    # try:
    #     # keep some prj in ~/.pymonitor.conf
    #     ConfigFileObj.removePrj(projectname)
    # except:
    #     logging.warning("--removePrj() Failed--")
    # else:
    #     logging.info("--removePrj() is OK--")

def test_class_cronList():
    # ConfigFileObj = configFile()
    print("content: " +ConfigFileObj.getHandle().get('base', 'CronNode'))
    logging.info("--ConfigFileObj.getHandle().get() is OK--")
    cronobj = cronList()
    logging.info("--cronList() is OK--")
    cronobj.addCron()
    logging.info("--addCron() is OK--")
    cronobj.removeCron()
    logging.info("--removeCron() is OK--")

def test_class_projectClass():
    projectname = "test1"
    projectlocation = "/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db"
    opt_P = "HUMDnab"
    opt_q = "bc.q"
    opt_p = "test1"
    opt_i = "/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test/outdir/allDependent.txt"
    opt_n = ''
    opt_m = 0
    # ConfigFileObj = configFile()
    # confighandle = ConfigFileObj.getHandle()
    logging.info("--getHandle() is OK--")
    confighandle.set('project', 'test1', '/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test1.db')
    ConfigFileObj.Update()
    zodbobj = ZDatabase()
    if not zodbobj.Init(projectlocation):
        print("Cannot open " + projectlocation)
        return
    zodbroot = zodbobj.Open()
    logging.info("--zodbobj.Open() OK--")
    if 'projectobj' not in zodbroot:
        zodbroot['projectobj'] = projectClass(zodbroot)
        logging.info("--zodbobj.write() OK--")
    projectobj = zodbroot['projectobj']
    projectobj.projectName = projectname
    projectobj.param_P = opt_P
    projectobj.param_q = opt_q
    projectobj.allFinished = 0
    if opt_n: # maximum number of jobs.
        projectobj.maxJobs = opt_n
    else:
        maxjobs = ConfigFileObj.getHandle().getint('base', 'GlobalMaxJobs')
        jobnumber = len(ConfigFileObj.getHandle().options('project'))
        maxjobs = int(maxjobs / jobnumber)
        projectobj.maxJobs = maxjobs
    finishmark = ConfigFileObj.getHandle().get('base', 'defaultFinishMark')
    print(projectobj.projectName , '|', projectobj.param_P , '|', projectobj.param_q , '|', projectobj.maxJobs , '|', projectobj.currentJobs , \
        projectobj.finishMark , '|', projectobj.allFinished , '|', projectobj.DiskWarning , '|', projectobj.submitEnabled )
    projectobj.ImportTaskmonitor(opt_i, opt_m)
    projectobj.Update(1)
    zodbobj.Close()
    zodbobj.Uninit()

if __name__=='__main__':
    ConfigFileObj = configFile()
    confighandle = ConfigFileObj.getHandle()
    FILE = os.getcwd()
    # logging.basicConfig(filename=os.path.join(FILE,'log.txt'),level=logging.INFO)
    logging.basicConfig(level=logging.INFO,
                    format='[%(levelname)s]  %(asctime)s - %(filename)s - [line:%(lineno)d]: %(message)s',
                    datefmt='%d %b %H:%M:%S',
                    filename = os.path.join(FILE,'log.txt'),
                    filemode='w')
    print("-----------------------test_class_ZDatabase----------------------------")
    try:
        # test_class_ZDatabase()
        pass
    except:
        logging.warning("--Failed--\n" + "-"*20)
    else:
        logging.info("--successfully test_class_ZDatabase--\n" + "-"*20)
    print("-----------------------test_class_configFile-------------------------")
    try:
        # test_class_configFile()
        pass
    except:
        logging.warning("--Fail--\n" + "-"*20)
    else:
        logging.info("--successfully test_class_configFile--\n" + "-"*20)
    print("------------------------test_class_cronList-----------------------")
    try:
        # test_class_cronList()
        pass
    except:
        logging.warning("--Fail--\n" + "-"*20)
    else:
        logging.info("--successfully test_class_cronList--\n" + "-"*20)
    print("------------------------test_class_projectClass-----------------------")
    try:
        test_class_projectClass()
    except:
        logging.warning("--Fail--\n" + "-"*20)
    else:
        logging.info("--successfully test_class_projectClass--\n" + "-"*20)




    
