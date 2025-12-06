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
    fileHandle DWORD ?
    bytesRead DWORD ?
    bytesWritten DWORD ?

    ; ==== Dynamic Item Structure ====
    ; Each item: [Name(32 bytes)][Price(4 bytes)][Stock(4 bytes)] = 40 bytes per item syet
    MAX_ITEMS equ 50    ;Only 50 items max
    ITEM_SIZE equ 40    ; size of the entire item structure
    NAME_SIZE equ 32    ; 32 bytes for each item name

    itemDatabase db MAX_ITEMS * ITEM_SIZE dup(0)
    currentItemCount DWORD 10 ;Default with 10 items

    ; ==== Sales Tracking Structure ====
    ; Each sale record: [ItemID(4)][Quantity(4)][TotalPrice(4)][Date(4)][Time(4)] = 20 bytes
    SALE_RECORD_SIZE equ 20
    MAX_SALES equ 1000  ; Track up to 1000 sales
    salesDatabase db MAX_SALES * SALE_RECORD_SIZE dup(0)
    currentSalesCount DWORD 0


    ;==== File Names ====
    inventoryFileName db "inventory.dat", 0
    summaryFileName db "summary.dat", 0

    ; ==== Temporary buffers for item operations ====
    tempName db NAME_SIZE dup(0)
    tempPrice DWORD ?
    tempStock DWORD ?


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
                   db "3. Update Item Stock",13,10
                   db "4. POS (Point of Sale)", 13,10
                   db "5. View Sales Summary", 13,10
                   db "6. Exit", 13,10, 13,10
                   db "Selection [1-6]: ", 0



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
    
    
    ; ==== Menu Text ==== -> Obsolete, will delete later
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

    ; ==== Default Items ====
    str_Coffee db "Coffee",0
    str_Donut db "Donut",0
    str_Sandwich db "Sandwich",0
    str_Milk db "Milk",0
    str_Bread db "Bread",0
    str_Chips db "Chips",0
    str_Soda db "Soda",0
    str_Juice db "Juice",0
    str_Candy db "Candy",0
    str_Egg db "Egg",0

    qtyPrompt db "Enter Quantity: ", 0
    anotherMsg db "Add another item? (Y/N): ",0 
    paymentMsg db 13,10,"Payment Amount:   ₱",0

                
    ; ==== Receipt Messages ====
    receiptHdr db 13,10, "========= RECEIPT =========",13,10,0
    dateText db "Date: ",0
    timeText db "   Time: ",0
    dateTimeBuf db 64 dup(0)
    itemText db "Item ",0
    itemNames db "Coffee", 0,0,0,0     ; 6 chars + 4 nulls = 10 bytes (Index 0)-> Obsolete since implemented dynamic menu items
              db "Donut", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 1)-> Obsolete
              db "Sandwich", 0,0       ; 8 chars + 2 nulls = 10 bytes (Index 2)-> Obsolete
              db "Milk", 0,0,0,0,0,0   ; 4 chars + 6 nulls = 10 bytes (Index 3)-> Obsolete
              db "Bread", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 4)-> Obsolete
              db "Chips", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 5)-> Obsolete
              db "Soda", 0,0,0,0,0,0   ; 4 chars + 6 nulls = 10 bytes (Index 6)-> Obsolete
              db "Juice", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 7)-> Obsolete
              db "Candy", 0,0,0,0,0    ; 5 chars + 5 nulls = 10 bytes (Index 8)-> Obsolete
              db "Egg", 0,0,0,0,0,0    ; 3 chars + 7 nulls = 10 bytes (Index 9)-> Obsolete
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
    stockDisplayPrompt db " (Stock: ",0
    closeParen db ")", 0


    ; ==== Update Stock Messages ====
    updateStockMenu db 13,10,"========= Update Item Stock =========",13,10,0
    selectItemPrompt db "Enter item ID to update (0 to cancel): ",0
    newStockPrompt db "Enter new stock quantity: ",0
    stockUpdatedMsg db "Stock updated successfully!",13,10,0
    updateCancelledMsg db "Update cancelled.",13,10,0


    ; ===== Add Item menu and messages ====
    addItemMenu db 13,10,"========= Add New Item =========",13,10
                db "Enter item details:", 13,10, 0
    namePrompt db "Item Name: ",0
    pricePrompt db "Price (₱): ",0
    initialStockPrompt db "Initial Stock: ", 0
    itemAddedMsg db "Item added succesffully!",13,10,0
    inventoryFullMsg db "Inventory is full! Cannot add more items!",13,10,0


    ; ==== Summary Messages ====
    summaryHeader db 13,10,"========= Sales Summary =========",13,10,0
    totalSalesMsg db "Total Transactions: ",0
    totalRevenueMsg db "Total Revenue: ₱",0
    mostSoldItemMsg db "Most Sold Item: ",0
    leastStockMsg db "Items Low on Stock (< 10): ",13,10,0
    noSalesMsg db "No sales recorded yet.",13,10,0
    salesBreakdownMsg db 13,10,"--- Sales Breakdown by Item ---",13,10,0
    itemSalesLine db 64 dup(0)
    dashLine3 db "================================",13,10,0
    recordFullMsg db "Sorry, summary file is full. Please move the current summary.dat to create a new empty one",0

    ; ==== Sales Messages ====
    saveSalesFailMsg db "Something went wrong. Failed saving sales. Please try again", 0
    ; ==== Prices ==== -> Obsolete
    priceTable DWORD 39, 12, 15, 50, 25, 30, 20, 15, 5, 8

    ; ==== Stock ==== -> Obsolete
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
    
    ; ==== Menu Display Buffers ====
    menuHeader db "========= MiniMart POS System =========", 13,10,13,10,0
    menuLine db 64 dup(0)



.code

    start_minimart: 
        invoke StdOut, chr$("Program starting...",13,10)
        invoke Sleep, 2000  ; Wait 2 seconds
        ; ==== Load inventory at startup ====
        call LoadInventory 

        invoke StdOut, chr$("LoadInventory completed...",13,10)
        invoke Sleep, 2000

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
            call atodw
            jc invalid_type_input_minimart
            mov optionIdx, eax
            
            ; ==== Validate input (1-5) ====
            cmp eax, 1
            jl invalid_selection_input_minimart
            cmp eax, 5
            jg invalid_selection_input_minimart

            cmp eax, 1
            je start_inventory
            cmp eax, 2
            je start_add_item
            cmp eax, 3
            je start_update_stock
            cmp eax, 4
            je start_pos
            cmp eax, 5
            je start_summary
            cmp eax, 6
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

        start_update_stock:
            call UpdateItemStock
            invoke crt_system, chr$("pause")
            invoke crt_system, addr clsCmd
            jmp option_loop

    start_summary:
        call DisplaySalesSummary
        invoke crt_system, chr$("pause")
        invoke crt_system, addr clsCmd
        jmp option_loop
        

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

            ; ==== Calculate Item offset ====
            mov ebx, ITEM_SIZE
            mul ebx
            

            ; ==== Get Item data ====
            lea esi, itemDatabase
            add esi, eax

            ; ==== Get price and stock ====
            mov eax, [esi + NAME_SIZE]
            mov price, eax
            mov eax, [esi + NAME_SIZE + 4]
            
            ; ==== Check stock ====
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
            
            mov quantity, eax
            
            ; ==== Check if quantity exceeds available stock ====
            mov ebx, stock
            cmp eax, ebx
            jg insufficient_stock_error

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
            

            ; ==== Decrease Stock in database (persistence) ====
            mov eax, itemIdx
            mov ebx, ITEM_SIZE
            mul ebx
            lea esi, itemDatabase
            add esi, eax
            add esi, NAME_SIZE
            add esi, 4  ; Skip to stock field

            mov eax, [esi]
            sub eax, quantity
            mov [esi], eax

            ; ==== Save inventory ====
            call SaveInventory


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
            
            ; ==== Get item index ====
            mov eax, receiptItems[esi*4]
            
            ; ==== Calculate item offset in database ====
            mov ebx, ITEM_SIZE
            mul ebx
            lea edi, itemDatabase
            add edi, eax
            
            ; ==== Print item number ====
            push offset itemText
            call StdOut
            mov eax, esi
            inc eax
            invoke StdOut, str$(eax)
            push offset colonText
            call StdOut
            
            ; ==== Print item name from database ====
            invoke StdOut, edi
            
            ; ==== Print quantity ====
            push offset priceText
            call StdOut
            invoke StdOut, str$(receiptQtys[esi*4])
            
            ; ==== Print price ====
            push offset atText
            call StdOut
            mov eax, [edi + NAME_SIZE]  ; Get price from database
            invoke StdOut, str$(eax)
            
            ; ==== Print total ====
            push offset equalText
            call StdOut
            invoke StdOut, str$(receiptTotals[esi*4])
            invoke StdOut, chr$(13,10)
            
            ;==== Increase item count ====
            inc esi

            ; ==== continue loop ====
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

            ; ==== Record the sale ====
            call RecordSale
            call SaveSalesData
            
            jmp exit_program; -> Should I quit automatically or loop back to the menu?

        out_of_stock_error:
            push offset outOfStockMsg
            call StdOut

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
            
            jmp read_item
            
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
        
        ; Zero out database first
        invoke RtlZeroMemory, addr itemDatabase, MAX_ITEMS * ITEM_SIZE
        
        ;Item 0: Coffee
        mov itemOffset, 0
        lea esi, itemDatabase
        invoke lstrcpy, esi, addr str_Coffee
        mov DWORD PTR [esi + NAME_SIZE], 39
        mov DWORD PTR [esi + NAME_SIZE + 4], 50
        
        ;Item 1: Donut
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Donut
        mov DWORD PTR [esi + NAME_SIZE], 12
        mov DWORD PTR [esi + NAME_SIZE + 4], 100
        
        ;Item 2: Sandwich
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Sandwich
        mov DWORD PTR [esi + NAME_SIZE], 15
        mov DWORD PTR [esi + NAME_SIZE + 4], 75
        
        ;Item 3: Milk
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Milk
        mov DWORD PTR [esi + NAME_SIZE], 50
        mov DWORD PTR [esi + NAME_SIZE + 4], 40
        
        ;Item 4: Bread
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Bread
        mov DWORD PTR [esi + NAME_SIZE], 25
        mov DWORD PTR [esi + NAME_SIZE + 4], 60
        
        ;Item 5: Chips
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Chips
        mov DWORD PTR [esi + NAME_SIZE], 30
        mov DWORD PTR [esi + NAME_SIZE + 4], 80
        
        ;Item 6: Soda
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Soda
        mov DWORD PTR [esi + NAME_SIZE], 20
        mov DWORD PTR [esi + NAME_SIZE + 4], 90
        
        ;Item 7: Juice
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Juice
        mov DWORD PTR [esi + NAME_SIZE], 15
        mov DWORD PTR [esi + NAME_SIZE + 4], 70
        
        ;Item 8: Candy
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Candy
        mov DWORD PTR [esi + NAME_SIZE], 5
        mov DWORD PTR [esi + NAME_SIZE + 4], 150
        
        ;Item 9: Egg
        add itemOffset, ITEM_SIZE
        lea esi, itemDatabase
        add esi, itemOffset
        invoke lstrcpy, esi, addr str_Egg
        mov DWORD PTR [esi + NAME_SIZE], 8
        mov DWORD PTR [esi + NAME_SIZE + 4], 120
        
        mov currentItemCount, 10
        ret

    InitializeDefaultItems ENDP

    ; ========================================
    ; Load Inventory from File
    ; ========================================
    LoadInventory PROC
        LOCAL bytesToRead:DWORD
        
        ;Trying to open inventory file
        invoke CreateFile, addr inventoryFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

        cmp eax, INVALID_HANDLE_VALUE
        je load_default
        mov fileHandle, eax

        ; Read item count first
        invoke ReadFile, fileHandle, addr currentItemCount, 4, addr bytesRead, NULL
        
        ; Check if ReadFile failed or read 0 bytes (empty file)
        test eax, eax
        jz load_default_close
        cmp bytesRead, 0
        je load_default_close
        
        ; Validate that we read exactly 4 bytes
        cmp bytesRead, 4
        jne load_default_close
        
        ; Validate that currentItemCount is reasonable (1 to MAX_ITEMS)
        mov eax, currentItemCount
        cmp eax, 0
        jle load_default_close
        cmp eax, MAX_ITEMS
        jg load_default_close
        
        ; Calculate bytes to read for all items
        mov eax, currentItemCount
        mov ebx, ITEM_SIZE
        mul ebx
        mov bytesToRead, eax

        ; Read all items
        invoke ReadFile, fileHandle, addr itemDatabase, bytesToRead, addr bytesRead, NULL
        
        ; Check if ReadFile failed
        test eax, eax
        jz load_default_close
        
        ; Validate that we read the expected number of bytes
        mov eax, bytesToRead
        cmp bytesRead, eax
        jne load_default_close

        invoke CloseHandle, fileHandle
        ret
        
        load_default_close:
            cmp fileHandle, INVALID_HANDLE_VALUE
            je load_default
            invoke CloseHandle, fileHandle
            mov fileHandle, 0  ; Clear the handle
            
        load_default:
            ; Initialize default items
            call InitializeDefaultItems
            
            ; Only save if we have valid items
            mov eax, currentItemCount
            cmp eax, 0
            jle load_inventory_done
            call SaveInventory  ; Save defaults to file so they persist
            
        load_inventory_done:
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

        ; Write item count first
        invoke WriteFile, fileHandle, addr currentItemCount, 4, addr bytesWritten, NULL
        test eax, eax  ; Check if WriteFile succeeded
        jz save_error_close

        ; Calculate bytes to write
        mov eax, currentItemCount
        mov ebx, ITEM_SIZE
        mul ebx
        mov bytesToWrite, eax

        ; Write all items
        invoke WriteFile, fileHandle, addr itemDatabase, bytesToWrite, addr bytesWritten, NULL
        test eax, eax  ; Check if WriteFile succeeded
        jz save_error_close

        invoke CloseHandle, fileHandle
        ret

    save_error_close:
        invoke CloseHandle, fileHandle  ; Close handle before showing error

    save_failed:
        push offset fileSaveErrorMsg
        call StdOut
        ret

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
        mov eax, currentItemCount
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
            push offset initialStockPrompt
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
        mov eax, currentItemCount
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
        lea esi, itemDatabase
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
        
    inv_done:
        invoke StdOut, chr$(13,10)
        ret
        
        
    DisplayInventory ENDP

    ; ========================================
    ; Update Item Stock
    ; ========================================
    UpdateItemStock PROC
        LOCAL itemID:DWORD, itemOffset:DWORD
        LOCAL newStock:DWORD

        ; check if inventory is empty
        mov eax, currentItemCount
        cmp eax, 0
        je no_items_to_update

        ; display current inventory first so that the user can pick which item it wants to update
        call DisplayInventory
        
        ; display update menu
        push offset updateStockMenu
        call StdOut

        get_item_id:
            ;display prompt for item id
            push offset selectItemPrompt
            call StdOut

            ; get user input
            push 32
            push offset inputBuf
            call StdIn

            ; validate input
            cmp byte ptr [inputBuf], 0
            je get_item_id 

            ; convert user input to int using atodw
            push offset inputBuf
            call atodw
            jc get_item_id
            
            ; Check for cancel (0)
            cmp eax, 0
            je update_cancelled

            mov itemID, eax

            ; validate item id input range 
            cmp eax, 1
            jl invalid_item_id
            mov ebx, currentItemCount
            cmp eax, ebx
            jg invalid_item_id

            ; convert user input to 0 based index so I can start changing the database
            dec eax

            ; calculate item offset -> this is where the calculations takes place
            mov ebx, ITEM_SIZE
            mul ebx
            mov itemOffset, eax
            

        get_new_stock:
            ; display prompt for new stoc
            push offset newStockPrompt
            call StdOut
            
            ; get user input
            push 32
            push offset inputBuf
            call StdIn

            ; validate user input, check if input is empty
            cmp byte ptr [inputBuf], 0
            je get_new_stock
            
            ; convert input to int using atodw
            push offset inputBuf
            call atodw
            jc get_new_stock
            
            ;validate stock if it's >= 0
            cmp eax, 0
            jl get_new_stock
            
            mov newStock, eax
            
            ;update stock in database
            lea esi, itemDatabase
            add esi, itemOffset
            add esi, NAME_SIZE
            add esi, 4

            mov eax, newStock
            mov ebx, [esi]
            add eax, ebx
            mov [esi], eax; -> Sets the new stock value
            
            ; save new stock to inventory
            call SaveInventory

            ; Display success message
            push offset stockUpdatedMsg
            call StdOut
            ret
            
        invalid_item_id:
            push offset invalidSelectionMsg
            call StdOut
            jmp get_item_id
            
        update_cancelled:
            push offset updateCancelledMsg
            call StdOut
            ret
            
        no_items_to_update:
            push offset noItemsMsg
            call StdOut
            ret
            
        
    
    UpdateItemStock ENDP
    
    ; ========================================
    ; Record Sale - Saves current transaction
    ; ========================================

    RecordSale PROC
        LOCAL saleOffset:DWORD, i:DWORD
        
        ; Check if we have room for more sales our max should be about 1k sales
        mov eax, currentSalesCount
        cmp eax, MAX_SALES ;-> has 1k sales limit
        jge record_sale_full

        ; get current date and time 
        invoke GetLocalTime, add localTime
        
        ; record each item in the transaction
        mov i, 0
        
        record_loop:
            mov eax, i
            cmp eax, itemCount
            jge record_done

            ; check if we still have room for another sale            
            mov eax, currentSalesCount
            cmp eax, MAX_SALES ;-> has 1k sales limit
            jge record_sale_full

            ; calculate offset for new sale record
            mov eax, currentSalesCount
            mov ebx, SALE_RECORD_SIZE
            mul ebx
            mov saleOffset, eax
            
            ; get pointer to sale record
            lea edi, salesDatabase
            add edi, saleOffset
            
            ; store ItemId
            mov eax, i 
            mov ebx, receiptItems[eax*4]
            mov [edi], ebx

            ; store quantity
            mov ebx, receiptQtys[eax*4]
            mov [edi + 4], ebx
            
            ; store total price
            mov ebx, receiptTotals[eax*4]
            mov [edi + 8], ebx
            
            ; Store date (YYYYMMDD format)
            movzx eax, localTime.wYear
            imul eax, 10000
            movzx ebx, localTime.wMonth
            imul ebx, 100
            add eax, ebx
            movzx ebx, localTime.wDay
            add eax, ebx
            mov [edi + 12], eax
            
            ; Store Time (HHMM format)
            movzx eax, localTime.wHour
            imul eax, 100
            movzx ebx, localTime.wMinute
            add eax, ebx
            mov [edi + 16], eax

            ; increment sales count
            inc currentSalesCount
            inc i
            jmp record_loop

        record_sale_full:
            push offset recordFullMsg
            call StdOut

            jmp start_minimart
            

        record_done:
            ret

    RecordSale ENDP

    ; ========================================
    ; Save Sales Data to File
    ; ========================================
    SaveSalesData PROC
        LOCAL bytesToWrite:DWORD
        
        ;create or read file if exists
        invoke CreateFile, addr summaryFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        cmp eax, INVALID_HANDLE_VALUE
        je save_sales_failed
        mov fileHandle, eax

        ; Write sales count
        invoke WriteFile, fileHandle, addr currentSalesCount, 4, addr bytesWritten, NULL
        test eax, eax
        jz save_sales_error_close

        ; Calculate bytes to write
        mov eax, currentSalesCount
        mov ebx, SALE_RECORD_SIZE
        mul ebx
        mov bytesToWrite,eax

        ; Write all sales records
        invoke WriteFile, fileHandle, addr salesDatabase, bytesToWrite, addr bytesWritten, NULL
        test eax, eax
        jz save_sales_error_close       

        invoke CloseHandle, fileHandle
        ret

        save_sales_error_close:
            invoke CloseHandle, fileHandle

        save_sales_failed:
            push offset saveSalesFailMsg
            call StdOut

            ret



    SaveSalesData ENDP

    ; ========================================
    ; Load Sales Data from File
    ; ========================================
    LoadSalesData PROC
        LOCAL bytesToRead:DWORD
        
        ; create or load file
        invoke CreateFile, addr summaryFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        cmp eax, INVALID_HANDLE_VALUE
        je load_sales_default
        mov fileHandle, eax

        ; Read sales count
        invoke ReadFile, fileHandle, addr currentSalesCount, 4, addr bytesRead, NULL
        test eax, eax
        jz load_sales_default_close
        cmp bytesRead, 4
        jne load_sales_default_close

        ; Validate sales count
        mov eax, currentSalesCount
        cmp eax, 0
        jl load_sales_default_close
        cmp eax, MAX_SALES ; -> checks if currentSalesCount is over 1k
        jg load_sales_default_close
        
        ; calculate bytes to read
        mov eax, currentSalesCount
        mov ebx, SALE_RECORD_SALE   
        mul ebx
        mov bytesToRead, eax
        
        ; Read all sales
        invoke ReadFile, fileHandle, addr salesDatabase, bytesToRead, addr bytesRead, NULL
        test eax, eax
        jz load_sales_default_close
        
        mov eax, bytesToRead
        cmp bytesRead, eax
        jne load_sales_default_close
        
        invoke CloseHandle, fileHandle
        ret


        load_sales_default_close:
            invoke CloseHandle, fileHandle

         load_sales_default:
            mov currentSalesCount, 0
            ret
           


    LoadSalesData ENDP

    ; ========================================
    ; Display Sales Summary
    ; ========================================
    DisplaySalesSummary PROC
        LOCAL totalRevenue:DWORD, totalTransactions:DWORD
        LOCAL mostSoldItemID:DWORD, mostSoldQty:DWORD
        LOCAL itemQuantities[50]:DWORD  ; Track quantity sold for each item
        LOCAL i:DWORD, j:DWORD, itemOffset:DWORD
        
        ;Display header
        push offset summaryHeader
        call StdIn
        
        ; check if there are any sales
        mov eax, currentSalesCount
        cmp eax, 0
        je no_sales_summary

        ; Initialize counters
        mov totalRevenue, 0
        mov totalTransactions, 0
        mov mostSoldQty, 0
        mov mostSoldItemID, 0
        
        ; Zero out item quantities array
        lea edi, itemQuantities
        mov ecx, 50
        xor eax, eax
        rep stosd
        
        ; Process all sales
        mov i, 0


        process_sales_loop:
            mov eax, i
            cmp eax, currentSalesCount ; -> This means that all sales were accounted for
            jge sales_processed

            ; Calculate sales record offset
            move ebx, SALE_RECORD_SIZE
            mul ebx
            lea esi, salesDatabase
            add esi, eax
            
            ; Get itemID, Quantity, and total
            mov eax, [esi] ;-> esi contains the base address of the sale structure. Base cell contains the ItemID
            mov ebx, [esi + 4] ;-> add 4 to esi is for the cell of Quantity
            mov ecx, [esi + 8] ;-> add 4 to esi is for the cell of Total Price
            
            ; add to item quantities
            lea edi, itemQuantities
            mov edx, eax
            shl edx, 2              ; multiply by 4
            add edi, edx
            add [edi], ebx

            ; Add to total revenue
            mov eax, totalRevenue
            add eax, ecx
            mov totalRevenue, eax
            
            inc i
            jmp process_sales_loop
            
        sales_processed:
            
            ;finding most sold item
            mov i, 0
            find_most_sold:
                mov eax, i
                cmp eax, currentItemCount
                jge found_most_sold
                
                lea edi, itemQuantities
                mov ebx, i
                shl ebx, 2
                add edi, ebx
                mov eax, [edi]
                
                cmp eax, mostSoldQty
                jle not_most_sold
                
                mov mostSoldQty, eax
                mov eax, i
                mov mostSoldItemID, eax
                
            not_most_sold:
                inc i
                jmp find_most_sold
    
                
        found_most_sold:
            
            ;Display total transactions
            push offset totalSalesMsg
            call StdOut

            invoke StdOut, str$(currentSalesCount)
            invoke StdOut, chr$(13,10)

            ; Display total revenue
            push offset totalRevenueMsg
            call StdOut
            invoke StdOut, str$(totalRevenue)
            invoke StdOut, chr$(13,10, 13,10)

            ; Display most sold item
            cmp mostSoldQty, 0
            je no_most_sold

            push offset mostSoldItemMsg
            call StdOut

            ; get item name of the most sold
            mov eax, mostSoldItemID
            mov ebx, ITEM_SIZE
            mul ebx
            lea esi, itemDatabase
            add esi, eax
            invoke StdOut, esi

            invoke StdOut, chr$(" (Sold: ")
            invoke StdOut, str$(mostSoldQty)
            invoke StdOut, chr$(")",13,10)
            
         no_most_sold:
            ; Display sales breakdown
            push offset salesBreakdownMsg
            call StdOut
            push offset dashLine3
            call StdOut
            
            mov i, 0

            display_breakdown:
                mov eax, i
                cmp eax, currentItemCount
                jge breakdown_done
                
                ; Check if this item was sold
                lea edi, itemQuantities
                mov ebx, i
                shl ebx, 2
                add edi, ebx
                mov eax, [edi]
                cmp eax, 0
                je skip_item
                
                ; Get item info
                mov eax, i
                mov ebx, ITEM_SIZE
                mul ebx
                mov itemOffset, eax
                lea esi, itemDatabase
                add esi, itemOffset
                
                ; Get item price
                mov edx, [esi + NAME_SIZE]
                
                ; Calculate total for this item
                lea edi, itemQuantities
                mov ebx, i
                shl ebx, 2
                add edi, ebx
                mov eax, [edi]          ; quantity
                mul edx                 ; multiply by price
                
                ; Format and display
                invoke RtlZeroMemory, addr itemSalesLine, 64
                mov ecx, i
                inc ecx
                invoke wsprintf, addr itemSalesLine, chr$("  %d. %-15s: Qty %3d  Revenue: ₱%d"), ecx, esi, DWORD PTR [edi], eax
                push offset itemSalesLine
                call StdOut
                invoke StdOut, chr$(13,10)
                
            skip_item:
                inc i
                jmp display_breakdown
                
        breakdown_done:
            push offset dashLine3
            call StdOut
            
            ; Display low stock warning
            push offset leastStockMsg
            call StdOut
            
            mov i, 0
            check_low_stock:
                mov eax, i
                cmp eax, currentItemCount
                jge low_stock_done
                
                ; Get item stock
                mov eax, i
                mov ebx, ITEM_SIZE
                mul ebx
                lea esi, itemDatabase
                add esi, eax
                mov eax, [esi + NAME_SIZE + 4]  ; stock
                
                cmp eax, 10
                jge not_low_stock
                
                ; Display item with low stock
                invoke StdOut, chr$("  - ")
                invoke StdOut, esi
                invoke StdOut, chr$(" (")
                mov eax, [esi + NAME_SIZE + 4]
                invoke StdOut, str$(eax)
                invoke StdOut, chr$(" left)",13,10)
                
            not_low_stock:
                inc i
                jmp check_low_stock
                
        low_stock_done:
            invoke StdOut, chr$(13,10)
            ret
            
        no_sales_summary:
            push offset noSalesMsg
            call StdOut
            ret
                 
        
    DisplaySalesSummary ENDP

    end start_minimart

    ;TODO: CLS every new item - Done
    ;-> put Stocks on items - Done
    ;->  add item - Done
    ;-> Summary - WIP 

    ;TODO: Feature improvements:
    ;-> Persistence - Done
    ;->  create a file for each receipt - WIP

    ;Things that I've found:
    ;-> stock is instantly decreased when trying to add a new item
    ;-> 
