; MiniMart POS System (MASM32)
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
    textMenu db "========= MiniMart POS System =========", 13,10,13,10
             db  "1. Coffee      - ₱39", 13,10
             db  "2. Donut       - ₱12", 13,10
             db  "3. Sandwich    - ₱15", 13,10
             db  "4. Milk        - ₱50", 13,10
             db  "5. Bread       - ₱25", 13,10
             db  "6. Chips       - ₱30", 13,10
             db  "7. Soda        - ₱20", 13,10
             db  "8. Juice       - ₱15", 13,10
             db  "9. Candy       - ₱5", 13,10
             db  "10. Egg        - ₱8", 13,10,13,10
             db  "Selection [1-10]: ", 0

    qtyPrompt db "Enter Quantity: ", 0
    anotherMsg db "Add another item? (Y/N): ",0 
    paymentMsg db "Payment Amount:   ₱",0

                
    ; ==== Receipt Messages ====
    receiptHdr db 13,10, "========= RECEIPT =========",0
    itemText db "Item ",0
    itemNames db "Coffee", 0,0,0,0     ; 6 chars + 4 nulls = 10 bytes (Index 0)
              db "Donut", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 1)
              db "Sandwich", 0,0       ; 8 chars + 2 nulls = 10 bytes (Index 2)
              db "Milk", 0,0,0,0,0,0   ; 4 chars + 6 nulls = 10 bytes (Index 3)
              db "Bread", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 4)
              db "Chips", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 5)
              db "Soda", 0,0,0,0,0,0   ; 4 chars + 6 nulls = 10 bytes (Index 6)
              db "Juice", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 7)
              db "Candy", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 8)
              db "Egg", 0,0,0,0,0,0    ; 3 chars + 7 nulls = 10 bytes (Index 9)
    priceText db " x ", 0
    atText    db " @ ₱", 0
    equalText db " = ₱", 0
    dashLine  db "--------------------------", 0
    subText   db "Sub Total:        ₱",0        
    taxText   db "VAT (12%):        ₱",0
    totalText db "Total Amount:     ₱",0
    dashLine2 db "===========================", 0
    paidText  db "Amount Paid:      ₱",0
    changeText db "Change:           ₱",0  

    ; ==== Response Messages ====
    insuffMsg db "Insufficient payment! Please pay at least ₱",0 
    thankYouMsg db "Thank you for your purchase!",0
    invalidMsg db"Invalid selection! Please pick the correct number"

    ; ==== Prices ====
    priceTable DWORD 39, 12, 15, 50, 25, 30, 20, 15, 5, 8

    ; ==== Buffers ====
    inputBuf        db 32 dup(0)
    itemIdx         DWORD ?
    price           DWORD ?
    quantity        DWORD ?
    itemTotal       DWORD ?
    runningTotal    DWORD 0
    itemCount       DWORD 0
    tax             DWORD ?
    finalTotal      DWORD ?
    payment         DWORD ?
    change          DWORD ?

    ; Store item details for receipt (max 10 items for now) 
    receiptItems    DWORD 10 dup(0)
    receiptQtys     DWORD 10 dup(0)
    receiptTotals   DWORD 10 dup(0)





.code

    start:

        mov runningTotal, 0
        mov itemCount, 0

        
    item_loop:
        
        ; ==== Display Shopping Cart Art ====;
        push offset shoppingCartArt
        call StdOut

        ; ==== Display Menu ====;
        push offset textMenu
        call StdOut
        
        ; ===== Read and Store item number =====
        push 32
        push offset inputBuf
        call StdIn 
        
        ; ==== Check if input is empty ====
        cmp byte ptr [inputBuf], 0
        je invalid_input

        ; ==== Convert input to int ====
        push offset inputBuf
        call atodw ; converts string to int
        jc invalid_input ; Jumps if input is not a number
        mov itemIdx, eax
 
        ; ===== Validate input (1-3) =====
        cmp eax, 1
        jl invalid_input
        cmp eax, 10
        jg invalid_input

        ; ==== Convert user selection to 0 based index ====
        dec eax
        mov itemIdx, eax

        ; ==== Fetch Price based on user selection ====
        mov ebx, itemIdx
        mov eax, priceTable[ebx*4]
        mov price, eax
        
    ; ==== Ask for item quantity and store it ====
    read_quantity:
        push offset qtyPrompt
        call StdOut
        
        push 32
        push offset inputBuf
        call StdIn
        
        ; ==== Validate quantity input ====
        cmp byte ptr [inputBuf], 0
        je invalid_input
        
        cmp inputBuf, 0
        jl invalid_input
        

        push offset inputBuf
        call atodw
        mov quantity, eax

        ; ==== Compute item subtotal ====
        mov eax, price
        mov ebx, quantity
        mul ebx
        

   
        jmp exit_program


    invalid_input:
        push offset invalidMsg
        call StdOut
        

    exit_program:
        invoke ExitProcess, 0
        

    end start
