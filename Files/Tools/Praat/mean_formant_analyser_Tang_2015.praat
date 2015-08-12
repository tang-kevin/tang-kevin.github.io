####################################################################
#  Mean Formant Analyser  (Part of ``Praat Toolkit'' by Kevin Tang)      
####################################################################
#  Function:                                                       
#  This script calculates the mean formant values (F1,F2,F3) of each labelled segment in each pair of Sound and TextGrid files (which have to have the same name). The mean formant values are calculated over a region of the label, e.g. the beginning (20-30%) of a diphthong
#  Author: Kevin Tang                                             
#  Latest revision: 12th August 2015
#  Email: kevtang@gmail.com
#  http://tang-kevin.github.io
#  Twitter: http://twitter.com/tang_kevin​
#
#  Please cite:
#  Tang, K. (2014-2015). Praat Toolkit. http://tang-kevin.github.io/Tools.html.
#
#  # Requires Praat v 5.2.03+
#  
#  Input: 
#  Directory of the Sound files, and their extension
#  Directory of the TextGrid files, and their extension 
#  Output path of the formant results
#  Tier Number
#  Starting Percentage of the labelled segment
#  Ending Percentage of the labelled segment
#  ... (Other default parameters for formant extraction)
#
#  NOTE: All the sound files should each have a textgrid file. Otherwise the script will try to process the sound files without the textgrid and you might experience the interface "flashing". This should not affect the results of the sound files that have a textgrid file.
#   
#  Output:
#  A textfile with the extracted mean formants
#
#  Revisions: 
#  12th August 2015: Fixed the GUI with units, better documentation
#
####################################################################

clearinfo

if praatVersion < 5203
  exit Your version of Praat is too old. Please update Praat to use this script.
endif

form Extract mean formant values of labeled segments of each file
	comment Directory of sound files
	text sound_directory c:\temp\
	sentence Sound_file_extension .wav
	comment Directory of TextGrid files
	text textGrid_directory c:\temp\
	sentence TextGrid_file_extension .TextGrid
	comment Full path of the resulting text file:
	text resultfile c:\temp\formant_results_20_30.txt
	comment Which tier number do you want to read?
	positive Tier 1
	comment Parameters for formant analysis
	positive Percentage_start_(%) 20
	positive Percentage_end_(%) 30
	positive Time_step_(s) 0.01_(=default)
	integer Maximum_number_of_formants 5_(=default)
	positive Maximum_formant_(Hz) 5500_(=default)
	positive Window_length_(s) 0.025_(=default)
	real Preemphasis_from_(Hz) 50_(=default)
endform

Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

header$ = "Filename	Label	F1 Mean (Hz)	F2 Mean (Hz)	F3 Mean (Hz)	Start (%)	End (%)'newline$'"
fileappend "'resultfile$'" 'header$'

for ifile to numberOfFiles
	filename$ = Get string... ifile
	
	Read from file... 'sound_directory$''filename$'
	soundname$ = selected$ ("Sound", 1)
	To Formant (burg)... time_step maximum_number_of_formants maximum_formant window_length preemphasis_from
	# Open a TextGrid by the same name:
	gridfile$ = "'textGrid_directory$''soundname$''textGrid_file_extension$'"
	if fileReadable (gridfile$)
		Read from file... 'gridfile$'
		numberOfIntervals = Get number of intervals... tier
		# Pass through all intervals in the selected tier:
		for interval to numberOfIntervals
			label$ = Get label of interval... tier interval
			if label$ <> ""
				# unempty labels only!
				start = Get starting point... tier interval
				end = Get end point... tier interval
				duration =  end - start

				startpoint = start + percentage_start/100 * duration
				endpoint = start + percentage_end/100 * duration

				readpoint = startpoint 
				count = 0

				select Formant 'soundname$'

				while readpoint < endpoint
					# get the formant values
					readpoint = startpoint + time_step*count
					
					f1[count+1] = Get value at time... 1 readpoint Hertz Linear
					f2[count+1] = Get value at time... 2 readpoint Hertz Linear
					f3[count+1] = Get value at time... 3 readpoint Hertz Linear

					count = count + 1		
	
				endwhile

				f1_sum = 0
				f2_sum = 0
				f3_sum = 0

				for n to count
				    f1_sum = f1_sum + f1[n]
				    f2_sum = f2_sum + f2[n]
				    f3_sum = f3_sum + f3[n]				    
				endfor

				f1_mean = f1_sum / count
				f2_mean = f2_sum / count
				f3_mean = f3_sum / count

				# Store results:
				resultline$ = "'soundname$'	'label$'	'f1_mean'	'f2_mean'	'f3_mean'	'percentage_start'	'percentage_end''newline$'"
				fileappend "'resultfile$'" 'resultline$'
				select TextGrid 'soundname$'
			endif
		endfor
		# Remove TextGrid
		select TextGrid 'soundname$'
		Remove
	endif
	# Clear old objects
	select Sound 'soundname$'
	plus Formant 'soundname$'
	Remove
	select Strings list
endfor


appendInfo: "All done!", newline$
appendInfo: "========================", newline$
appendInfo: "Please cite:", newline$
appendInfo: "Tang, K. (2014-2015). Praat Toolkit. http://tang-kevin.github.io/Tools.html.", newline$
appendInfo: "========================", newline$
appendInfo: "For other linguistic tools, please visit:", newline$
appendInfo: "http://tang-kevin.github.io", newline$