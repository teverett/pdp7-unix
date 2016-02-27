" Warren's cat program: cat [arg1 arg2 ...]
"
" Because the a7out simulator currently doesn't deal with ASCII files,
" here is how you can test it:
" ./as7 wktcat.s > a.out
"
" ./a7out a.out > z1
" <type some lines and end in ctrl-D>
"
" ./a7out a.out z1 z1
" <the text you typed in will be displayed twice>
"
" Also, the current coding is hideous and needs refactoring.
" I'm still coming to grips with PDP-7 assembly code.

main:
   " Load the pointer pointer in 017777 to see if we have any arguments
   lac 017777 i
   sad d4		" Skip if we have more than four argument words
     jmp stdinout	" Only four argument words, so no arguments

   lac 017777
   tad d1		" Bump AC up by 5 so that it points at the first argument
   tad d4

" This section opens files, and copies their contents to standard output
catfiles:
   " We start with AC pointing to an argument. Save it at label 1f
   dac name

   " Open the file and get the fd into AC
   sys open; name:0; 0; 0
   spa
     jmp badfile	" Bad fd, exit with an error message
   dac fd		" Save the file descriptor

fileloop:
   " Read five words into the buffer from the input file
   lac fd
   sys read; buf; 5
   spa			" Skip if result was >= 0
     jmp error		" Result was -ve, so error result
   sna			" Skip if result was >0
     jmp fileend	" Result was zero, so nothing left to read

   " Save the count of words read in
   dac 1f

   " Write five words from the buffer to stdout
   lac d1
   sys write; buf; 1:0

   " and loop back for more words to read
   jmp fileloop

fileend:
   " Close the open file descriptor
   lac fd
   sys close

   " Subtract 4 from the count of argument words
   lac minus4
   tad 017777 i
   dac 017777 i
   sad d4		" Is the value 4, i.e. no args left?
     jmp end		" Yes, so exit

   " Still an argument, so move up to the next filename argument
   lac name
   tad d4
   dac name
   jmp catfiles		" and loop back to cat this file

end:
   " exit
   sys exit

" This section copies from standard input to standard output
stdinout:
   " Read five words into the buffer from stdin
   " Five was chosen arbitrarily
   lac d0
   sys read; buf; 5
   spa			" Skip if result was >= 0
     jmp error		" Result was -ve, so error result
   sna			" Skip if result was >0
     jmp end		" Result was zero, so nothing left to read

   " Save the count of words read in
   dac 1f

   " Write five words from the buffer to stdout
   lac d1
   sys write; buf; 1:0

   " and loop back for more words to read
   jmp stdinout


" This code comes from the real cat.s
badfile:
   lac name		" Get the pointer to the filename
   dac 1f		" Store it in 1f below
   lac d8		" Load fd 8 which is stderr
   sys write; 1:0; 4	" Write the name, max 4 words
   lac d8		" Then write " ?\n"
   sys write; 1f; 2
   sys exit		" and exit

1: 040; 077012


error:
   " Print an "err read" string and exit
   lac d1
   sys write; noreadstr; 5
   sys exit

noreadstr:
   <er>;<r 040;<re>;<ad>;012000

fd: 0		" fd of the open file
d0: 0		" Constants 0 and 1
d1: 1
d4: 4
d8: 8		" stderr seems to have fd 8
minus4:	0777774	" -4 constant

" Input buffer for read
buf: 0; 0; 0; 0; 0