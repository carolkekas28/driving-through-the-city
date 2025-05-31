.bss
STACK: .skip 1024
STACK_END: 
.set GPT_BASE, 0xFFFF0100
.set CAR_BASE, 0xFFFF0300
.set SERIAL_BASE, 0xFFFF0500

.text
.align 4

Syscall_set_engine_and_steering:
    # a0: movement direction, a1: steering wheel angle
    li t0, 0
    li t1, -1
    li t2, 1
    li t3, -127
    li t4, 127

    # Checking if steering wheel angle is valid value
    bgt a1, t4, invalid # a1 > 127
    blt a1, t3, invalid # a1 < -127

    # Checking if movement direction is a valid value
    bgt a0, t2, invalid # a0 > 1
    blt a1, t1, invalid # a0 < -1

    # All paramaters are valid and we procced to proccess them
    li s0, CAR_BASE # We load begin adress of car base in register s0
    addi s0, s0, 32 # Base+0x20
    sb a1, 0(s0) # Trigger wished movement direction angle
    addi s0, s0, 1 # Base+0x21
    sb a0, 0(s0) # Trigger movement direction
    mv a0, t0 # Return 0 if successful
    j end_interruption

    invalid:
    li t0, -1    
    mv a0, t0 # Return -1 in case any parameter is not valid
    j end_interruption


Syscall_set_handbrake:
    # a0: value stating if the hand brakes must be used
    li s0, CAR_BASE
    addi s0, s0, 34 # Base+0x22
    sb a0, 0(s0)
    j end_interruption


Syscall_read_sensors:
    # a0: adress of an array with 256 elements that will store values read by sensor
    li s0, CAR_BASE
    addi s0, s0, 1 # Base+0x01
    li t0, 1
    li t1, 256 # To iterate our array
    sb t0, 0(s0) # Store 1 in equivalent adress to trigger sensor luminosity

    luminosity_sensor_stop:
    lb t0, 0(s0)
    beq t0, x0, store_image # If its 0, the capture is completed
    j luminosity_sensor_stop

    store_image:
    mv a1, a0 # We store begin adress of array in register a0
    addi s0, s0, 35 # Base+0x24
    store_image_loop:
        beqz t1, capture_image_finished
        lb t0, 0(s0) # Load byte value
        sb t0, 0(a0) # Store it in equivalent position
        addi a0, a0, 1
        addi s0, s0, 1
        addi t1, t1, -1 # We do this 256 times
        j store_image_loop

    capture_image_finished:
    mv a0, a1 # We recover beggin adres of our array
    j end_interruption


Syscall_read_sensor_distance:
    li s0, CAR_BASE
    addi s0, s0, 2 # Base+0x02
    li t0, 1
    sb t0, 0(s0) # Trigger our ultrasonic sensor

    ultrasonic_sensor_stop:
    lb t0, 0(s0)
    beq t0, x0, store_distance # If it is 0, the measurement is completed
    j ultrasonic_sensor_stop

    store_distance:
    li s0, CAR_BASE
    addi s0, s0, 28 # Base+0x1C
    lw a0, 0(s0) # We load the distance read by our sensor
    li t0, -1
    beq t0, a0, no_obstacle # Checking if no obstacle was found
    j end_interruption

    no_obstacle:
    mv a0, t0 # Return -1 if no obstacle was found
    j end_interruption


Syscall_get_position:
    # a0: adress of variable that will store the value the value of x position
    # a1: " " " " " " " " " " " y position
    # a2: " " " " " " " " " " " z position
    li s0, CAR_BASE
    li t0, 1
    sb t0, 0(s0) # Trigger GPS device to start reading

    reading_GPS_stop_1:
    lb t0, 0(s0) # We check if this register was set to 0
    beq t0, x0, store_positions
    j reading_GPS_stop_1

    store_positions:
    addi s0, s0, 16 # Base+0x10
    lw t0, 0(s0)
    lw t1, 4(s0) # Base+0x14
    lw t2, 8(s0) # Base+0x18
    # We procced to store positions in its registers
    sw t0, 0(a0) 
    sw t1, 0(a1)
    sw t2, 0(a2)
    j end_interruption


Syscall_get_rotation:
    # a0: adress of variable that will store the Euler angle in x
    # a1:   "     "    "      "    "     "    "    "     "   "  y
    # a2:   "     "    "      "    "     "    "    "     "   "  z
    li s0, CAR_BASE
    li t0, 1
    sb t0, 0(s0) # Trigger GPS device to start reading

    reading_GPS_stop_2:
    lb t0, 0(s0) # We check if this register was set to 0
    beq t0, x0, store_angles
    j reading_GPS_stop_2

    store_angles:
    addi s0, s0, 4 # Base+0x04
    lw t0, 0(s0)
    lw t1, 4(s0) # Base+0x08
    lw t2, 8(s0) # Base+0x0c
    # We store angles in its registers
    sw t0, 0(a0)
    sw t1, 0(a1)
    sw t2, 0(a2)
    j end_interruption


Syscall_read_serial:
    # a0: buffer, a1: max size
    li s0, SERIAL_BASE
    li t1, 10 # Check newline caracter
    li t2, 0 # To count number of bytes that were read

    read_loop:
    beq t2, a1, read_finished # Check if buffer is full
    li t0, 1
    sb t0, 2(s0) # Triggers reading

    stop_reading:
    lb t0, 2(s0)
    beq t0, zero, continue_reading
    j stop_reading
    
    continue_reading:
    lbu t0, 3(s0)
    sb t0, 0(a0) # Store byte in equivalent position of buffer
    beq t1, t0, read_finished # Check if we reached a newline caracter
    beqz t0, read_finished # Check if we reached a null caracter
    addi a0, a0, 1 # Move to the next position of our buffer
    addi t2, t2, 1 # Increase number of read bytes
    j read_loop

    read_finished: 
    mv a0, t2
    j end_interruption


Syscall_write_serial:
    # a0: buffer, a1: max number of bytes to write
    li s0, SERIAL_BASE
    li t1, 0 # To count number of iterations
    li t3, 10

    write_loop:
    beq t1, a1, write_finished # Check if we have written max number of bytes
    lb t2, 0(a0) # Get first caracter of our buffer
    sb t2, 1(s0) # Store it in serial port base+0x01

    li t0, 1
    sb t0, 0(s0) # Triggers serial port to write

    stop_writing:
    lb t0, 0(s0)
    beq t0, zero, continue_writing
    j stop_writing
    
    continue_writing:
    addi a0, a0, 1
    addi t1, t1, 1 # Increase number of written bytes
    beq t2, t3, write_finished # Check if we have reached a newline character
    blt t1, a1, write_loop

    write_finished:
    j end_interruption


Syscall_get_systime:
    li s0, GPT_BASE
    li t0, 1 # Trigger GPT to read current system time
    sb t0, 0(s0) # Trigger activation

    stop_GPT:
    lb t0, 0(s0)
    beq t0, x0, procced_GPT_reading
    j stop_GPT

    procced_GPT_reading:
    lw a0, 4(s0) # Stores the time at the moment of the last reading by GPT
    j end_interruption


int_handler:
    csrrw sp, mscratch, sp # Changes sp to mscratch
    addi sp, sp, -40
    # sw a0, 0(sp)
    # sw a1, 4(sp)
    sw a2, 8(sp)
    sw a7, 12(sp)
    sw t0, 16(sp)
    sw t1, 20(sp)
    sw t2, 24(sp)
    sw t3, 28(sp)
    sw t4, 32(sp)
    sw s0, 36(sp)

    li t0, 10
    beq t0, a7, Syscall_set_engine_and_steering

    li t0, 11
    beq t0, a7, Syscall_set_handbrake

    li t0, 12
    beq t0, a7, Syscall_read_sensors

    li t0, 13
    beq t0, a7, Syscall_read_sensor_distance

    li t0, 15
    beq t0, a7, Syscall_get_position

    li t0, 16
    beq t0, a7, Syscall_get_rotation

    li t0, 17
    beq t0, a7, Syscall_read_serial

    li t0, 18
    beq t0, a7, Syscall_write_serial

    li t0, 20
    beq t0, a7, Syscall_get_systime

    end_interruption:
    lw s0, 36(sp)
    lw t4, 32(sp)
    lw t3, 28(sp)
    lw t2, 24(sp)
    lw t1, 20(sp)
    lw t0, 16(sp)
    lw a7, 12(sp)
    lw a2, 8(sp)
    # lw a1, 4(sp)
    addi sp, sp, 40

    csrrw sp, mscratch, sp

    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    mret

.globl _start 
.globl main
 
_start:
    li sp, 0x07FFFFFC


    la a0, STACK_END
    csrw mscratch, a0

    # Allow external interruptions
    csrr t1, mie # Set bit 11 (MEIE)
    li t2, 0x800
    or t1, t1, t2
    csrw mie, t1

    # Allow global interruptions
    csrr t1, mstatus # Set bit 3 (MIE)
    ori t1, t1, 0x8
    csrw mstatus, t1

    la a0, int_handler 
    csrw mtvec, a0      

    # Change to user mode
    jal user_main
    jal main

    ret

user_main:
    csrr t1, mstatus # Update the mstatus.MPP
    li t2, ~0x1800 # field (bits 11 and 12)
    and t1, t1, t2 # with value 00 (U-mode)
    csrw mstatus, t1
    la t0, main # Loads the user software
    csrw mepc, t0 # entry point into mepc
    mret # PC <= MEPC; mode <= MPP;
