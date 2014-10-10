#!/usr/bin/env python
# -*- coding: utf-8 -*-

####################################################################
#  Linger-Summarizer (Part of ``Linger Toolkit'' by Kevin Tang)
####################################################################
#  Function:                                                       
#  This script creates a summary output for Linger .dat files.
#                                                                  
#  Author: Kevin Tang                                             
#  Latest revision: 10 October 2014
#  Email: kevin.tang.10@ucl.ac.uk
#  http://tang-kevin.github.io
#  Twitter: http://twitter.com/tang_kevin​
#
#  Please cite:
#  Tang, K. (2014). Linger Toolkit. http://tang-kevin.github.io/Tools.html. 
#
#  Tested with Python 2.7.6
#
#  The script has a command line interface. 
#
#  Input: 
#  Directory of the dat files from Linger
#  The path of the output csv
#
#  Output:
#  A summary csv
#
#  Options:
#  -h, --help            show this help message and exit
#  -i DATFOLDER, --datfolder=DATFOLDER
#                        A directory contains dat files, e.g. /usr/data/. n.b.
#                        the back slash is important
#  -o CSVOUT, --csvout=CSVOUT
#                        A path for the csv output
#  -e ENCODING, --encoding=ENCODING
#                        If it crashes at the loading stage, please refer to
#                        encoding scheme by Python, e.g. Western Windows 1252
#                        is cp1252 in Python
#  -u RTUPPERBOUND, --rtupperbound=RTUPPERBOUND
#                        The upper bound for RT cut off. The default is 2500
#  -l RTLOWERBOUND, --rtlowerbound=RTLOWERBOUND
#                        The lower bound for RT cut off. The default is 100
#
#
####################################################################
import optparse
import os
import codecs
import math

def main():
    p = optparse.OptionParser()
    p.add_option("-i","--datfolder",help="A directory contains dat files, e.g. /usr/data/. n.b. the back slash is important")
    p.add_option("-o",'--csvout',help = "A path for the csv output")
    p.add_option("-e",'--encoding',default = 'utf-8',help = "If it crashes at the loading stage, please refer to encoding scheme by Python, e.g. Western Windows 1252 is cp1252 in Python")
    p.add_option("-u",'--rtupperbound',help = "The upper bound for RT cut off. The default is 2500", default = "2500")
    p.add_option("-l",'--rtlowerbound',help = "The lower bound for RT cut off. The default is 100", default = "100")
    options, arguments = p.parse_args()
    #print 'Hello %s' % options.person    

    #### modify path names here
    dat_path_folder = options.datfolder  
    #dat_path_folder = "/media/My_Files/MyWork/Projects/PyLingerlyser/Files_from_Nino/dats/"
    #### it saves the csv in the same folder
    csv_path = options.csvout
    #csv_path = dat_path_folder + 'summary.csv'
    
    ## Get all dat files and sort
    allfiles = os.listdir(dat_path_folder)
    datfiles = [i for i in allfiles if i.endswith('.dat')]
    datfiles = sorted(datfiles)
    
    print '====================================='
    print 'dat folder location: ' + dat_path_folder   
    print '====================================='
    print 'Processing ' + str(len(datfiles)) + ' dat files'
    print ','.join(datfiles) 
    
    
    
    # There should be 8 columns, thus 8 headers
    #headers = options.headers 
    #headers = headers.split(',')
    headers = ['subject',
               'experiment',
               'item',
               'condition',
               'Wpos',
               'word',
               'region',
               'Rtraw']
    
    
    ## Add all dats together
    dat_lines = []
    
    print '=====================================' 
    print 'Combining dat files'
    for dat in datfiles:
        with codecs.open(dat_path_folder + dat,'r',options.encoding) as f:
            dat_lines_individ = f.readlines()
        dat_lines_individ = [i.rstrip('\r\n') for i in dat_lines_individ]
        
        dat_lines_individ = [i.split() for i in dat_lines_individ]  # space delimit splits
        
        # check if every lines has 8 parts like the headers
        bad_dat_lines = [0 for i in dat_lines_individ if len(i) != len(headers)]
        if len(bad_dat_lines) == 0:
            #print 'DAT contains the right number of columns for every line'
            dat_lines += dat_lines_individ
        else:
            print dat + ' contains the wrong number of columns for' + str(len(bad_dat_lines)) + ' line(s), this file will be skipped'
        
    #print len(dat_lines)
    

    
    print '=====================================' 
    print 'Calculating Rtraw.1'
    '''
    Task 1: "Rtraw.1" is a version of "Rtraw" with outliers
    being replaced by the symbol "-" with the exception 
    of any "Rtraw" that has a non-integer value in the "Wpos"
     column. Outlier criteria are set by users, upper bound 
     (default 2500 ms) and lower bound (default 100 ms). 
    '''
    ## Parameters Beg.
    # Hard criterion
    Rtraw_1_above_ms = int(options.rtupperbound)
    Rtraw_1_below_ms = int(options.rtlowerbound)
    # String that you would like to use to replace the outlier cell
    Rtraw_1_Replacer = "-" 
    #Wpos_end = "?"
    ## Parameters End
    
    ## Fixed Parameters Beg.
    # python idx 7 is column 8 (Rtraw)
    Rtraw_Posit = headers.index("Rtraw")
    Wpos_Posit = headers.index("Wpos")
    #Rtraw_Posit = 7
    ## Fixed Parameters End.
    
    # Update header
    headers.append("Rtraw.1")
    
    new_dat_lines = [] 
    for dat_line in dat_lines:
        
        Wpos_individ = dat_line[Wpos_Posit]

        Rtraw_individ = dat_line[Rtraw_Posit]
        dat_line.append(Rtraw_individ)
        Rtraw_individ = int(Rtraw_individ)
        
        try:
            value = int(Wpos_individ)
            Wpos_is_int = 1
        except ValueError:
            Wpos_is_int = 0
                 

        if Wpos_is_int == 1:
            if Rtraw_individ > Rtraw_1_above_ms:
                #print dat_line[7]        
                dat_line[8] = Rtraw_1_Replacer # idx 8 is the new Rtraw.1 column
            if Rtraw_individ < Rtraw_1_below_ms:
                #print dat_line[7]        
                dat_line[8] = Rtraw_1_Replacer # idx 8 is the new Rtraw.1 column             
        
        new_dat_lines.append(dat_line)
        
    '''
    Task 2:
    "correct" contains the accuracy of the response for each item.
    '''
    print '=====================================' 
    print 'Calculating correct'    
    ## Parameters Beg.
    # Wpos
    # String to denote end of sentence
    #Wpos_end = "?"
    correct_NA = '-' # symbol for correct if the sentence has no Wpos_end
    ## Parameters End
    
    ## Fixed Parameters Beg.
    Wpos_Posit = headers.index("Wpos")
    #Wpos_Posit = 4
    region_Posit = headers.index("region")
    #RightAnswerPosit = 6
    subject_Posit = headers.index("subject")
    experiment_Posit = headers.index("experiment")
    item_Posit = headers.index("item")
    
    ## Fixed Parameters End.
    
    # Update header
    headers.append("correct")
    
    
    new_dat_lines_2 = []
    #reverse to iterate through the list backwards
    new_dat_lines_rev = list(new_dat_lines)
    new_dat_lines_rev.reverse()
    
    for currLine in new_dat_lines_rev:
        
        Wpos_individ = currLine[Wpos_Posit]
        try:
            value = int(Wpos_individ)
            Wpos_is_int = 1
        except ValueError:
            Wpos_is_int = 0
                 

                
    
        #currLine = line
        if Wpos_is_int == 0:
        #if currLine[Wpos_Posit] == Wpos_end:               # find the lines that correspond to responses
            accval = currLine[region_Posit]          # get accuracy for current question
            currSub = currLine[subject_Posit]
            currExp = currLine[experiment_Posit]
            currItem = currLine[item_Posit]
            currUnique = currSub + '\t' + currExp + '\t' + currItem
    
            #print currUnique
        currUnique2 = currLine[subject_Posit] + '\t' + currLine[experiment_Posit] + '\t' + currLine[item_Posit]
    
        #print currUnique2
        if currUnique != currUnique2:
            accval = '-'
        currLine.append(str(accval))
        new_dat_lines_2.append(currLine)    
    
    
    # reverse order to obtain original order
    new_dat_lines_2.reverse()
    
    print '=====================================' 
    print 'Calculating Lpos'        
    ''' Task 3
    "Lpos" contains the position of the item in the presented order.
    '''
    subject_Posit = headers.index("subject")
    
    # Update header
    headers.append("Lpos")
    
    new_dat_lines_3 = []
    Lpos_counter = 0
    Item_Last = -9999 # an impossible item number
    Subject_Last = "IMPOSSIBLE" # an impossible subject
    for currLine in new_dat_lines_2:
        if currLine[subject_Posit] != str(Subject_Last):
            Lpos_counter = 0
        if currLine[item_Posit] != str(Item_Last):
            Lpos_counter += 1
        Item_Last = currLine[item_Posit] 
        Subject_Last = currLine[subject_Posit]
        currLine.append(str(Lpos_counter))
        
        new_dat_lines_3.append(currLine)

    print '=====================================' 
    print 'Calculating LogRT'   
    ''' Task 4
    "LogRT" is the log(base-10) transformed RTs of "Rtraw.1".
    '''
    
    ## Parameters Beg.
    # symbol for when RTraw1 is not log-able, e.g. if it's not a number
    LogRT_NA = '-'
    ## Paremters End
    
    # Update header
    headers.append("LogRT")
    
    # Rtraw.1's Posit
    Rtraw_1_Posit = headers.index("Rtraw.1")
    
    new_dat_lines_4 = []
    
    for currLine in new_dat_lines_3:
        try:
            LogRT_int = math.log10(int(currLine[Rtraw_1_Posit]))
        except:
            LogRT_int = LogRT_NA
        #LogRT_int = math.log10(int(currLine[Rtraw_1_Posit]))
        currLine.append(str(LogRT_int))
        
        new_dat_lines_4.append(currLine)

    print '=====================================' 
    print 'Calculating Wlen'           
    ''' Task 5
    "Wlen" is the length of "word".
    '''
    # Update header
    headers.append("Wlen")
    # Rtraw.1's Posit
    word_Posit = headers.index("word")
    
    new_dat_lines_5 = []
    
    for currLine in new_dat_lines_4:
        currLine.append(str(len(currLine[word_Posit])))    
        new_dat_lines_5.append(currLine)   


    print '=====================================' 
    print 'Printing output csv'              
    '''
    Finally print summary .csv
    '''
    with codecs.open(csv_path,'w','utf-8') as f:
        f.write('\t'.join(headers) + '\n')
        f.writelines(['\t'.join(i) + '\n' for i in new_dat_lines_5])
        print '=====================================' 
        print 'Completed' 
        print '====================================='           
        print 'Summary file location: ' + csv_path
        print '====================================='           
        print 'Please cite:'
        print 'Tang, K. (2014). Linger Toolkit. http://tang-kevin.github.io/Tools.html.'         
        print '=====================================' 
if __name__ == '__main__':
    main()
    