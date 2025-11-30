; MiniMart POS System (MASM32)
; Simulates a simple retail checkout transaction
include C:\masm32\include\masm32rt.inc
;include C:\irvine32\Irvine32.inc

.data

    ;Current Time and Date 
    LPSYSTEMTIME STRUCT
        wYear        WORD ?
        wMonth       WORD ?
        wDayOfWeek   WORD ?
        wDay         WORD ?
        wHour        WORD ?
        wMinute      WORD ?
        wSecond      WORD ?
        wMilliseconds WORD ?
    LPSYSTEMTIME ENDS

    localTime LPSYSTEMTIME <>


    ;==== JJRC Minimart ASCII Art ====
    jjrcMinimartArt db "         ____.    ____.___________________      _____  .__       .__                       __   ",13,10
                  db "        |    |   |    |\______   \_   ___ \    /     \ |__| ____ |__| _____ _____ ________/  |_ ",13,10
                  db "        |    |   |    | |       _/    \  \/   /  \ /  \|  |/    \|  |/     \\__  \\_  __ \   __\ ",13,10
                  db "    /\__|    /\__|    | |    |   \     \____ /    Y    \  |   |  \  |  Y Y  \/ __ \|  | \/|  |  ",13,10
                  db "    \________\________| |____|_  /\______  / \____|__  /__|___|  /__|__|_|  (____  /__|   |__|  ",13,10
                  db "                               \/        \/          \/        \/         \/     \/              ",13,10,0

    ; ==== Minimart Option ====
    minimartOption db 13,10,"========= JJRC Minimart =========",13,10
                   db "1. Inventory",13,10
                   db "2. Summary",13,10
                   db "3. POS", 13,10, 13,10
                   db "Selection [1-3]: ", 0


    ; ==== Stock Messages ====
    outOfStockMsg db "Sorry, this item is out of stock!", 13,10,0
    insufficientStockMsg db "Insufficient stock! Only ",0
    availableMsg db " available", 13, 10, 0
    stockPrompt db " (Stock: ",0
    closeParen db ")", 0


    

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
    paymentMsg db 13,10,"Payment Amount:   ₱",0

                
    ; ==== Receipt Messages ====
    receiptHdr db 13,10, "========= RECEIPT =========",13,10,0
    dateText db "Date: ",0
    timeText db "   Time: ",0
    dateTimeBuf db 64 dup(0)
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
    colonText db ": ", 0
    dashLine  db "--------------------------", 13,10, 0
    subText   db "Sub Total:        ₱",0        
    taxText   db "VAT (12%):        ₱",0
    totalText db "Total Amount:     ₱",0
    dashLine2 db "===========================", 13,10,0
    paidText  db "Amount Paid:      ₱",0
    changeText db "Change:           ₱",0  

    ; ==== Response Messages ====
    insuffMsg db "Insufficient payment! Please pay at least ₱",0 
    thankYouMsg db "Thank you for your purchase!",13,10,0
    invalidSelectionMsg db "Invalid selection! Please enter the correct number: ", 0
    invalidQuantityMsg db "Invalid Quantity! Please enter a positive number", 13, 10, 0
    invalidTypeMsg db "Please input a number!", 13,10, 0
    invalidPay db "Invalid payment! Please enter a valid amount", 13, 10, 0



    ; ==== Prices ====
    priceTable DWORD 39, 12, 15, 50, 25, 30, 20, 15, 5, 8

    ; ==== Stock ====
    stockTable DWORD 10, 10, 10, 10, 10, 10, 10, 10, 10, 10

    ; ==== Buffers ====
    inputBuf        db 32 dup(0)
    itemIdx         DWORD ?
    optionIdx       DWORD ?
    price           DWORD ?
    stock           DWORD ?
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


    ; some command for the clear screen
    clsCmd db "cls", 0



.code

    start_minimart: 
        ; ==== Display JJRC Minimart Art ====;
        push offset jjrcMinimartArt
        call StdOut
        
        option_loop:
            ; ==== Display JJRC Menu ====
            push offset minimartOption
            call StdOut
        
        read_option:
        
            ; ==== Read and store user input ====
            push 32
            push offset inputBuf
            call StdIn

            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_selection_input_minimart

            ; ==== Convert input to int ====
            push offset inputBuf
            call atodw ; converts string to int
            jc invalid_type_input_minimart ; Jumps if input is not a number
            mov optionIdx, eax
            
            ; ==== Validate input (1-3) ====
            cmp eax, 1
            jl invalid_selection_input_minimart
            cmp eax, 3
            jg invalid_selection_input_minimart

            cmp eax, 1
            je start_inventory
            cmp eax, 2
            je start_summary
            cmp eax, 3
            je start_pos
             
        invalid_selection_input_minimart:
            push offset invalidSelectionMsg
            call StdOut
            jmp read_option
            
        invalid_type_input_minimart:
            push offset invalidTypeMsg
            call StdOut
            jmp read_option

    start_inventory:

    start_summary:

    start_pos:

        mov runningTotal, 0
        mov itemCount, 0

        ; ==== Display Shopping Cart Art ====;
        push offset shoppingCartArt
        call StdOut
        
        item_loop:
            
            ; ==== Display Menu ====;
            push offset textMenu
            call StdOut

        read_item: 
            ; ===== Read and Store item number =====
            push 32
            push offset inputBuf
            call StdIn 
            
            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_selection_input

            ; ==== Convert input to int ====
            push offset inputBuf
            call atodw ; converts string to int
            jc invalid_type_input ; Jumps if input is not a number
            mov itemIdx, eax
     
            ; ===== Validate input (1-10) =====
            cmp eax, 1
            jl invalid_selection_input
            cmp eax, 10
            jg invalid_selection_input

            ; ==== Convert user selection to 0 based index ====
            dec eax
            mov itemIdx, eax

            ; ==== Fetch Price based on user selection ====
            mov ebx, itemIdx
            mov eax, priceTable[ebx*4]
            mov price, eax

            ; ==== Check if item is in stock ====
            ; TODO: To be implemented
            mov ebx, itemIdx
            mov eax, stockTable[ebx*4]

            cmp eax, 0
            je out_of_stock_error
            
            mov stock, eax
            

            
        ; ==== Ask for item quantity and store it ====
        read_quantity:
            push offset qtyPrompt
            call StdOut
            
            push 32
            push offset inputBuf
            call StdIn
            
            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_quantity_input
            
            ; ==== Validate that input contains only digits ====
            mov esi, offset inputBuf
            validate_digit_loop:
                mov al, [esi]
                cmp al, 0                    ; End of string?
                je digits_valid
                cmp al, 13                   ; Carriage return?
                je digits_valid
                cmp al, 10                   ; Line feed?
                je digits_valid
                cmp al, '0'                  ; Less than '0'?
                jb invalid_quantity_input
                cmp al, '9'                  ; Greater than '9'?
                ja invalid_quantity_input
                inc esi
                jmp validate_digit_loop
            
        digits_valid:
            ; ==== Convert input to integer ====
            push offset inputBuf
            call atodw
            jc invalid_quantity_input
            
            ; ==== Check if quantity is less than or equal to 0. That means its a negative number ====
            cmp eax, 0
            jle invalid_quantity_input
            
            ; ==== Check if requested quantity exceeds available stock ====
            mov ebx, itemIdx
            mov ecx, stockTable[ebx*4] ; Gets current stock
            cmp eax, ecx
            jg insufficient_stock_error
            

            mov quantity, eax

            ; ==== Compute item subtotal ====
            mov eax, price
            mov ebx, quantity
            mul ebx
            mov itemTotal, eax

            ; ==== Add to running total ====
            mov eax, runningTotal
            add eax, itemTotal
            mov runningTotal, eax

            ; ==== Store item details for receipt ====
            mov eax, itemCount
            mov ebx, itemIdx
            mov receiptItems[eax*4],ebx
            mov ebx, quantity
            mov receiptQtys[eax*4],ebx
            mov ebx, itemTotal
            mov receiptTotals[eax*4],ebx
            
            ;==== Increase Item Count ====
            inc itemCount
            
            ; ==== Ask if user wants another item ====
            push offset anotherMsg
            call StdOut

            push 32
            push offset inputBuf
            call StdIn

            mov al, byte ptr [inputBuf]
            cmp al, 'Y'
            jne check_lowercase
            invoke crt_system, addr clsCmd
            jmp item_loop

        check_lowercase:
            cmp al, 'y'
            jne compute_tax
            invoke crt_system, addr clsCmd
            jmp item_loop

        compute_tax:
            
            ; ==== Compute TAX (12%) ====
            mov eax, runningTotal
            mov ebx, 12
            mul ebx
            mov ebx, 100
            xor edx, edx
            div ebx
            mov tax, eax

            ; ==== Compute FINAL TOTAL ====
            mov eax, runningTotal
            add eax, tax
            mov finalTotal, eax

            ; ==== Display total before payment ====
            invoke StdOut, chr$(13,10)
            invoke StdOut, addr totalText
            invoke StdOut, str$(finalTotal)
            invoke StdOut, chr$(13,10)
            
            payment_loop:
                
                ; ==== Ask for payment ====
                push offset paymentMsg
                call StdOut
                
                push 32
                push offset inputBuf
                call StdIn
                
                ; ==== Input validation ====
                cmp byte ptr [inputBuf], 0
                je invalid_payment_input

                cmp byte ptr [inputBuf], '-'
                je invalid_payment_input
            
                ; ==== Validate that payment input contains only digits ====
                mov esi, offset inputBuf
                validate_payment_loop:
                    mov al, [esi]
                    cmp al, 0                    ; End of string?
                    je valid_payment
                    cmp al, 13                   ; Carriage return?
                    je valid_payment
                    cmp al, 10                   ; Line feed?
                    je valid_payment
                    cmp al, '0'                  ; Less than '0'?
                    jb invalid_payment_input
                    cmp al, '9'                  ; Greater than '9'?
                    ja invalid_payment_input
                    inc esi
                    jmp validate_payment_loop

                valid_payment:
                                    
                    push offset inputBuf
                    call atodw
                    mov payment, eax

                    ; ==== Checks if payment is less than or equal to 0 ====
                    cmp eax, 0
                    jle invalid_payment_input

                    ; ==== Checks if payment amount is less than total amount ====
                    cmp eax, finalTotal
                    jl insufficient_payment
                
                    ; ==== Calculate Change ====
                    sub eax, finalTotal
                    mov change, eax
                    
                    ; ==== Print Receipt ==== 
                    push offset receiptHdr
                    call StdOut

                    ; ==== Get and Display Date/Time ====
                    invoke GetLocalTime, addr localTime
                    
                    ; ==== Format Date: YYYY-MM-DD ====
                    movzx eax, localTime.wYear
                    movzx ebx, localTime.wMonth
                    movzx ecx, localTime.wDay
                    invoke wsprintf, addr dateTimeBuf, chr$("Date: %04d-%02d-%02d"), eax, ebx, ecx
                    
                    ; ==== Format Time: HH:MM AM/PM ====
                    ; Convert hour to 12-hour format and determine AM/PM
                    movzx eax, localTime.wHour
                    movzx ebx, localTime.wMinute
                    mov edx, 0           ; 0 = AM, 1 = PM
                    
                    cmp eax, 12
                    jl time_am_check
                    je time_noon
                    sub eax, 12
                    mov edx, 1          ; PM (hours 13-23 are afternoon/evening)
                    jmp time_format
                time_noon:
                    mov eax, 12
                    mov edx, 1          ; PM (12:00 is noon)
                    jmp time_format
                time_am_check:
                    cmp eax, 0
                    jne time_format
                    mov eax, 12
                    mov edx, 0          ; AM (0:00 is midnight)
                time_format:
                    ; Save converted hour and minute before calculating buffer position
                    push eax             ; Save converted hour (12-hour format)
                    push ebx             ; Save minute
                    
                    ; Get current length of dateTimeBuf and append time
                    push offset dateTimeBuf
                    call lstrlen
                    mov esi, offset dateTimeBuf
                    add esi, eax
                    
                    ; Restore hour and minute values
                    pop ebx              ; minute
                    pop eax              ; converted hour (12-hour format)
                    
                    ; Format and append time
                    cmp edx, 0
                    je append_am
                    invoke wsprintf, esi, chr$("   Time: %02d:%02d PM"), eax, ebx
                    jmp time_done
                append_am:
                    invoke wsprintf, esi, chr$("   Time: %02d:%02d AM"), eax, ebx
                time_done:
                    ; ==== Print Date/Time ====
                    push offset dateTimeBuf
                    call StdOut
                    invoke StdOut, chr$(13,10)
                    
                    ; ==== Print Dash Line ====
                    push offset dashLine
                    call StdOut

            ; ==== Counter ====
            mov esi, 0

        print_items:
            cmp esi, itemCount
            jge print_totals

            ; ==== Print "Item " ====
            push offset itemText
            call StdOut
            
            ; ==== Print Item Number ====
            mov eax, esi
            inc eax
            invoke StdOut, str$(eax)
            
            ; ==== Print ": " ====
            push offset colonText
            call StdOut

            ; ==== Print Item Name ====
            mov eax, receiptItems[esi*4]
            mov ebx, 10
            mul ebx
            lea ebx, itemNames
            add ebx, eax
            invoke StdOut, ebx
            
            ; ==== Print Quantity Of the Item ====
            push offset priceText
            call StdOut
            invoke StdOut, str$(receiptQtys[esi*4])
            
            ; ==== Print Price Of the Item ====
            push offset atText
            call StdOut
            mov eax, receiptItems[esi*4]
            mov ebx, priceTable[eax*4]
            invoke StdOut, str$(ebx)

            ; ==== Print Item Total ====
            push offset equalText
            call StdOut
            invoke StdOut, str$(receiptTotals[esi*4])
            invoke StdOut, chr$(13,10)

            ; ==== Increase count ====
            inc esi

            ; ==== Loop back to print_items label ====
            jmp print_items


        print_totals:
            ;==== Print Separator ==== 
            push offset dashLine
            call StdOut

            ; ==== Print Subtotal ====
            push offset subText
            call StdOut
            invoke StdOut, str$(runningTotal)
            invoke StdOut, chr$(13,10)

            ; ==== Print Tax Amount ====
            push offset taxText
            call StdOut
            invoke StdOut, str$(tax)
            invoke StdOut, chr$(13,10)
            
            ;==== Print Separator ==== 
            push offset dashLine
            call StdOut
            
            ; ==== Print Final Total ====
            push offset totalText
            call StdOut
            invoke StdOut, str$(finalTotal)
            invoke StdOut, chr$(13,10)
            
            ;==== Print Separator ==== 
            push offset dashLine2
            call StdOut
            

            ; ==== Print Payment Details ====
            push offset paidText
            call StdOut
            invoke StdOut, str$(payment)
            invoke StdOut, chr$(13,10)
            
            push offset changeText
            call StdOut
            invoke StdOut, str$(change)
            invoke StdOut, chr$(13,10)
            
            ; ==== Print Thank you message ====
            push offset thankYouMsg
            call StdOut
            
            jmp exit_program

        out_of_stock_error:
            push offset outOfStockMsg
            call StdIn

            jmp item_loop

        insufficient_stock_error:
            push offset insufficientStockMsg
            call StdOut

            mov ebx, stock
            invoke StdOut, str$(stock)
            
            push offset availableMsg
            call StdOut
            
            jmp read_quantity
            

        invalid_selection_input:
            push offset invalidSelectionMsg
            call StdOut

            jmp read_item
            
        invalid_quantity_input:
            push offset invalidQuantityMsg
            call StdOut

            jmp read_quantity

        invalid_type_input:
            push offset invalidTypeMsg
            call StdOut

            jmp read_item

        invalid_payment_input:
            push offset invalidPay
            call StdOut
            
            jmp payment_loop
        
        insufficient_payment:
            push offset insuffMsg
            call StdOut
            invoke StdOut, str$(finalTotal)
            
            jmp payment_loop

        exit_program:
            invoke ExitProcess, 0
            

    end start_minimart
    ;TODO: CLS every new item - Done
    ; put Stocks on items
    ; add item
    ; dashboard
    ; add a create file for each receipt
