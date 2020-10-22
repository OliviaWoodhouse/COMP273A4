# Woodhouse
# Olivia
# 260734701
.data
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display 
errorBuffer:    .space 0x40000 # space to store match function
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gs.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128  imageFileName
errorBufferInfo:    .word errorBuffer    512 128  0
templateBufferInfo: .word templateBuffer 8   8    templateFileName
#Part 3 Question 1. The image and error buffers' base addresses fall into the same cache
		   #block given that 0x10010000 mod 8 = 0x10050000 mod 8 (unless padding is used)
#Part 3 Question 2. For the templateMatchFast, if the template buffer base address falls into
		   #the same block of direct mapped cache as the image buffer base address,
		   #then the method will take less time to complete, so yes it does matter
		   #for efficiency puposes. But since 0x10010000 mod 8 = 0x10090000 mod 8
		   #(meaning they fall into the same cache block), I have chosen not to alter
		   #the memory layout in this data segment.

.text
main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplate        # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	

##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:	
	
	# TODO: write this function!
	subi $sp, $sp, 16	#using stack space for extra variables
	lw $a3, 0($a0)	#a3 = *imageBuffer
	lw $t0, 0($a1)	#t0 = *templateBuffer
	lw $t1, 0($a2)	#t1 = *errorBuffer
	lw $a1, 4($a0)	#a1 = width
	lw $a2, 8($a0)	#a2 = height
	add $t2, $zero, $zero	#t2 = y
	addi $t6, $zero, 8	#t6 = 8
	sub $a1, $a1, $t6
	sub $a2, $a2, $t6
	
foryloop:	bgt $t2, $a2, done
		add $t3, $zero, $zero	#t3 = x
		j forxloop
		
forxloop:	bgt $t3, $a1, endxloop
		add $t5, $zero, $zero	#t5 = j
		add $v0, $zero, $zero	#for SAD[x,y]
		j forjloop
		
forjloop:	bge $t5, $t6, endjloop
		add $t4, $zero, $zero	#t4 = i
		j foriloop
		
foriloop:	bge $t4, $t6, endiloop
		j sadxy	
		
sadxy:		#t4 = i
		#t5 = j
		add $s0, $t3, $t4	#s0 = x+i
		add $t7, $t2, $t5	#t7 = y+j
		sw $s0, 0($sp)	#0($sp) = x+i
		#a1 = width of image-8
		addi $s0, $a1, 8
		sw $s0, 4($sp)	#4($sp) = width of image
		mult $s0, $t7
		mflo $t7
		lw $s0, 0($sp)
		add $t7, $t7, $s0	#t7 = w*(y+j)+(x+i)
		sll $t7, $t7, 2		#t7 = 4(w*(y+j)+(x+i))
		#a3 = address of displayBuffer
		add $t7, $t7, $a3
		lbu $s0, 0($t7)	#8($sp) = I[x+i][y+j]
		sw $s0, 8($sp)
		#t6 = 8
		mult $t5, $t6
		mflo $t7
		add $t7, $t7, $t4	#t7 = 8j+i
		sll $t7, $t7, 2		#t7 = 4(8j+i)
		#t0 = address of templateBuffer
		add $t7, $t7, $t0
		lbu $s0, 0($t7)	#12($sp) = T[i][j]
		sw $s0, 12($sp)
		lw $s0, 8($sp)
		lw $t7, 12($sp)
		sub $t7, $s0, $t7	#t7 = I[x+i][y+j]-T[i][j]
		abs $t7, $t7	#t7 = abs(I[x+i][y+j]-T[i][j])
		add $v0, $v0, $t7	#v0 += t7
		addi $t4, $t4, 1	#i++
		j foriloop
		
endiloop:	addi $t5, $t5, 1	#j++
		j forjloop	
		
endjloop:	#4($sp) = width of image
		lw $s0, 4($sp)
		mult $s0, $t2
		mflo $t7
		add $t7, $t7, $t3	#t7 = wy+x
		sll $t7, $t7, 2		#t7 = 4(wy+x)
		#t1 = address of errorBuffer
		add $t7, $t7, $t1	#t7 = appropriate address in errorBuffer
		sw $v0, 0($t7)		#store calculated error at errorBuffer[x,y]
		addi $t3, $t3, 1	#x++
		j forxloop
		
endxloop:	addi $t2, $t2, 1	#y++
		j foryloop
		
done:	addi $sp, $sp, 8
	add $v0, $zero, $zero
	jr $ra	
	
##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
	
	# TODO: write this function!
	subi $sp, $sp, 32	#using stack space for extra variables
	lw $a3, 0($a1)	#a3 = *templateBuffer
	lw $t3, 0($a0)	#t3 = *imageBuffer
	lw $t4, 0($a2)	#t4 = *errorBuffer
	lw $a1, 8($a0)	#a1 = height
	lw $a0, 4($a0)	#a0 = width
	add $a2, $zero, $zero	#a2 = j
	addi $t2, $zero, 8	#t2 = 8
	sub $a0, $a0, $t2	#a0 = width-8
	sub $a1, $a1, $t2	#a1 = height-8
	
forjloop2:	bge $a2, $t2, finish
		mult $t2, $a2
		mflo $t0	#t0 = 8*j
		addi $t1, $t0, 0	
		sll $t1, $t1, 2	#t1 = 4(w*j+0)
		add $t1, $t1, $a3
		lbu $t1, 0($t1)	
		sw $t1, 0($sp)	#0($sp) = T[0][j]
		addi $t1, $t0, 1
		sll $t1, $t1, 2	#t1 = 4(w*j+1)
		add $t1, $t1, $a3
		lbu $t1, 0($t1)		
		sw $t1, 4($sp)	#4($sp) = T[1][j]
		addi $t1, $t0, 2
		sll $t1, $t1, 2	#t1 = 4(w*j+2)
		add $t1, $t1, $a3	
		lbu $t1, 0($t1)	
		sw $t1, 8($sp)	#8($sp) = T[2][j]
		addi $t1, $t0, 3
		sll $t1, $t1, 2	#t1 = 4(w*j+3)
		add $t1, $t1, $a3	
		lbu $t1, 0($t1)	
		sw $t1, 12($sp)	#12($sp) = T[3][j]
		addi $t1, $t0, 4
		sll $t1, $t1, 2	#t1 = 4(w*j+4)
		add $t1, $t1, $a3	
		lbu $t1, 0($t1)	
		sw $t1, 16($sp)	#16($sp) = T[4][j]
		addi $t1, $t0, 5
		sll $t1, $t1, 2	#t1 = 4(w*j+5)
		add $t1, $t1, $a3	
		lbu $t1, 0($t1)	
		sw $t1, 20($sp)	#20($sp) = T[5][j]
		addi $t1, $t0, 6
		sll $t1, $t1, 2	#t1 = 4(w*j+6)
		add $t1, $t1, $a3	
		lbu $t1, 0($t1)	
		sw $t1, 24($sp)	#24($sp) = T[6][j]
		addi $t1, $t0, 7
		sll $t1, $t1, 2	#t1 = 4(w*j+7)
		add $t1, $t1, $a3
		lbu $t1, 0($t1)		
		sw $t1, 28($sp)	#28($sp) = T[7][j]
		add $t0, $zero, $zero	#t0 = y
		j foryloop2
		
foryloop2:	bgt $t0, $a1, endyloop2
		add $t1, $zero, $zero	#t1 = x
		j forxloop2

forxloop2:	bgt $t1, $a0, endxloop2
		add $v0, $zero, $zero	#for SAD[x,y]
		add $t5, $t0, $a2	#t5 = y+j
		#t2 = 8
		add $t8, $a0, $t2	#t8 = width
		mult $t5, $t8
		mflo $t6	#t6 = w(y+j)
		addi $t7, $t1, 0	#x+0
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+0)+w(y+j))
		#t3 = *imageBuffer
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 0($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+0][y+j]-t0)
		addi $t7, $t1, 1	#x+1
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+1)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 4($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+1][y+j]-t1)
		addi $t7, $t1, 2	#x+2
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+2)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 8($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+2][y+j]-t2)
		addi $t7, $t1, 3	#x+3
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+3)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 12($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+3][y+j]-t3)
		addi $t7, $t1, 4	#x+4
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+4)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 16($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+4][y+j]-t4)
		addi $t7, $t1, 5	#x+5
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+5)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 20($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+5][y+j]-t5)
		addi $t7, $t1, 6	#x+6
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+6)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 24($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+6][y+j]-t6)
		addi $t7, $t1, 7	#x+7
		add $t7, $t7, $t6
		sll $t7, $t7, 2	#t7 = 4((x+7)+w(y+j))
		add $t7, $t7, $t3
		lbu $t7, 0($t7)	
		lw $t8, 28($sp)
		sub $t7, $t7, $t8
		abs $t7, $t7
		add $v0, $v0, $t7	#SAD[x,y] += abs(I[x+7][y+j]-t7)
		j endingofeachxloop
		
		
endyloop2:	addi $a2, $a2, 1	#j++
		j forjloop2
		
endingofeachxloop:	#t2 = 8
		add $t8, $a0, $t2	#t8 = width
		mult $t0, $t8
		mflo $t7
		add $t7, $t7, $t1	#t7 = wy+x
		sll $t7, $t7, 2		#t7 = 4(wy+x)
		#t4 = address of errorBuffer
		add $t7, $t7, $t4	#t7 = appropriate address in errorBuffer
		lw $t8, 0($t7)	#add what is already at errorBuffer[x,y] to SAD[x,y]
		add $v0, $t8, $v0
		sw $v0, 0($t7)		#errorBuffer[x,y] += calculated error
		addi $t1, $t1, 1	#x++
		j forxloop2
				
endxloop2:	addi $t0, $t0, 1	#y++
		j foryloop2	
	
finish:	addi $sp, $sp, 32
	add $v0, $zero, $zero
	jr $ra	
	
	
	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra
