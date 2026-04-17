#Alzahra Nassif - 1220168
#Nagham Massis - 1220149
.data
	test: .asciiz "C:\\Users\\HP\\OneDrive\Attachments\\Desktop\\Arch Project1\\Items.txt"
	output_file: .asciiz "C:\\Users\\HP\\OneDrive\\Attachments\\Desktop\\Arch Project1\\outputfile.txt"
	prompt_msg: .asciiz "\nEnter the input file path: "
	successOpen: .asciiz "The file opened successfully.\n"
	file_open_err_msg: .asciiz "\nError: Could not open the file! Try again.\n"
	invalid_format_msg: .asciiz "Error: Invalid file format! Only numbers between 0 and 1 are allowed. Try again.\n"
	menu: .asciiz "Please select an operation:\n1- Print the input file.\n2- First Fit.\n3- Best Fit.\n4- Save it to output file.\nTo exit enter Q or q.\n"
	invalid_input_msg: .asciiz "\nInvalid Input! try again.\n"
	newline: .asciiz "\n"
	newspace:.asciiz "    \r"
	
	fileName: .space 100
	choice: .space 2
	buffer: .space 1024
	output_buffer: .space 1024 # space for output text
	values: .space 512 # Holds parsed strings, null-separated  
	num_values: .word 0 # Counter for parsed values

	
	binsize: .float 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0  # 10 bins
	binsizeB: .float 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0  # 10 bins
	numOfNeededBins:.word 0
	numOfNeededBinsB:.word 0
	valueCountPerBin: .space 40  # 10 bins * 4 bytes (integers)
	valueCountPerBinB: .space 40  # 10 bins * 4 bytes (integers)
	binIndex: .word 0  
	huge_float: .float 100.0  
	
	valuesInEachBin: .space 400 # each bin can hold 10 float ==> 10 bins * 10 = 100 * 4 byte = 400
	valuesInEachBinB: .space 400 # each bin can hold 10 float ==> 10 bins * 10 = 100 * 4 byte = 400
	label_bin: .asciiz "Bin "
	label_size: .asciiz ": Size = "
	label_values: .asciiz ", Values: "
	lable_numOfBinsUsed: .asciiz "Minimum number of required bins is: "
	
	fail: .asciiz "Failed to open the file.\n"
	success: .asciiz "File written!\n"

.text
main:
get_filenamepath:
  	# Prompt user for input file name/path
  	li $v0, 4
  	la $a0, prompt_msg
  	syscall

  	# Read file name
  	li $v0, 8
  	la $a0, fileName
  	li $a1, 100
  	syscall

  	# Remove newline from input if exists
  	la $t0, fileName
newline_check:
    	lb $t1, 0($t0)
    	beqz $t1, proceed
    	beq $t1, 0x0A, remove_newline
    	addi $t0, $t0, 1
    	j newline_check

remove_newline:
    	sb $zero, 0($t0)

proceed:
  	# Open file for reading
	li $v0, 13
	la $a0, fileName
	li $a1, 0
	syscall
	move $s0, $v0 # Save file descriptor

  	# If file open failed, show error and retry
    	bltz $s0, file_open_error
    		
	# Print success message
  	li $v0, 4
  	la $a0, successOpen
  	syscall
  		
  	# Read file content into buffer
	li $v0, 14
	move $a0, $s0
	la $a1, buffer
	li $a2, 1024
	syscall

	# Close the file
	li $v0, 16
	move $a0, $s0
	syscall
#==========================spliting======================================	
	# Parse values
    	la $t0, buffer # Load address of input buffer into $t0
    	la $t1, values # Load address of output buffer into $t1
    	li $t2, 0 # Initialize index for num_values to 0
    	li $t4, 0 # inside string flag

parse_loop:
    	lb $t3, 0($t0) # Load byte from address input buffer $t0 into $t3
    	beqz $t3, finish_parse # Exit loop if byte is zero (end of string)

    	li $t5, 0x0A # ASCII code for newline
    	li $t6, 0x20 # ASCII code for space
    	beq $t3, $t5, end_value # Check if current byte is newline, go to end_value if true
    	beq $t3, $t6, end_value # Check if current byte is space
			
	# if not newline or space ,then itmust be part of the number
    	sb $t3, 0($t1) # Store byte $t3 into address t1 (values)
    	addi $t1, $t1, 1 # Increment $t1 to point to next location in values buffer
    	li $t4, 1 # number is building 
    	j next_char

end_value:
    	beqz $t4, next_char # if space came not after a value (t4==0)ignore it and go to next char
    	sb $zero, 0($t1) # Store null terminator to indicate the end of number
    	addi $t1, $t1, 1
    	li $t4, 0 # Reset inside string flag to 0 means that we are not building a number
    	addi $t2, $t2, 1 # Increment num_values count

next_char:
    	addi $t0, $t0, 1 # Move to next character in input buffer
    	j parse_loop

finish_parse:
	beqz $t4, store_count
    	sb $zero, 0($t1) # null terminate last value
    	addi $t1, $t1, 1
    	li $t4, 0
    	addi $t2, $t2, 1

store_count:
    	la $t0, num_values
    	sw $t2, 0($t0)
	
	# Jump to menu
#==========================Checking input file contents===========================================
	la $t0, values
    	la $t1, num_values
    	lw $t2, 0($t1) # Load the number of values into $t2
    	li $t3, 0 # counter of how many values printed so far	
loopvalid:
    	bge $t3, $t2,displayMainMenu # check if done 
   
    	move $a0, $t0
    	jal string_to_float # items in $f0
    	
    	li $t8, 1	
    	mtc1 $t8, $f3 # Move integer to float register
    	cvt.s.w $f3, $f3 # Convert integer to float
 
    	
    	c.le.s  $f3, $f0 # is 1 <= $f2

	bc1t invalid_value
    	
nextvalid:
    	lb $t4, 0($t0)
    	beqz $t4, fullNumvalid # if it's null byte, stop this string
    	addi $t0, $t0, 1
    	j nextvalid
fullNumvalid:
    	addi $t0, $t0, 1 # move past null terminator
    	addi $t3, $t3, 1 # increment number of values
    	j loopvalid
#==========================Menue==================================================================
displayMainMenu:
  	li $v0, 4
  	la $a0, menu
  	syscall

  	# Read user choice
  	li $v0, 8
  	la $a0, choice
  	li $a1, 2
  	syscall

  	# Print newline after input
  	li $v0, 4
  	la $a0, newline
  	syscall

  	# Load the entered character
  	lb $t0, choice

  	# Exit if user entered q or Q
  	li $t1, 'q'
  	beq $t0, $t1, end_menu
  	li $t1, 'Q'
  	beq $t0, $t1, end_menu

  	# If user entered 1 ? print input file
  	li $t1, '1'
  	beq $t0, $t1, printInputFile

  	li $t1, '2'
  	beq $t0, $t1, FirstFit
  	
  	li $t1, '3'
  	beq $t0, $t1, bestFit
  	
  	li $t1, '4'
  	beq $t0, $t1, write_to_file

  	# Invalid input
  	li $v0, 4
  	la $a0, invalid_input_msg
  	syscall

  	j displayMainMenu
#===================================invalid name or path =============================================
file_open_error:
    	li $v0, 4
    	la $a0, file_open_err_msg
    	syscall
    	j get_filenamepath
#===================================invalid file contents =============================================
invalid_value:
    	li $v0, 4
    	la $a0, invalid_input_msg 
    	syscall
    	j get_filenamepath
#===============================print input file selction 1========================================
printInputFile:
    	li $v0, 4
    	la $a0, buffer
    	syscall

    	# print newline 
    	li $v0, 4
    	la $a0, newline
    	syscall

    	j displayMainMenu
#=======================first fit algorithm=================================    
FirstFit:
	la $t0, values
    	la $t1, num_values
    	lw $t2, 0($t1) # Load the number of values into $t2
    	li $t3, 0  # counter of how many values printed so far	
loop:
    	bge $t3, $t2, printBins # check if done 
   
    	move $a0, $t0
    	jal string_to_float # items in $f0
    	
    	li $t5,0 # index i
findplace:  	
    	mul $t6,$t5,4  # offset = i*4
    	la $t7,binsize  # base address
    	add $t7,$t7,$t6 # EA = base + offset
    	lwc1 $f1,0($t7)
    	sub.s $f2,$f1,$f0
    	
    	li $t4, 0	
    	mtc1 $t4, $f4 # Move integer to float register
    	cvt.s.w $f4, $f4 # Convert integer to float
	c.le.s  $f4, $f2  # is 0.0 <= $f2

	bc1t setInBin

    	addi $t5,$t5,1 # i++
    	#j end_menu
    	j findplace
# move to next string
next:
    	lb $t4, 0($t0)
    	beqz $t4, fullNum # if it's null byte, stop this string
    	addi $t0, $t0, 1
    	j next
fullNum:
    	addi $t0, $t0, 1  # move past null terminator
    	addi $t3, $t3, 1 # increment number of values
    	j loop
setInBin:
    	la $t8, valuesInEachBin # base address of value array
   	la $t9, valueCountPerBin # base address of count array

    	mul $t6, $t5, 4 # t6 = bin index * 4

    	add $t9, $t9, $t6 # address of value count for this bin
    	lw  $t4, 0($t9) # t4= current count

    	# calculate where to store the float:
    	# offset = (bin index * 10  + current count ) *4 
    	mul $t6, $t5, 10             # bin index * 10
    	add $t6, $t6, $t4 # + value count
    	mul $t6, $t6, 4 # * 4 = byte offset
    	add $t8, $t8, $t6 # final address to store value

    	swc1 $f0, 0($t8) # store float value

    	addi $t4, $t4, 1 # increment count
    	sw  $t4, 0($t9)  # save it back

    	# update remaining bin size
    	swc1 $f2, 0($t7)

    	j next
#=======================Best fit algorithm====================================
bestFit:
    	la $t0, values # Address of input values
    	la $t1, num_values
    	lw $t2, 0($t1) # Load number of values
    	li $t3, 0 # Counter: how many values processed

loopB:
    	bge $t3, $t2, printBinsB # Done? Go to print
    	move $a0, $t0
    	jal string_to_float # $f0

    	li $t5, 0 # Bin index = 0
    	li $t6, -1 # Best-fit bin index = -1
    	la $t7, huge_float
    	lwc1 $f10, 0($t7) # $f10 = large float (initial best diff)
    	

findplaceB:
	li $t4,10
    	bge $t5, $t4, checkBestFit # Only 10 bins

  	
    	mul $t7, $t5, 4
    	la $t8, binsizeB
    	add $t7, $t8, $t7
    	lwc1 $f1, 0($t7) # $f1 = current bin size

    	sub.s $f2, $f1, $f0 # $f2 = remaining space

    	li $t9, 0
    	mtc1 $t9, $f3
    	cvt.s.w $f3, $f3
    	c.lt.s $f2, $f3         
    	bc1t skipBin

    	c.lt.s $f2, $f10 # is this bin a better fit?
    	
    	bc1t putsmallestSize # if f2<f10 ==> f10 =f2
    
    	j skipBin
putsmallestSize:

	mov.s $f10, $f2 # update best fit remaining
    	move $t6, $t5  # update best bin index
    	
skipBin:
    	addi $t5, $t5, 1
    	j findplaceB

checkBestFit:
    	li $t9, -1
    	
    	beq $t6, $t9, nextB # No bin fit found ? skip item
	
    	move $t5, $t6 # $t5 = best bin index
    	j setInBinB

nextB:
    	lb $t4, 0($t0)
    	beqz $t4, fullNumB
    	addi $t0, $t0, 1
    	j nextB

fullNumB:
    	addi $t0, $t0, 1 # past null terminator
    	addi $t3, $t3, 1 # processed count++
    	j loopB

setInBinB:

    	la $t8, valuesInEachBinB
    	la $t9, valueCountPerBinB

    	mul $t6, $t5, 4 # offset = bin * 4
    	add $t9, $t9, $t6
    	lw  $t4, 0($t9) # $t4 = current count in bin

    	# final offset = (bin * 10 + count) * 4
    	mul $t6, $t5, 10
    	add $t6, $t6, $t4
    	mul $t6, $t6, 4
    	add $t8, $t8, $t6
    	swc1 $f0, 0($t8) # store item in bin

    	addi $t4, $t4, 1
    	sw   $t4, 0($t9) # update count

    	# Update bin size: remaining = old - item
    	mul $t7, $t5, 4
    	la $t8, binsizeB
    	add $t7, $t8, $t7
    	lwc1 $f1, 0($t7) # current bin size
    	sub.s $f1, $f1, $f0
    	swc1 $f1, 0($t7) # save new bin size
    	mov.s   $f12,$f1
  


    	j nextB
#=======================convert string to float function =======================
string_to_float:# Input: $a0='0.5'   Output: $f0 =0.5
    	# Load first digit (before dot)
    	lb $t5, 0($a0)
    	li $t6, 48
    	sub $t5, $t5, $t6 # Convert character to digit
    	mtc1 $t5, $f1 # Move integer to float register
    	cvt.s.w $f1, $f1 #Convert integer to float

    	# Load first digit after '.'
    	lb $t7, 2($a0)
    	sub $t7, $t7, $t6 # Convert character to digit
    	li $t8, 10	
    	mtc1 $t7, $f2 # Move integer to float register
    	mtc1 $t8, $f3 # Move integer to float register
    	cvt.s.w $f2, $f2 #Convert integer to float
    	cvt.s.w $f3, $f3 #Convert integer to float
    	div.s $f2, $f2, $f3 # to became fraction 

    	add.s $f0, $f1, $f2 # final float = int + frac
    	jr $ra
#======================================printBins================================
printBins:
	li $t0, 0 # bin index
    	la $t1, binsize
    	la $t2, valuesInEachBin
    	la $t9, numOfNeededBins
    	li $t6, 0 # count of used bins 
    	
    	li $t7, 1	
    	mtc1 $t7, $f4 # Move integer to float register
    	cvt.s.w $f4, $f4 # Convert integer to float
    	
print_bins:
	lwc1 $f12, 0($t1) # load bin size
    	c.eq.s $f4, $f12 # if bin size == 1 -> not used -> no need to print 
    	bc1t skip_bin
    	
    	li $v0, 4 # print "Bin "
    	la $a0, label_bin
    	syscall

    	li $v0, 1 # print bin number
    	move $a0, $t0
    	syscall

    	li $v0, 4 # print ": Size = "
    	la $a0, label_size
    	syscall

   	li $v0, 2
   	lwc1 $f12, 0($t1)
    	syscall

    	li $v0, 4 # print ", Values: "
    	la $a0, label_values
    	syscall

    	li $t3, 0 # value index inside the bin (0 to 9)

print_values:
    	beq $t3, 10, finish_bin

    	mul $t4, $t0, 40 # bin offset (10 values * 4 bytes)
    	mul $t5, $t3, 4 # value offset
    	add $t7, $t4, $t5
    	add $t7, $t7, $t2 # address = base t2+ offset[each value t3 * 4 + binoffset = 40 * index]

    	lwc1 $f12, 0($t7)
    
    	# Check if value is 0.0
    	mtc1 $zero, $f6 # $f6 = 0.0
    	c.eq.s $f12, $f6
    	bc1t skip_value
    
    	# Print value
    	li $v0, 2
    	syscall

    	li $v0, 4                  
    	la $a0, newspace
    	syscall
    	
skip_value:
    	addi $t3, $t3, 1 # value index ++
    	j print_values
    	
finish_bin:
    	li $v0, 4
    	la $a0, newline
    	syscall
    	addi $t6, $t6, 1 # increment used bins
skip_bin:
    	addi $t0, $t0, 1 # bin index ++
    	addi $t1, $t1, 4 # next binsize since each bin is 4 byte 
    	li $t8, 10 # total number of bins
    	blt $t0, $t8, print_bins
    
    	# Store number of used bins
    	sw $t6, 0($t9)
    	# Print used bin count
    	li $v0, 4                  
    	la $a0, lable_numOfBinsUsed
    	syscall

	li $v0 , 1
	move $a0, $t6 
	syscall 
	
	li $v0, 4  # print space
    	la $a0, newline
    	syscall
    
	j displayMainMenu
#====================================print best fit solution================================================
printBinsB:
	li $t0, 0 # bin index
    	la $t1, binsizeB
    	la $t2, valuesInEachBinB
    	la $t9, numOfNeededBinsB
    	li $t6, 0 # count of used bins 
    	
    	li $t7, 1	
    	mtc1 $t7, $f4 # Move integer to float register
    	cvt.s.w $f4, $f4 # Convert integer to float
    	
print_binsB:
	lwc1 $f12, 0($t1) # load bin size
    	c.eq.s $f4, $f12 # if bin size == 1 -> not used -> no need to print 
    	bc1t skip_binB
    	
    	li $v0, 4 # print "Bin "
    	la $a0, label_bin
    	syscall

    	li $v0, 1 # print bin number
    	move $a0, $t0
    	syscall

    	li $v0, 4 # print ": Size = "
    	la $a0, label_size
    	syscall

   	li $v0, 2
   	lwc1 $f12, 0($t1)
    	syscall

    	li $v0, 4 # print ", Values: "
    	la $a0, label_values
    	syscall

    	li $t3, 0 # value index inside the bin (0 to 9)

print_valuesB:
    	beq $t3, 10, finish_binB

    	mul $t4, $t0, 40 # bin offset (10 values * 4 bytes)
    	mul $t5, $t3, 4 # value offset
    	add $t7, $t4, $t5
    	add $t7, $t7, $t2 # address = base t2+ offset[each value t3 * 4 + binoffset = 40 * index]

    	lwc1 $f12, 0($t7)
    
    	# Check if value is 0.0
    	mtc1 $zero, $f6 # $f6 = 0.0
    	c.eq.s $f12, $f6
    	bc1t skip_valueB
    
    	# Print value
    	li $v0, 2
    	syscall

    	li $v0, 4                  
    	la $a0, newspace
    	syscall
    	
skip_valueB:
    	addi $t3, $t3, 1 # value index ++
    	j print_valuesB
    	
finish_binB:
    	li $v0, 4
    	la $a0, newline
    	syscall
    	addi $t6, $t6, 1 # increment used bins
skip_binB:
    	addi $t0, $t0, 1 # bin index ++
    	addi $t1, $t1, 4 # next binsize since each bin is 4 byte 
    	li $t8, 10 # total number of bins
    	blt $t0, $t8, print_binsB
    
    	# Store number of used bins
    	sw $t6, 0($t9)
    	# Print used bin count
    	li $v0, 4                  
    	la $a0, lable_numOfBinsUsed
    	syscall

	li $v0 , 1
	move $a0, $t6 
	syscall 
	
	li $v0, 4  # print space
    	la $a0, newline
    	syscall
    
	j displayMainMenu
#====================================write to file==========================================================
write_to_file:
    	# Open file for writing
    	li $v0, 13
    	la $a0, output_file
    	li $a1, 1
    	syscall
    	move $s0, $v0
	
    	bltz $s0, failed

    	# File output logic (same as print_bins, but writing to file instead of printing)
	li $t0, 0 # bin index
    	la $t1, binsize
    	la $t2, valuesInEachBin
    	la $t9, numOfNeededBins
    	li $t6, 0 # count of used bins
    
    	li $t7, 1
    	mtc1 $t7, $f4 # Move integer to float register
    	cvt.s.w $f4, $f4 # Convert integer to float
    
file_print_bins:
    	lwc1 $f12, 0($t1) # load bin size
    	c.eq.s $f4, $f12  # if bin size == 1 -> no need to print
    	bc1t file_skip_bin
    
    	# Write "Bin " to file
    	li $v0, 15
    	move $a0, $s0 # File descriptor
    	la $a1, label_bin
   	li $a2, 4 # Length of "Bin "
    	syscall

    	# Write ": Size = " to file
    	li $v0, 15
    	move $a0, $s0
    	la $a1, label_size
    	li $a2, 8
    	syscall
    	
    	# Write ", Values: " to file
    	li $v0, 15
    	move $a0, $s0
    	la $a1, label_values
    	li $a2, 9
    	syscall

    	li $t3, 0 # Value index inside the bin (0 to 9)

file_print_values:
    	beq $t3, 10, file_finish_bin

    	# Compute value offset and load value
    	mul $t4, $t0, 40
    	mul $t5, $t3, 4
    	add $t7, $t4, $t5
    	add $t7, $t7, $t2
    	lwc1 $f12, 0($t7)

    	# Check if value is 0.0
    	mtc1 $zero, $f6
    	c.eq.s $f12, $f6
    	bc1t file_skip_value

    	# Write space after value
    	li $v0, 15
    	move $a0, $s0
    	la $a1, newspace
    	li $a2, 1
    	syscall

file_skip_value:
    	addi $t3, $t3, 1
    	j file_print_values

file_finish_bin:
    	# Write newline to file
    	li $v0, 15
    	move $a0, $s0
    	la $a1, newline
    	li $a2, 1
    	syscall

    	addi $t6, $t6, 1
    	
file_skip_bin:
    	addi $t0, $t0, 1
    	addi $t1, $t1, 4
    	li $t8, 10
    	blt $t0, $t8, file_print_bins

    	# Write used bins count to file
    	li $v0, 15
   	move $a0, $s0
    	la $a1, lable_numOfBinsUsed
    	li $a2, 35
    	syscall

    	# Close the file
    	li $v0, 16
    	move $a0, $s0
    	syscall
    	
    	li $v0, 4
    	la $a0, success
    	syscall
    	j displayMainMenu
failed:
    	li $v0, 4
    	la $a0, fail
    	syscall
#====================================end program============================================================
end_menu:
	li $v0, 10
	syscall

