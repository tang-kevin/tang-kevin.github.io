####################################################################
#  Channel Extractor
#  
#  Function:
#  Extract Only One Channel of all the files in a specified
#  directory.  Files are saved in specified directory.
#
#  Author: Kevin Tang                                             
#  Latest revision: 14 June 2014
#  Email: kevin.tang.10@ucl.ac.uk
#  http://tang-kevin.github.io
#  Twitter: http://twitter.com/tang_kevin​
#
####################################################################


form Extract Single Channel
	comment Directory of sound files
	text sound_directory c:\temp\
	sentence Sound_file_extension .wav
	comment Save resulting files in which directory
	text end_directory c:\temp\
	comment Channel Number
	positive channum 1
endform

# Here, you make a listing of all the sound files in a directory.

Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

for ifile to numberOfFiles

	# A sound file is opened from the listing:

	filename$ = Get string... ifile
	Read from file... 'sound_directory$''filename$'

	# Extract one channel

	Extract one channel... channum

	# Save resulting file

	Write to WAV file... 'end_directory$''filename$'

	select all
	minus Strings list
	Remove
	select Strings list
endfor

select all
Remove

appendInfo: "All done!", newline$
appendInfo: "Thank you for using ''Channel Extractor''", tab$, "by Kevin Tang", newline$
appendInfo: "For other linguistic tools, please visit:", newline$
appendInfo: "http://tang-kevin.github.io", newline$