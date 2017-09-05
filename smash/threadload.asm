.arm

.macro call func
    ldr r6, =\func
    blx r6
.endm

.include "common.asm"
.equ base_addr,     0xA36000

.equ TO_LOAD, 0x0
.equ RESOURCE_ID, 0x4
.equ FILE_SIZE, 0x8
.equ BYTES_READ, 0xC

test:
     @Compensate for removing code
     sub sp, sp, #0x8
     mov r6, r0
     ldr r0, [r2, #0x4]
     
     @ Check RF flags
     push {r0-r6,lr}
        call get_rf_struct
        ldr r0, [r0, #0x8]
        tst r0, #0x8000 @ does this file have an SD override?
     pop {r0-r6,lr}
     bne exit
     
     push {r0-r8,lr}
         sub sp, sp, #0x20
         str r1, [sp, #TO_LOAD] @ Stash to-load address
         str r2, [sp, #RESOURCE_ID]
         
         ldr r0, =0x404
         call liballoc
         mov r8, r0
         add r7, r8, #0x20
         
         ldr r0, =mod_path+base_addr
         call strlen
         add r7, r7, r0
         
         ldr r1, [sp, #RESOURCE_ID]
         mov r0, r7
         sub r0, r0, #0x4
         call path_str
                  
         add r7, r8, #0x20
         
         ldr r0, =mod_path+base_addr
         call strlen
         mov r2, r0
         mov r0, r7
         ldr r1, =mod_path+base_addr
         call memcpy
               
         mov r0, r8
         call IFile_Init
         
         ldr r0, =sdmc+base_addr
         call mount_sdmc
         
         mov r0, r8
         mov r1, r7
         mov r2, #0x1
         call IFile_Open
         cmp r0, #0x0
         beq close_and_end @ SD file doesn't exist, exit and pretend it never happened.
         
         mov r0, r8
         call IFile_GetSize
         str r0, [sp, #FILE_SIZE]
         
         ldr r1, [sp, #TO_LOAD] @dst
         ldr r2, [sp, #FILE_SIZE] @size
         add r3, sp, #BYTES_READ @bytes_read
         mov r0, r8 @file
         call IFile_Read
end_read_sd:         
         mov r0, r8
         call IFile_Close 
         mov r0, r8
         call libdealloc
         add sp, sp, #0x20
     pop  {r0-r8,lr}
     
     b skip
     
close_and_end:
        mov r0, r8
        call IFile_Close     
close:
     mov r0, r8
     call libdealloc
     add sp, sp, #0x20
     pop  {r0-r8,lr}
     
exit:
     add lr, lr, #0x4
     bx lr
     
skip:
    add sp, sp, #0x8
    pop {r4-r8,lr}
    
skip_end:
    bx lr
    
.pool

.align 4
sdmc:       .asciz "sdmc:"
.align 4
sdmc_:      .asciz "sdmc"
.align 4
mod_path:   .asciz "sdmc:/saltysd/smash/"
