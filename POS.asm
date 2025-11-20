; Mini POS System (MASM32)
; Simulates a simple retail checkout transaction
    
include C:\masm32\include\masm32rt.inc

.data

    
    ; Text Menu Header
    textMenu db "=== Mini POS System ===", 13, 10,
               "1. Coffee   - ₱50",13,10,
               "2. Donut    - ₱30",13,10,
               "3. Sandwich - ₱90",13,10,
               "Selection [1-3]: ", 0
                
    ; Receipt Structure
    receiptHeader db ""




.code

    start:

        push offset textMenu
        call StdOut

        

    end start
