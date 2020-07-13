/** @file statistics.h
 *This is the header file of the 'statistics' module
 */  
#ifndef _THREADMGR_H_
#define _THREADMGR_H_

#include <pthread.h>
#include <unistd.h>

/**
 * base class of the muti-threading model.
 *it is the encapsulation of pthread, but it makes  easy to generate threads 
 *inheriting from the following virtual base class, the derived class can use multi-threading easily
 *example;
 *class my_thread: public thread_base
 *{
 *    var XXXX//your member variables here
 *        
 *   public:
 *    void* task() {
 *    ... //your thread task here
 *    }
 *};
 *
 *void use_thread()
 *{
 *    my_thread thread1;
 *    thread.run();
 *
 *    thread.join(NULL);
 *}
 */

void *thread_fun(void *arg);

class thread_base
{
    public:
    pthread_attr_t attr;    ///< attribute field of the pthread
    pthread_t pid;          ///< the pid of the thread
    
    thread_base() {         ///< constructor
        pthread_attr_init(&attr);
    }
    virtual void* task(){return NULL;};              
    
    friend void *thread_fun(void *arg) {
        return ((thread_base*)arg)->task();
    }
    
    /**
     * a new thread will be generated when this function called, and it runs the task of the thread 
     */
    void run(){
        pthread_create(&pid, &attr, thread_fun, (void*)this);
    }
    
    /**
     * wait for the thread 
     */
    void join(void **status) {
        pthread_join(pid, status);
    } 
};

#endif

