; Mini POS System (MASM32)
; Simulates a simple retail checkout transaction
include C:\masm32\include\masm32rt.inc

.data

    ;Current Time and Date 
    LPSYSTEMTIME STRUCT
        wYear   WORD ?
        wMonth  WORD ?
        wDay    WORD ?
        wHour   WORD ?
        wMinute WORD ?
        wSecond WORD ?
    LPSYSTEMTIME ENDS

    localTime LPSYSTEMTIME <>




    ; ==== Shopping Cart ASCII Art ==== 
    shoppingCartArt  db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠈⠛⠻⠶⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠈⢻⣆⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⢻⡏⠉⠉⠉⠉⢹⡏⠉⠉⠉⠉⣿⠉⠉⠉⠉⠉⣹⠇⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠈⣿⣀⣀⣀⣀⣸⣧⣀⣀⣀⣀⣿⣄⣀⣀⣀⣠⡿⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠸⣧⠀⠀⠀⢸⡇⠀⠀⠀⠀⣿⠁⠀⠀⠀⣿⠃⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣧⣤⣤⣼⣧⣤⣤⣤⣤⣿⣤⣤⣤⣼⡏⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⠀⠀⢸⡇⠀⠀⠀⠀⣿⠀⠀⢠⡿⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣷⠤⠼⠷⠤⠤⠤⠤⠿⠦⠤⠾⠃⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢾⣷⢶⣶⠶⠶⠶⠶⠶⠶⣶⠶⣶⡶⠀⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣧⣠⡿⠀⠀⠀⠀⠀⠀⢷⣄⣼⠇⠀⠀⠀⠀⠀⠀⠀",13,10
                     db "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",13,10
                     db 13,10
                     db 0
    
    
    ; ==== Menu Text ====
textMenu db "========= MiniMart POS System =========", 13,10,13,10,
           "1. Coffee      - ₱39", 13,10,
           "2. Donut       - ₱12", 13,10,
           "3. Sandwich    - ₱15", 13,10,
           "4. Milk        - ₱50", 13,10,
           "5. Bread       - ₱25", 13,10,
           "6. Chips       - ₱30", 13,10,
           "7. Soda        - ₱20", 13,10,
           "8. Juice       - ₱15", 13,10,
           "9. Candy       - ₱5", 13,10,
           "10. Egg        - ₱8", 13,10,13,10,
           "Selection [1-10]: ", 0

    qtyPrompt db "Enter Quantity: ", 0
    anotherMsg db "Add another item? (Y/N): ",0 

                
    ; ==== Receipt Messages ====
    receiptHdr db 13,10, "========= RECEIPT =========",0
    itemText db "Item ",0
    ;itemNames db 


    ;input
    userInput db 50 dup(?) 

    ;output result
    userOutput db "Hello, you picked: ",0

    ;invalid input
    invalidInput db "Invalid, input. Please pick the correct number", 0

    ; ==== Buffers ==== 
    itemIdx DWORD ?

.code

    start:
        

        push offset shoppingCartArt
        call StdOut

        
        push offset textMenu
        call StdOut

        push 50
        push offset userInput
        call StdIn
        push offset userInput
        call atodw              ;converts string to int and return it as eax 
        mov itemIdx, eax

        cmp eax, 1
        jl invalid_input

        cmp eax, 3
        jg invalid_input

         

        push offset userOutput
        call StdOut

        push offset userInput
        call StdOut

        invoke ExitProcess,0


    invalid_input:
        push offset invalidInput
        call StdOut
        


    end start
