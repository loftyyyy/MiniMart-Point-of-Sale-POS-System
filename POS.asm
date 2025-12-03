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

    ; ==== File handling ====
    stockFileName db "stock.dat", 0
    fileHandle DWORD ?
    bytesRead DWORD ?
    bytesWritten DWORD ?

    ; ==== Dynamic Item Structure ====
    ; Each item: [Name(32 bytes)][Price(4 bytes)][Stock(4 bytes)] = 40 bytes per item syet
    MAX_ITEMS equ 50    ;Only 50 items max
    ITEM_SIZE equ 40    ; size of the entire item structure
    NAME_SIZE equ 32    ; 32 bytes for each item name

    itemDatabase db MAX_ITEMS * ITEM_SIZE dup(0)
    currentItemcount DWORD 10 ;Default with 10 items

    ;==== File Names ====
    inventoryFileName db "inventory.dat", 0
    configFileName db "config.dat",0

    ; ==== Temporary buffers for item operations ====
    tempName db NAME_SIZE dup(0)
    tempPrice DWORD ?
    tempStock DWORD ?

    ; ===== Add Item menu and messages ====
    addItemMenu db 13,10,"========= Add New Item =========",13,10
                db "Enter item details:", 13,10, 0
    namePrompt db "Item Name: ",0
    pricePrompt db "Price (₱): ",0
    stockPrompt db "Initial Stock: ", 0
    itemAddedMsg db "Item added succesffully!",13,10,0
    inventoryFullMsg db "Inventory is full! Cannot add more items!"13,10,0

    ; ==== Inventory Display ====
    inventoryHeader db 13,10,"========= Current Inventory =========",13,10,0
    inventoryNum db "ID: ",0
    nameLabel db " | Name: ",0
    priceLabel db " | Price: ₱",0
    stockLabel db " | Stock: ",0
    noItemsMsg db "No items in inventory.",13,10,0


    ;==== JJRC Minimart ASCII Art ====
    jjrcMinimartArt db "         ____.    ____.___________________      _____  .__       .__                       __   ",13,10
                  db "        |    |   |    |\______   \_   ___ \    /     \ |__| ____ |__| _____ _____ ________/  |_ ",13,10
                  db "        |    |   |    | |       _/    \  \/   /  \ /  \|  |/    \|  |/     \\__  \\_  __ \   __\ ",13,10
                  db "    /\__|    /\__|    | |    |   \     \____ /    Y    \  |   |  \  |  Y Y  \/ __ \|  | \/|  |  ",13,10
                  db "    \________\________| |____|_  /\______  / \____|__  /__|___|  /__|__|_|  (____  /__|   |__|  ",13,10
                  db "                               \/        \/          \/        \/         \/     \/              ",13,10,0

    ;==== Minimart Option ====
    minimartOption db 13,10,"========= JJRC Minimart =========",13,10
                   db "1. View Inventory",13,10
                   db "2. Add New Item",13,10
                   db "3. POS (Point of Sale)", 13,10
                   db "4. Exit", 13,10, 13,10
                   db "Selection [1-4]: ", 0



    ; ==== Inventory Option ====
    inventoryOption db 13,10,"=========  Inventory ========= ", 13,10
                    db "1. Add new Item",13,10
                    db "2. Update Stock",13,10
                    db "3. Show Items with Stock",13,10
                    db "0. Exit",13,10
                    db "Selection [1-3]: ", 0
    


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


    ; ==== File error messages ====
    fileErrorMsg db "Warning: Could not load stock data. Using defaults.", 13, 10, 0
    fileSaveErrorMsg db "Warning: Could not save stock data.", 13, 10, 0


    ; ==== Stock Messages ====
    outOfStockMsg db "Sorry, this item is out of stock!", 13,10,0
    insufficientStockMsg db "Insufficient stock! Only ",0
    availableMsg db " available", 13, 10, 0
    stockPrompt db " (Stock: ",0
    closeParen db ")", 0


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
        ; ==== Load inventory at startup ====
        call LoadInventory 


        ; ==== Clear Console Screen ====
        invoke crt_system, addr clsCmd

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
            je start_add_item
            cmp eax, 3
            je start_pos
            cmp eax, 4
            je exit_program
             
        invalid_selection_input_minimart:
            push offset invalidSelectionMsg
            call StdOut
            jmp read_option
            
        invalid_type_input_minimart:
            push offset invalidTypeMsg
            call StdOut
            jmp read_option

    start_inventory:     
        call DisplayInventory
        invoke crt_system, chr$("pause")
        invoke crt_system, addr clsCmd
        jmp option_loop
        
        start_add_item:
            call AddNewItem
            invoke crt_system, chr$("pause")
            invoke crt_system, addr clsCmd
            jmp option_loop
        

    start_summary:

    start_pos:

        mov runningTotal, 0
        mov itemCount, 0

        ; ==== Display Shopping Cart Art ====;
        push offset shoppingCartArt
        call StdOut
        
        item_loop:
            
            ; ==== Display Dynamic Menu ====;
            call DisplayDynamicMenu

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
     
            ; ===== Validate against current item count =====
            cmp eax, 1
            jl invalid_selection_input
            mov ebx, currentItemCount
            cmp eax, ebx
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

            ; ==== Decrease Stock ====
            mov eax, itemIdx
            mov ebx, quantity
            mov ecx, stockTable[eax*4]
            sub ecx, ebx
            mov stockTable[eax*4], ecx
            
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
            


        invalid_inventory_selection_input:
            push offset invalidSelectionMsg
            call StdOut
            
            jmp read_inventory_item
            
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
            
    ; ========================================
    ; Initialize Default Items
    ; ========================================
    InitializeDefaultItems PROC
        LOCAL itemOffset:DWORD
        

        ;Item 0: Coffee
        mov itemOffset, 0
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Coffee")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 39 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 50 ; item Stock

        ;Item 1: Donut
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Donut")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 12 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 100 ; item Stock
        
        ;Item 2: Sandwich
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Sandwich")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 15 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 75 ; item Stock
    
        ;Item 3: Milk
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Milk")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 50 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 40 ; item Stock

        ;Item 4: Bread
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Bread")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 25 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 60 ; item Stock

        ;Item 5: Chips
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Chips")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 30 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 80 ; item Stock

        ;Item 6: Soda
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Soda")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 20 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 90 ; item Stock

        ;Item 7: Juice
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Juice")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 15 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 70 ; item Stock

        ;Item 8: Candy
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Candy")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 5 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 150 ; item Stock
    
        ;Item 9: Egg
        add itemOffset, ITEM_SIZE
        invoke lstrcpy, addr itemDatabase[itemOffset], chr$("Egg")
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE], 8 ; item Price
        mov DWORD PTR itemDatabase[itemOffset + NAME_SIZE + 4], 120 ; item Stock

        mov currentItemCount, 10
        ret

    InitializeDefaultItems ENDP

    ; ========================================
    ; Load Inventory from File
    ; ========================================
    LoadInventory PROC
        LOCAL bytesToRead:DWORD
        
        ;Trying to open inventory file
        invoke CreateFile, addr inventoryFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRUBTE_NORMAL, NULL

        cmp eax, INVALID_HANDLE_VALUE
        je load_default
        mov fileHandle, eax

        ; Read item count first
        invoke ReadFile, fileHandle, addr currentItemCount, 4, addr bytesRead, NULL
        
        ; Calculate bytes to read for al items
        mov eax, currentItemCount
        mov ebx, ITEM_SIZE
        mul ebx
        mov bytesToRead, eax

        ; Read all items
        invoke ReadFile, fileHandle, addr itemDatabase, bytesToRead, add bytesRead, Null

        invoke CloseHandle, fileHandle
        ret
        
        load_default:
            call InitializeDefaultItems
            ret
    


        
    LoadInventory ENDP
    
    ; ========================================
    ; Save Inventory to File
    ; ========================================   

    SaveInventory PROC
        LOCAL bytesToWrite:DWORD

        invoke CreateFile, addr inventoryFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE
    je save_failed
    mov fileHandle, eax

    ; Write item count first since it is what we are reading first
    invoke WriteFile, fileHandle, addr currentItemCount, 4, addr bytesWritten, NULL

    ;Calculate bytes to write
    mov eax, currentItemCount
    mov ebx, ITEM_SIZE
    mul ebx
    mov bytesToWrite, eax

    ;Write all items
    invoke WriteFile, fileHandle, addr itemDatabase, bytesToWrite, addr bytesWritten, NULL

    invoke CloseHandle, fileHandle
    ret

    save_failed:
        push offset fileSaveErrorMsg

    

    SaveInventory ENDP
    
    ; ========================================
    ; Display Dynamic Menu with Stock
    ; ========================================
    DisplayDynamicMenu PROC
        LOCAL itemNum:DWORD, itemOffset:DWORD
        LOCAL itemPrice:DWORD, itemStock:DWORD

        invoke StdOut, chr$(13,10)
        push offset menuHeader
        call StdOut


        ; Check if there are any items
        mov eax, currentItemcount
        cmp eax, 0
        je no_items
        
        mov itemNum, 0

        display_loop:
            mov eax, itemNum
            cmp eax, currentItemCount
            jge display_done
        
            ; Calculate offset for current item
            mov eax, itemNum
            mov ebx, ITEM_SIZE
            mul ebx
            mov itemOffset, eax
            
            ; Get item data
            lea esi, itemDatabase
            add esi, itemOffset
            
            ; Get price and stoc
            mov eax, [esi + NAME_SIZE]
            mov itemPrice, eax
            mov eax, [esi + NAME_SIZE + 4]
            mov itemStock, eax
            
            ;Clear Menu line buffer
            invoke RtlZeroMemory, addr menuLine, 64
            
            ; Format: "X. ItemName - ₱Price (Stock: X)"
            mov eax, itemNum
            inc eax ;To display as 1-based since by default it is 0 based
            invoke wsprintf, addr menuLine, chr$("%d. %-12s - ₱%-4d (Stock: %d)"), eax, esi, itemPrice, itemStock
            
            push offset menuLine
            call StdOut
            invoke StdOut, chr$(13,10)
            
            inc itemNum
            jmp display_loop
            
        no_items:
            push offset noItemsMsg
            call StdOut
        

        display_done:
            invoke StdOut, chr$(13,10,"Selection [1-")
            invoke StdOut, str$(currentItemCount)
            invoke StdOut, chr$("]: ")
            ret

    DisplayDynamicMenu ENDP
    
    ; ========================================
    ; Add New Item
    ; ========================================   
    AddNewItem PROC
        LOCAL itemOffset:DWORD
        
        ; check if inventory is full
        mov eax, currentItemCount
        cmp eax, MAX_ITEMS
        jge inventory_full
        
        ;Display add item menu
        push offset addItemMenu
        call StdOut

        ; Get item name
        push offset namePrompt
        call StdOut

        push NAME_SIZE
        push offset tempName
        call StdIn
        
        ;Get item price
        get_price:
            ; Display price prompt
            push offset pricePrompt
            call StdOut
            
            ; Input
            push 32
            push offset inputBuf
            call StdIn

            ; input validation
            cmp byte ptr [inputBuf], 0
            je get_price
            
            ;Converting input(str) to int
            push offset inputBuf
            call atodw
            jc get_price
            cmp eax, 0
            jle get_price
            mov tempPrice, eax
            
        ;Get item Stock
        get_stock:
            ; Display stock prompt
            push offset stockPrompt
            call StdOut
            
            ;input
            push 32
            push offset inputBuf
            call StdIn
            
            ;input validation
            cmp byte ptr [inputBuf], 0
            je get_stock

            ;Converting input(str) to int
            push offset inputBuf
            call atodw
            jc get_stock
            cmp eax, 0
            jl get_stock
            mov tempStock, eax
            
            ; Calculate offset for new item
            mov eax, currentItemCount
            mov ebx, ITEM_SIZE
            mul ebx
            mov itemOffset, eax
            
            ; copy data to database
            lea edi, itemDatabase
            add edi, itemOffset ;edi now has the new mem address of the newly allocated space for the new item
        
            ; copy name
            invoke lstrcpy, edi, addr tempName
            
            ;copy price
            mov eax, tempPrice
            mov [edi + NAME_SIZE], eax

            ;copy stock
            mov eax, tempStock
            mov [edi + NAME_SIZE + 4], eax

            ; increment item count +1
            inc currentItemCount

            ;Save to file
            call SaveInventory
            
            ; Print successful item add
            push offset itemAddedMsg
            call StdOut
            
            ret

        inventory_full:
            push offset inventoryFullMsg
            call StdOut

            ret
            
        add_item_cancelled:

            ret


    AddNewItem ENDP

    ; ========================================
    ; Display Inventory
    ; ========================================

    DisplayInventory PROC
        LOCAL itemNum:DWORD, itemOffset:DWORD
        LOCAL itemPrice:DWORD, itemStock:DWORD

        ;Display inventory header
        push offset inventoryHeader
        call StdOut

        ; get current item count
        mov eax, currentItemcount
        cmp eax, 0
        je no_items_inv
        
        mov itemNum, 0
        
        inv_loop:
        mov eax, itemNum
        cmp eax, currentItemCount
        jge inv_done
        
        ; Calculate offset
        mov eax, itemNum
        mov ebx, ITEM_SIZE
        mul ebx
        mov itemOffset, eax

        ; get item data
        lea esi itemDatabase
        add esi, itemOffset
        
        mov eax, [esi + NAME_SIZE]
        mov itemPrice, eax
        mov eax, [esi + NAME_SIZE + 4]
        mov itemStock, eax

        ; Display Item
        push offset inventoryNum
        call StdOut

        mov eax, itemNum
        inc eax
        invoke StdOut, str$(eax)
        
        ; Display item name
        push offset nameLabel
        call StdOut
        invoke StdOut, esi

        ; Display item price
        push offset priceLabel
        call StdOut
        invoke StdOut, str$(itemPrice)
        
        ;Display item stock
        push offset stockLabel
        call StdOut 
        invoke StdOut, str$(itemStock)

        ;New line
        invoke StdOut, chr$(13,10)
        
        inc itemNum
        jmp inv_loop

        
    no_items_inv:
        push offset noItemsMsg
        call StdOut
        
    inv_done
        invoke StdOut, chr$(13,10)
        ret
        
        
    DisplayInventory ENDP




    end start_minimart
    ;TODO: CLS every new item - Done
    ; put Stocks on items
    ; add item
    ; dashboard
    ; Feature improvements:
    ;   Persistence
    ;   create a file for each receipt
