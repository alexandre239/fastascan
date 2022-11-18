#!/usr/bin/bash
#
#  ----------------------------------------------------------------------------------------------------
# |                                                                                                    |
# |                                    ### FASTASCAN - V2.0 ###                                        |
# |                                                                                                    |
# |     This bash script provides the below described information about fasta files found              |
# |     in the current directory and subfolders, or other folders if specified as arguments            |
# |     in the command-line. This script can be executed as a command typing "fastascan" in            |
# |     the bash terminal.                                                                             |
# |                                                                                                    |
# |     The aim of this program is to provide a brief summary about 'fasta' files found in             |
# |     a certain folder and subfolders.                                                               |
# |                                                                                                    |
# |     The user might execute the fastascan script in the following way:                              |
# |                                                                                                    |
# |                                  $ fastascan folder_to_search                                      |
# |                                     -------    -----------                                         |
# |                                    (command)   (argument*)                                         |
# |                                                                                                    | 
# |     * The user can indicate in which folder the program should be run as an argument to            |
# |       the command. If the user executes the command without argument, the program will run         |
# |       in the current folder and subfolders.                                                        |
# |                                                                                                    |
# |                                         ## SCRIPT ##                                               |
# |                                                                                                    |
# |     The script is explained in code blocks (1), (2), (3), (4) with each of them describing         |
# |     each step in sections [a], [b], [c]... before the actual code block. Each code block and       |
# |     section are referenced in the corresponding code within the code block.                        |
# |                                                                                                    |
#  ----------------------------------------------------------------------------------------------------

# (1) -- Searching fasta files by suffix --
#    [a]  Checking if folder was specified as argument in the command-line ($1). If so, fastascan
#    will look for fasta files in such folder (find $1...). Else, fastascan will be  executed in
#    current folder
#
#    [b]  Summary of 'find' command: search of files and symlinks (f,l) that enf with the suffix
#    '.fa/.fasta'. Command is stored in a variable for further usage.
#
#    [c]  Checkpoint - checking if in specified folder any fasta files at all can be found by
#    checking if 'fa_list' variable is empty or not. If empty, error message printed and program exited. 

# [a]
if [[ -n $1 ]]
then
    fa_list=$(find $1 -type f,l -name "*.fa" -o -type f,l -name "*.fasta") 
else                                                                        # [b]
    fa_list=$(find . -type f,l -name "*.fa" -o -type f,l -name "*.fasta")
fi

# [c]
if [[ -z $fa_list ]]
then
    echo '### ERROR ###'
    echo No fasta files could be found 'in' the specified directory
    echo Please make sure that, if an argument is being provided, it corresponds to an actual directory '(example: $ fastascan this_folder/)'
    exit 1
fi

# (2) -- FASTA SUMMARY --
#    Below, a summary for each file is produced, and it is all included in one single loop
#    done through each file found inside the '$fa_list" variable. The result will be a table
#    where the information for each file is displayed. Before the loop start, the titles of
#    each field of the table are created and outputted to 'table.tsv'* file.
#
#    [a] Checkpoint - program will review veracity of each fasta file by checking if any fasta title
#    can be found for each file. If so, 3 variables are created [a.1, a.2, a.3]:
#
#       [a.1] SEQUENCE CONTENT: 'grep' used for retrieving each line starting with '>' (= sequence
#       titles). Each line  is counted with 'wc -l', obtaining number of sequences of file.
#      	[a.2] SEQUENCE LENGTH: 'egrep' used for selecting only lines NOT starting with '>'. Then,
#       'sed -E' used to remove gaps (-). Lastly, 'sed -z' is able to recognize new line chars
#	(we match any possible space char with '\s'), so it is used to remove them.
#	[a.3] NUMBER OF SEQUENCES: 'awk' used on '$seq_cont' to print the length of the sequence, which
#       is now found in a single line ($0).
#
#    If no fasta title is found in a file, fasta file name is appended in 'error.tsv'* file for later use.
#
#    [b] 'TYPE' - under the condition set in '[a]', another condition is set to check
#    the file contains either nucleotide or amino acid sequences: if the file contains anything that
#    is not the nucleotides ATCGU (and N for any of them in fasta format) in any single char position,
#    it means it consists of an amino acid sequence. Else, it is a nucleotide sequence. Variable '$type'
#    is created, content dependent on condition.
#
#    [c] 'SYMLINK' - simple condition to check if the file is a symlink (-h is the specific condiitonal
#    operator for this). Variable '$symlink' is created, content dependent on condition.
#
#    [d] The above determined variables are tabbed and appended into 'table.tsv' file. On this step,
#    the creation of the table where the values of the variables for each file will be displayed takes
#    place, round after round of the loop.
#
#    [e] 'OVERALL RESULTS' - 2 empty variables are declared before the loop whose final value will
#    become the sum of the values of number of sequences ('total_seq_num') and sequence length
#    ('$total_seq_len') of all fasta files into a final global value. The functions for performing
#    this sum are shown by the end of the loop. Both variables are appended to the 'table.tsv' file
#    as the last line of the created table.
#
#    [f] Obtaining one fasta title - We put a condition to ensure the title of the first file is saved in
#    a variable so that after that, the condition is ignored. We do this by defining the variable
#    we are checking after the condition block. We delete the directory pathway using 'sed' for a nicer
#    output showing only the file name.
#
#    [g] Outputting results - The table created in 'table.tsv' file is retrieved using the function
#    column - we use the switches -s -t $'\t' to identify fields separated by tabular spaces. The file
#    'table.tsv' is removed right after retrieving the table. After this, the example fasta title is
#    outputted by echoing the corresponding variables created in section '[f]'.
#
#    * '.tsv' files are used as they are useful to store data in tabular format.

echo; echo == FASTA SUMMARY ==
echo 'Please find below a table with a brief summary of fasta files found in the directory and subfolders:'; echo

# [e]
total_seq_num=0
total_seq_len=0

echo -e FILE NAME'\t'NUM SEQ'\t'SEQ LEN'\t'SYMLINK'\t'TYPE > table.tsv
for file in $fa_list; do

    # [a]
    if grep -q '^>' $file
    then
	seq_num=$(grep '^>' $file | wc -l)                                   # [a.1]
	seq_cont=$(egrep '^[^>]' $file | sed -E 's/-//g' | sed -z 's/\s//g') # [a.2]
	seq_len=$(echo $seq_cont | awk '{print length($0)}')                 # [a.3]

	# [b]
	if (echo $seq_cont | egrep -q '[^AaCcTtGgUuNn]')
	then
	    type='Amino Acid'
	else
	    type='Nucleotide'
	fi

	# [c]
	if [[ -h $file ]]
	then
	    symlink=Yes
	else
	    symlink=No
	fi

	# [d]
	echo -e $file'\t'$seq_num'\t'$seq_len'\t'$symlink'\t'$type >> table.tsv
	
	# [e]
	total_seq_num=$(($total_seq_num+$seq_num))
	total_seq_len=$(($total_seq_len+$seq_len))

	# [f]
	if [[ -z $file_name ]]
	then
	    file_name=$(echo $file | sed -E 's/^.+\///g')
	    fasta_title=$(awk '/^>/{print $0}' $file | head -n1)
	else
	    continue
	fi
	
    else
	echo -e $file >> error.tsv
    fi
done

# [e]
(echo  -e -'\t'-'\t'-'\t'-'\t'-; echo -e 'OVERALL RESULTS*\t'$total_seq_num'\t'$total_seq_len) >> table.tsv

# [g]
column -t -s $'\t' table.tsv; echo; rm table.tsv

# [f]
echo "Also, please find a fasta title found in '$file_name' as an example:"
echo $fasta_title; echo


# (3) -- LEGEND --
#    A brief legend is displayed after the summary table for the user's best understanding of each field.

echo == LEGEND ==

echo '  NUM SEQ: number of sequences contained in fasta file' 
echo '  SEQ LEN: total sequence length of all sequences in fasta file (in nt or aa, see 'TYPE' field)'
echo '  SYMLINK: is fasta file a symbolic link? (Yes/No)'
echo '  TYPE: informs about if fasta file contains amino acid or nucleotide sequences'
echo; echo '* Overall results obtained by summing up the values from all files.'; echo


# (4) -- DISCARDED FILES!! --
#    The fasta files from which a fasta title cannot be retrieved are appended in the 'error.tsv' file.
#    The purpose of this code block is to inform the user in case there are fasta files from which fasta
#    information could not be retrieved for many possible reasons (echoed in output), so the user can
#    detect any fasta file that should be reviewed. The 'error.tsv' file is removed at the end of the code
#    block.

if [[ -e error.tsv ]]
then
    echo '== DISCARDED FILES!! =='
    echo "FYI - please be aware that the below fasta files exist, but no fasta information can be retrieved from them."
    echo "For this reason, no information from them can be displayed in the previous sections..."; echo
    column -t -s $'\t' error.tsv; echo
    echo "Possible reasons might be: files are empty, do not contain fasta information or it is intelligible" '(are they hidden/binary files?).'
    echo "You might consider reviewing them."; echo
    rm error.tsv
fi

### END OF PROGRAM ###
