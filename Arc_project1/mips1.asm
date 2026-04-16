##########################
# Data Section
##########################
.data
input_buffer: .space 50
buffer: .space 300
matrixData: .space 25
output: .asciiz "outputFile.txt"
newline: .asciiz "\n"
space: .asciiz " "
msg_input: .asciiz "Enter input file name/path: "
msg_error: .asciiz "Error opening file\n"
msg_debug: .asciiz "Matrix read: \n"
msg_size: .asciiz "Maximum clique size: "
msg_vertices: .asciiz "Vertices in maximum clique: "
msg_invalid: .asciiz "Error: Matrix is invalid \n"
msg_valid: .asciiz "Matrix is valid\n"
msg_no_clique: .asciiz "No clique found\n" 
msg_debug_n: .asciiz "n = "
n: .word 5
max_size: .word 0
max_subset: .word 0

##########################
# Text Section
##########################
.text
.globl main
main:
    # User interface
    li $v0, 4#load on v0
    la $a0, msg_input#load the msg input on reg a0
    syscall#systen call 4 (print on concole)

    li $v0, 8#load on v0 8 
    la $a0, input_buffer#to read input and save it on the input buffer at a0
    li $a1, 50#size for input input
    syscall

    # strip newline
    la $a0, input_buffer
strip_loop:
    lb $t0, 0($a0)
    beqz $t0, strip_done#end of file (/0==0)
    li $t1, 10
    beq $t0, $t1, set_zero
    addi $a0, $a0, 1
    j strip_loop
set_zero:
    sb $zero, 0($a0)
strip_done:

    #open input file
    li $v0, 13
    la $a0, input_buffer
    li $a1, 0
    syscall
    move $s0, $v0
    bltz $s0, file_error#func called file error

    #read from file
    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 300
    syscall

    # cloas input file
    li $v0, 16
    move $a0, $s0
    syscall

    # DYNAMIC MATRIX READING 
    la $t0, buffer
    la $t1, matrixData
    li $t3, 0                    # elements counter
    li $s6, 1                    # valid flag
    li $s7, 0                    # matrix size n initial =0
    
    # Determine n from first row
    li $t9, 0                    # count numbers in header
read_header_for_n:
    lb $t4, 0($t0)
    beqz $t4, header_done
    li $t5, 10# in ASCII 10 =/n (new line)
    beq $t4, $t5, header_done
    
    li $t5, 48#in ascii 48=0
    blt $t4, $t5, not_header_digit
    li $t5, 57  #in ASCII 57=9
    bgt $t4, $t5, not_header_digit
    addi $t9, $t9, 1
    
not_header_digit:
    addi $t0, $t0, 1#t0 have the buffer which have the input file data
    j read_header_for_n

header_done:
    move $s7, $t9
    sw $s7, n# size for the matix n*n
    
    # Validate n range (1-5)
    li $t5, 1
    blt $s7, $t5, matrix_invalid
    li $t5, 5
    bgt $s7, $t5, matrix_invalid
    
    addi $t0, $t0, 1

    # Read matrix elements
    li $t3, 0                    # reset counter
    li $t6, 0                    # row counter
process_rows_dynamic:
    beq $t6, $s7, read_done
    li $t9, 0                    # column counter
    
skip_row_header:
    lb $t4, 0($t0)
    beqz $t4, read_done
    li $t5, 32
    beq $t4, $t5, row_header_skipped
    li $t5, 9
    beq $t4, $t5, row_header_skipped
    addi $t0, $t0, 1
    j skip_row_header

row_header_skipped:
    addi $t0, $t0, 1

process_row_dynamic:
    beq $t9, $s7, next_row#if new line go to the next row
    lb $t4, 0($t0)
    beqz $t4, read_done#if eq 0 go the function read_done
    
    li $t5, 32# if space 
    beq $t4, $t5, skip_char
    li $t5, 9#if tap
    beq $t4, $t5, skip_char
    
    li $t5, 48#if eq 0
    beq $t4, $t5, store_precise
    li $t5, 49#if == 1
    beq $t4, $t5, store_precise
    
    li $s6, 0
    j skip_char

store_precise:
    subi $t4, $t4, 48#sub 48 to convert it to 0 or 1
    sb $t4, 0($t1)#store byte in matrix data location 
    addi $t1, $t1, 1#next location
    addi $t3, $t3, 1#next read location
    addi $t9, $t9, 1

skip_char:
    addi $t0, $t0, 1
    j process_row_dynamic

next_row:
    lb $t4, 0($t0)
    beqz $t4, read_done
    li $t5, 10#new line
    beq $t4, $t5, found_newline
    addi $t0, $t0, 1
    j next_row

found_newline:
    addi $t0, $t0, 1
    addi $t6, $t6, 1
    j process_rows_dynamic

read_done:
    beqz $s6, matrix_invalid#if s6(validation flag )==0 go to invalid matrix fuction
    
    mul $t0, $s7, $s7
    bne $t3, $t0, matrix_invalid#if the size counted berfor does not match elements counted so far call invalid matrix function
    j matrix_verified

matrix_invalid:
    li $v0, 4
    la $a0, msg_invalid
    syscall
    li $v0, 10
    syscall

matrix_verified:
    li $v0, 4
    la $a0, msg_valid
    syscall

    # print matrix
    li $v0, 4
    la $a0, msg_debug
    syscall

    li $v0, 4
    la $a0, msg_debug_n
    syscall
    lw $a0, n
    li $v0, 1
    syscall
    li $v0, 11
    li $a0, '\n'
    syscall
    
    la $t0, matrixData
    li $t1, 0
    lw $t2, n
    mul $t5, $t2, $t2
debug_loop:
    bge $t1, $t5, debug_done
    lb $a0, 0($t0)
    li $v0, 1
    syscall
    li $v0, 11
    li $a0, ' '
    syscall
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    div $t1, $t2
    mfhi $t3
    bnez $t3, debug_loop
    li $v0, 11
    li $a0, '\n'
    syscall
    j debug_loop
debug_done:

    #Open output file 
    li $v0, 13
    la $a0, output
    li $a1, 1
    syscall
    move $s3, $v0
    bltz $s3, file_error

    #Call max clique algorithm
    jal find_max_clique
    jal write_max_clique_results

    # Close output file
    li $v0, 16
    move $a0, $s3
    syscall

    li $v0, 10
    syscall

file_error:
    li $v0, 4#
    la $a0, msg_error#print error msg on the console
    syscall
    li $v0, 10#close the programe
    syscall

##########################
# Max Clique Algorithm (i < j)
##########################
find_max_clique:
    addi $sp, $sp, -32#
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $ra, 28($sp)
    
    lw   $s2, n
    sw   $zero, max_size
    sw   $zero, max_subset
    
    li $t0, 2
    blt $s2, $t0, no_clique_final
    
    li $s1, 1
    move $t2, $s2
calc_2n:
    beqz $t2, calc_2n_done
    sll $s1, $s1, 1
    addi $t2, $t2, -1
    j calc_2n
calc_2n_done:
    
    li $s0, 0

final_search:
    beq  $s0, $s1, final_done
    
    move $t4, $s0
    li $t5, 0
final_count:
    beq  $t4, $zero, final_count_done
    andi $t6, $t4, 1
    add  $t5, $t5, $t6
    srl  $t4, $t4, 1
    j    final_count
final_count_done:
    move $s3, $t5

    lw   $t8, max_size
    ble  $s3, $t8, final_next

    # --- clique checking ---
    li   $s4, 1
    li   $s5, 0
final_i:
    bge  $s5, $s2, final_check_done
    li   $t7, 1
    sllv $t8, $t7, $s5
    and  $t9, $s0, $t8
    beqz $t9, final_next_i

    addi $s6, $s5, 1
final_j:
    bge  $s6, $s2, final_next_i
    li   $t7, 1
    sllv $t8, $t7, $s6
    and  $t9, $s0, $t8
    beqz $t9, final_next_j

    mul  $t4, $s5, $s2
    add  $t4, $t4, $s6
    la   $t5, matrixData
    add  $t5, $t5, $t4
    lb   $t6, 0($t5)
    beqz $t6, final_not_clique

final_next_j:
    addi $s6, $s6, 1
    j final_j

final_next_i:
    addi $s5, $s5, 1
    j final_i

final_not_clique:
    li $s4, 0

final_check_done:
    beqz $s4, final_next
    sw   $s3, max_size
    sw   $s0, max_subset

final_next:
    addi $s0, $s0, 1
    j final_search

no_clique_final:
    sw $zero, max_size
    sw $zero, max_subset

final_done:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra
write_max_clique_results:
    lw $t0, max_size
    beqz $t0, write_no_clique
    
    # Write "Maximum clique size: "
    li $v0, 15
    move $a0, $s3
    la $a1, msg_size
    li $a2, 21
    syscall

    # Write max_size
    lw $t0, max_size
    addi $t0, $t0, 48   # convert max_size to ASCII
    sb $t0, buffer
    li $v0, 15
    move $a0, $s3
    la $a1, buffer
    li $a2, 1
    syscall

    # newline
    li $v0, 15
    move $a0, $s3
    la $a1, newline
    li $a2, 1
    syscall

    # Write "Vertices in maximum clique: "
    li $v0, 15
    move $a0, $s3
    la $a1, msg_vertices
    li $a2, 28
    syscall

    # Write vertices in clique (0-based)
    lw  $t0, max_subset
    lw  $t3, n
    li  $t4, 0
    li  $t9, 0

write_vertices_loop:
    bge $t4, $t3, write_done
    
    li   $t5, 1
    sllv $t6, $t5, $t4
    and  $t7, $t0, $t6
    beqz $t7, next_vertex

    beqz $t9, no_space
    li $v0, 15
    move $a0, $s3
    la $a1, space
    li $a2, 1
    syscall
no_space:
    addi $t8, $t4, 48   # <-- changed here: 0-based, no +1
    sb $t8, buffer
    li $v0, 15
    move $a0, $s3
    la $a1, buffer
    li $a2, 1
    syscall
    li $t9, 1

next_vertex:
    addi $t4, $t4, 1
    j write_vertices_loop

write_no_clique:
    li $v0, 15
    move $a0, $s3
    la $a1, msg_no_clique
    li $a2, 16
    syscall

write_done:
    li $v0, 15
    move $a0, $s3
    la $a1, newline
    li $a2, 1
    syscall
    jr $ra
