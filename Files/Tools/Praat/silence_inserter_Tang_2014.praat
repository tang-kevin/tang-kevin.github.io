####################################################################
#  Silence Inserter  (Part of ``Praat Toolkit'' by Kevin Tang)      
####################################################################
#  Function:                                                       
#  This script inserts a silence between two adjacent labels in a   
#  TextGrid. It modifies both the Sound file and the TextGrid file 
#                                                                  
#  Author: Kevin Tang                                             
#  Latest revision: 14 June 2014
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
#  OutputDirectory of the Sound files
#  OutputDirectory of the TextGrid files
#  Tier Number
#  Length of the Silence (sec)
#  Presilence word and the Postsilence word
# 
#  Output:
#  Modified Sound and TextGrid files
#
#  N.B.
#  * This script will create the output directories if they do not 
#  exist already.
#  * This script requires your Sound filename and TextGrid filenames 
#  to match
#  * If either of the two labels do not exist in the TextGrid, the
#  file will be skipped and the filename will be printed in the info
#  box
#  *If the two labels provided are not adjacent, the TextGrid will 
#  NOT be modified correctly.
####################################################################

# Praat versions older than 5.2.03 may be used, but all array
# instances must be changed from array$[index] and array[index]
# to array'index'$ and array'index' respectively. However, other
# problems may persist even if you do this.

clearinfo

if praatVersion < 5203
  exit Your version of Praat is too old. Please update Praat to use this script.
endif


# Input form
form Adding Silence between labeled segments in files
	comment Directory of sound files
	text sound_directory E:\SoundTextGrid\
	sentence Sound_file_extension .wav
	comment Directory of TextGrid files
	text textGrid_directory E:\SoundTextGrid\
	sentence TextGrid_file_extension .TextGrid
	comment Directory of the output sound files
	text output_sound_directory E:\SoundTextGrid\output\
	comment Directory of output TextGrid files
	text output_textGrid_directory E:\SoundTextGrid\output\
	comment Which tier number do you want to read?
	positive tiernum 1
	comment Pre-Silence Word
	text word1
	comment Post-Silence Word
	text word2
	comment Silence Duration
	positive sildur 1
endform

# Create output directory
createDirectory: output_sound_directory$
createDirectory: output_textGrid_directory$

# A list of all the sound files in a directory.

Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	filename$ = Get string... ifile

	# A sound file is opened from the list:
	Read from file... 'sound_directory$''filename$'
	soundname$ = selected$ ("Sound", 1)
	
	# Output Sound_file_extension
	outputsoundfile$ = output_sound_directory$ + soundname$ + sound_file_extension$

	outputgridfile$ = output_textGrid_directory$ + soundname$ + textGrid_file_extension$
    
	label_found = 0
	# Open a TextGrid by the same name:
	gridfile$ = "'textGrid_directory$''soundname$''textGrid_file_extension$'"
	if fileReadable (gridfile$)
		Read from file... 'gridfile$'
		# Find the tier number that has the label given in the form:
		
		select TextGrid 'soundname$'

		tierdur = Get total duration
		tiername$ = Get tier name... 1

		hits = Get number of intervals... tiernum

		# Extract label and timemarks from textgrid
		for hit to hits
		  label$ = Get label of interval... tiernum hit
		  label_all$[hit] = label$
		  label_start[hit] = Get starting point... tiernum hit

		  if label$ <> "" and label$ = word1$
		    word1start = Get starting point... tiernum hit
		    word1end = Get end point... tiernum hit
		    label_found = 1
		  endif

		  if label$ <> "" and label$ = word2$
		       word2start = Get starting point... tiernum hit
		       word2end = Get end point... tiernum hit
		       label_found = label_found + 1
		  endif
		endfor

		if label_found == 2
			select Sound 'soundname$'
			samplingFrequency = Get sampling frequency
			numchn = Get number of channels

			# Create new Sound File with Silence
			# Extract Presilence part
			select Sound 'soundname$'
			soundend = Get total duration
			Extract part... 0 word1end rectangular 1 no
			select Sound 'soundname$'_part
			Rename... prewordsound

			# Create silence
			Create Sound from formula: "silence", numchn, 0.0, sildur, samplingFrequency, "0"

			# Extract postsilence part
			select Sound 'soundname$'
			soundend = Get total duration
			Extract part... word2start soundend rectangular tiernum no
			select Sound 'soundname$'_part
			Rename... postwordsound

			# Concatenate all the three and Save file
			select Sound prewordsound
			plus Sound silence
			plus Sound postwordsound
			Concatenate
			select Sound chain
			#Write to WAV file... 'output_target_directory$'/'soundname$'.wav
			Write to WAV file... 'outputsoundfile$'

			# Create new tier
			newtierdur = tierdur+sildur
			Create TextGrid... 0.0 'newtierdur' 'tiername$'
			Rename... 'soundname$'_New

			select TextGrid 'soundname$'_New

			foundword=0

			for hit to hits

				labeltemp$ = label_all$[hit]
			        
			  if labeltemp$ = word2$
			    foundword = 1
			    silind = hit
			    Insert boundary... tiernum  label_start[hit]
				endif

			  if label_start[hit] != 0
			    if foundword = 1
			    	starttemp = label_start[hit]+sildur
			      Insert boundary... tiernum starttemp
			    else
			     	Insert boundary... tiernum label_start[hit]
			    endif
			  endif

			endfor

			# Apply New Labels
			newhits = hits + 1
			for hit to hits

			labeltemp$ = label_all$[hit]

			  if hit < silind
					Set interval text... tiernum hit 'labeltemp$'
				elsif hit >= silind
					new_hit= hit + 1
					Set interval text... tiernum new_hit 'labeltemp$'
				endif

			endfor 

			# Save New Textgrid

			#Save as text file... 'output_target_directory$'/'soundname$'.TextGrid
	        Save as text file... 'outputgridfile$'

			# Clean up
			select Sound 'soundname$'
			plus TextGrid 'soundname$'
			plus TextGrid 'soundname$'_New
			plus Sound chain
			plus Sound silence
			plus Sound postwordsound
			plus Sound prewordsound
			Remove

		else
		    appendInfo: "Skipped ''", soundname$, "''; Reason: Label(s) not found", newline$
			select Sound 'soundname$'
			plus TextGrid 'soundname$'
			Remove
		endif

	endif

endfor

select Strings list
Remove

appendInfo: "All done!", newline$
appendInfo: "========================", newline$
appendInfo: "Please cite:", newline$
appendInfo: "Tang, K. (2014-2015). Praat Toolkit. http://tang-kevin.github.io/Tools.html.", newline$
appendInfo: "========================", newline$
appendInfo: "For other linguistic tools, please visit:", newline$
appendInfo: "http://tang-kevin.github.io", newline$