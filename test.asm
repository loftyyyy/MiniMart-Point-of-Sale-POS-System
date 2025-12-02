; MiniMart POS System (MASM32)
; Simulates a simple retail checkout transaction

include C:\masm32\include\masm32rt.inc
;include C:\irvine32\Irvine32.inc

.data

    ; ==== Inventory file configuration ====
    MAX_INVENTORY_ITEMS EQU 20

    ITEM_RECORD STRUCT
        ir_name  db 32 dup(0)   ; item name (null-terminated, max 31 chars)
        ir_price DWORD ?        ; item price in pesos
        ir_stock DWORD ?        ; current stock
    ITEM_RECORD ENDS
    
    ; Field offsets for manual access
    IR_NAME_OFFSET  EQU 0
    IR_PRICE_OFFSET EQU 32
    IR_STOCK_OFFSET EQU 36

    inventoryFileName db "inventory.dat",0
    inventoryRecords  ITEM_RECORD MAX_INVENTORY_ITEMS dup(<>)
    currentInventoryCount DWORD 0
    hInventoryFile DWORD 0
    bytesIO        DWORD 0
    fileSize       DWORD 0

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

    ; ==== Menu / POS & Receipt Text (dynamic inventory) ====
    menuHeader   db "========= MiniMart POS System =========", 13,10,13,10,0
    selectPrompt1 db "Selection [1-",0
    selectPrompt2 db "]: ",0
    menuPriceSep db " - ₱",0

    qtyPrompt   db "Enter Quantity: ", 0
    anotherMsg  db "Add another item? (Y/N): ",0 
    paymentMsg  db 13,10,"Payment Amount:   ₱",0

    ; ==== Receipt Messages ====
    receiptHdr  db 13,10, "========= RECEIPT =========",13,10,0
    dateText    db "Date: ",0
    timeText    db "   Time: ",0
    dateTimeBuf db 64 dup(0)
    itemText    db "Item ",0
    priceText   db " x ", 0
    atText      db " @ ₱", 0
    equalText   db " = ₱", 0
    colonText   db ": ", 0
    dashLine    db "--------------------------", 13,10, 0
    subText     db "Sub Total:        ₱",0        
    taxText     db "VAT (12%):        ₱",0
    totalText   db "Total Amount:     ₱",0
    dashLine2   db "===========================", 13,10,0
    paidText    db "Amount Paid:      ₱",0
    changeText  db "Change:           ₱",0  

    ; ==== Response Messages ====
    insuffMsg db "Insufficient payment! Please pay at least ₱",0 
    thankYouMsg db "Thank you for your purchase!",13,10,0
    invalidSelectionMsg db "Invalid selection! Please enter the correct number: ", 0
    invalidQuantityMsg db "Invalid Quantity! Please enter a positive number", 13, 10, 0
    invalidTypeMsg db "Please input a number!", 13,10, 0
    invalidPay db "Invalid payment! Please enter a valid amount", 13, 10, 0

    ; ==== Inventory Messages ====
    newItemMsg db "Item Name: ",13,10,0
    newItemPriceMsg db "Item Price (in pesos): ",13,10,0
    newItemStockMsg db "Initial Stock Amount: ", 13,10,0
    successNewItemMsg db "Item added successfully.", 13,10,0
    inventoryFullMsg db "Inventory is full, cannot add more items.",13,10,0
    updateItemIndexMsg db "Enter item number to update: ",13,10,0
    newStockAmountMsg db "New Stock Amount: ",13,10,0
    noItemsMsg db "No items in inventory.",13,10,0
    showItemsHeader db 13,10,"Items with stock:",13,10,0

    ; ==== Stock Messages ====
    outOfStockMsg db "Sorry, this item is out of stock!", 13,10,0
    insufficientStockMsg db "Insufficient stock! Only ",0
    availableMsg db " available", 13, 10, 0
    stockPrompt db " (Stock: ",0
    closeParen db ")", 0

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
        ; ==== Load inventory from file (if it exists) ====
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
        
        inventory_loop:
            ; ==== Display inventory menu ====
            push offset inventoryOption
            call StdOut
            
        read_inventory_item:
            ; ==== Read and store user selection ====
            push 32
            push offset inputBuf
            call StdIn
            
            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_inventory_selection_input

            ; ==== Convert input to int ====
            push offset inputBuf
            call atodw ; converts string to int
            jc invalid_type_input ; Jumps if input is not a number
            
            mov itemIdx, eax
            
            ; ==== Validate user input (0-3) ====
            cmp eax, 0
            jl invalid_inventory_selection_input
            cmp eax, 3
            jg invalid_inventory_selection_input

            ; ==== go to selection ====
            cmp eax, 0
            je start_minimart
            
            cmp eax, 1
            je new_item
            
            cmp eax, 2
            je update_stock

            cmp eax, 3
            je show_inventory_items

        new_item:
            ;==== New item name ====
            push offset newItemMsg
            call StdOut
            
            ;==== Read and store name ====
            push 32
            push offset inputBuf
            call StdIn
            
            ;==== Check if inventory is full ====
            mov eax, currentInventoryCount
            cmp eax, MAX_INVENTORY_ITEMS
            jae inventory_full
            
            ;==== Compute pointer to new inventory record ====
            mov ecx, eax                    ; ecx = index = currentInventoryCount
            mov eax, SIZEOF ITEM_RECORD
            mul ecx                          ; eax = index * sizeof(ITEM_RECORD)
            lea edi, inventoryRecords
            add edi, eax                     ; edi -> new ITEM_RECORD
            
            ;==== Copy name from inputBuf to ir_name (max 31 chars) ====
            mov esi, OFFSET inputBuf
            mov ecx, 31
        copy_new_name_loop:
            cmp ecx, 0
            je finish_name_copy
            mov al, [esi]
            cmp al, 0
            je finish_name_copy
            cmp al, 13                      ; stop at CR
            je finish_name_copy
            cmp al, 10                      ; stop at LF
            je finish_name_copy
            mov [edi], al
            inc esi
            inc edi
            dec ecx
            jmp copy_new_name_loop
            
        finish_name_copy:
            mov byte ptr [edi], 0           ; null-terminate name
            
            ;==== Ask and read item price ====
            push offset newItemPriceMsg
            call StdOut
            
            push 32
            push offset inputBuf
            call StdIn
            
            ;==== Validate that price input contains only digits ====
            mov esi, offset inputBuf
        validate_new_price_loop:
            mov al, [esi]
            cmp al, 0
            je new_price_digits_valid
            cmp al, 13
            je new_price_digits_valid
            cmp al, 10
            je new_price_digits_valid
            cmp al, '0'
            jb invalid_quantity_input
            cmp al, '9'
            ja invalid_quantity_input
            inc esi
            jmp validate_new_price_loop
            
        new_price_digits_valid:
            push offset inputBuf
            call atodw
            jc invalid_quantity_input
            
            cmp eax, 0
            jle invalid_quantity_input
            
            mov edx, eax                    ; save price value in EDX
            
            ;==== Store price in record (ir_price) ====
            ; Recompute pointer to record
            mov ebx, currentInventoryCount   ; index
            mov eax, SIZEOF ITEM_RECORD
            mul ebx
            lea edi, inventoryRecords
            add edi, eax
            mov [edi+IR_PRICE_OFFSET], edx   ; store price
            
            ;==== Ask and read initial stock amount ====
            push offset newItemStockMsg
            call StdOut
            
            push 32
            push offset inputBuf
            call StdIn
            
            ;==== Validate that stock input contains only digits ====
            mov esi, offset inputBuf
        validate_new_stock_loop:
            mov al, [esi]
            cmp al, 0
            je new_stock_digits_valid
            cmp al, 13
            je new_stock_digits_valid
            cmp al, 10
            je new_stock_digits_valid
            cmp al, '0'
            jb invalid_quantity_input
            cmp al, '9'
            ja invalid_quantity_input
            inc esi
            jmp validate_new_stock_loop
            
        new_stock_digits_valid:
            push offset inputBuf
            call atodw
            jc invalid_quantity_input
            
            cmp eax, 0
            jle invalid_quantity_input
            
            mov edx, eax                    ; save stock value in EDX
            
            ;==== Store stock in record (ir_stock) ====
            ; Recompute pointer to record
            mov ebx, currentInventoryCount   ; index
            mov eax, SIZEOF ITEM_RECORD
            mul ebx
            lea edi, inventoryRecords
            add edi, eax
            mov [edi+IR_STOCK_OFFSET], edx   ; store stock
            
            ;==== Increase inventory count ====
            mov eax, currentInventoryCount
            inc eax
            mov currentInventoryCount, eax
            
            ;==== Save inventory to file ====
            call SaveInventory
            
            ;==== Success message ====
            push offset successNewItemMsg
            call StdOut
            
            jmp inventory_loop

        inventory_full:
            push offset inventoryFullMsg
            call StdOut
            jmp inventory_loop

        update_stock:
            ;==== Check if there are items ====
            mov eax, currentInventoryCount
            cmp eax, 0
            je no_items_inventory

            ;==== Show current items ====
            call ShowInventoryItems

            ;==== Ask which item to update ====
            push offset updateItemIndexMsg
            call StdOut

            push 32
            push offset inputBuf
            call StdIn

            ;==== Validate and convert index ====
            mov esi, offset inputBuf
        validate_update_index_loop:
            mov al, [esi]
            cmp al, 0
            je update_index_digits_valid
            cmp al, 13
            je update_index_digits_valid
            cmp al, 10
            je update_index_digits_valid
            cmp al, '0'
            jb invalid_inventory_selection_input
            cmp al, '9'
            ja invalid_inventory_selection_input
            inc esi
            jmp validate_update_index_loop

        update_index_digits_valid:
            push offset inputBuf
            call atodw
            jc invalid_inventory_selection_input

            cmp eax, 1
            jl invalid_inventory_selection_input
            cmp eax, currentInventoryCount
            jg invalid_inventory_selection_input

            ; convert to 0-based index
            dec eax
            mov itemIdx, eax

            ;==== Ask for new stock amount ====
            push offset newStockAmountMsg
            call StdOut

            push 32
            push offset inputBuf
            call StdIn

            ;==== Validate new stock digits ====
            mov esi, offset inputBuf
        validate_update_stock_loop:
            mov al, [esi]
            cmp al, 0
            je update_stock_digits_valid
            cmp al, 13
            je update_stock_digits_valid
            cmp al, 10
            je update_stock_digits_valid
            cmp al, '0'
            jb invalid_quantity_input
            cmp al, '9'
            ja invalid_quantity_input
            inc esi
            jmp validate_update_stock_loop

        update_stock_digits_valid:
            push offset inputBuf
            call atodw
            jc invalid_quantity_input

            cmp eax, 0
            jle invalid_quantity_input

            mov edx, eax                    ; save new stock

            ;==== Store new stock in selected record ====
            mov ecx, itemIdx
            mov eax, SIZEOF ITEM_RECORD
            mul ecx                          ; eax = index * sizeof(ITEM_RECORD)
            lea edi, inventoryRecords
            add edi, eax
            mov [edi+IR_STOCK_OFFSET], edx   ; store stock

            ;==== Save inventory ====
            call SaveInventory

            jmp inventory_loop

        show_inventory_items:
            call ShowInventoryItems
            jmp inventory_loop

        no_items_inventory:
            push offset noItemsMsg
            call StdOut
            jmp inventory_loop

    start_summary:

    start_pos:

        mov runningTotal, 0
        mov itemCount, 0

        ; ==== Display Shopping Cart Art ====;
        push offset shoppingCartArt
        call StdOut
        
        item_loop:
            
            ; ==== Check if there are items in inventory ====
            mov eax, currentInventoryCount
            cmp eax, 0
            jle no_items_inventory

            ; ==== Display dynamic menu from inventory ====
            call ShowPosMenu

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
     
            ; ===== Validate input (1..currentInventoryCount) =====
            cmp eax, 1
            jl invalid_selection_input
            mov ebx, currentInventoryCount
            cmp eax, ebx
            jg invalid_selection_input

            ; ==== Convert user selection to 0 based index ====
            dec eax
            mov itemIdx, eax

            ; ==== Fetch price and stock from inventory record ====
            mov ecx, itemIdx
            mov eax, SIZEOF ITEM_RECORD
            mul ecx
            lea edi, inventoryRecords
            add edi, eax                    ; EDI -> selected record
            
            mov eax, [edi+IR_PRICE_OFFSET]   ; read price
            mov price, eax
            
            mov eax, [edi+IR_STOCK_OFFSET]   ; read stock

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
            mov ecx, stock                ; current stock for selected item
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

            ; ==== Decrease Stock in inventory record ====
            mov ecx, itemIdx
            mov eax, SIZEOF ITEM_RECORD
            mul ecx
            lea edi, inventoryRecords
            add edi, eax
            mov ecx, [edi+IR_STOCK_OFFSET]   ; current stock
            sub ecx, ebx                    ; ebx = quantity
            mov [edi+IR_STOCK_OFFSET], ecx   ; update ir_stock
            
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
                    
                    ; ==== Persist updated inventory ====
                    call SaveInventory
                    
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

            ; ==== Print Item Name (from inventory record) ====
            mov eax, receiptItems[esi*4]   ; item index (0-based)
            mov ecx, eax
            mov eax, SIZEOF ITEM_RECORD
            mul ecx
            lea edi, inventoryRecords
            add edi, eax                   ; EDI -> record
            invoke StdOut, edi
            
            ; ==== Print Quantity Of the Item ====
            push offset priceText
            call StdOut
            invoke StdOut, str$(receiptQtys[esi*4])
            
            ; ==== Print Price Of the Item ====
            push offset atText
            call StdOut
            mov eax, [edi+IR_PRICE_OFFSET]   ; read price
            invoke StdOut, str$(eax)

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
            

; ============================================================
; Inventory persistence procedures
; ============================================================

; ---- LoadInventory ----
; Loads inventory from inventory.dat if it exists.
; File format:
;   DWORD count
;   ITEM_RECORD[count]

LoadInventory PROC
        ; Try to open existing inventory file for reading
        invoke CreateFile, addr inventoryFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        cmp eax, INVALID_HANDLE_VALUE
        je no_inventory_file

        mov hInventoryFile, eax

        ; Get file size to validate format (handle old/incompatible files)
        invoke GetFileSize, hInventoryFile, NULL
        mov fileSize, eax

        ; Read item count
        invoke ReadFile, hInventoryFile, addr currentInventoryCount, SIZEOF currentInventoryCount, addr bytesIO, NULL

        ; Validate count
        mov eax, currentInventoryCount
        cmp eax, MAX_INVENTORY_ITEMS
        jbe count_ok
        mov eax, MAX_INVENTORY_ITEMS
        mov currentInventoryCount, eax

    count_ok:
        ; Validate file size against expected layout: 4 + count * SIZEOF ITEM_RECORD
        mov ecx, currentInventoryCount
        mov eax, SIZEOF ITEM_RECORD
        mul ecx
        add eax, SIZEOF currentInventoryCount   ; expected size
        cmp eax, fileSize
        jne bad_inventory_file

        ; Valid size and count
        mov eax, currentInventoryCount
        cmp eax, 0
        jle close_inventory_load

        ; Read records
        mov ecx, eax                     ; ecx = count
        mov eax, SIZEOF ITEM_RECORD
        mul ecx                          ; eax = count * sizeof(ITEM_RECORD)
        invoke ReadFile, hInventoryFile, addr inventoryRecords, eax, addr bytesIO, NULL
        jmp close_inventory_load

    bad_inventory_file:
        ; Incompatible old file layout – ignore its contents
        mov currentInventoryCount, 0

    close_inventory_load:
        invoke CloseHandle, hInventoryFile
        jmp inv_load_done

    no_inventory_file:
        ; No file yet, start with empty inventory
        mov currentInventoryCount, 0

    inv_load_done:
        ret
LoadInventory ENDP

; ---- SaveInventory ----
; Saves current inventory to inventory.dat

SaveInventory PROC
        ; Open (or create) file for writing
        invoke CreateFile, addr inventoryFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        cmp eax, INVALID_HANDLE_VALUE
        je save_inv_done

        mov hInventoryFile, eax

        ; Write count
        invoke WriteFile, hInventoryFile, addr currentInventoryCount, SIZEOF currentInventoryCount, addr bytesIO, NULL

        ; Write records if any
        mov eax, currentInventoryCount
        cmp eax, 0
        jle close_inventory_save

        mov ecx, eax
        mov eax, SIZEOF ITEM_RECORD
        mul ecx
        invoke WriteFile, hInventoryFile, addr inventoryRecords, eax, addr bytesIO, NULL

    close_inventory_save:
        invoke CloseHandle, hInventoryFile

    save_inv_done:
        ret
SaveInventory ENDP

; ---- ShowInventoryItems ----
; Prints all items with their current stock

ShowInventoryItems PROC
        ; Check if there are items
        mov eax, currentInventoryCount
        cmp eax, 0
        jle show_inv_done

        ; Header
        push offset showItemsHeader
        call StdOut

        mov esi, 0

    show_inv_loop:
        cmp esi, currentInventoryCount
        jge show_inv_done

        ; Print item number (1-based)
        mov eax, esi
        inc eax
        invoke StdOut, str$(eax)

        ; Print ". "
        invoke StdOut, chr$('.', ' ')

        ; Compute pointer to record
        mov ecx, esi
        mov eax, SIZEOF ITEM_RECORD
        mul ecx
        lea edi, inventoryRecords
        add edi, eax

        ; Print name
        invoke StdOut, edi

        ; Print stock: " (Stock: "
        push offset stockPrompt
        call StdOut

        ; stock
        mov eax, [edi+IR_STOCK_OFFSET]
        invoke StdOut, str$(eax)

        ; Print closing parenthesis and newline
        push offset closeParen
        call StdOut
        invoke StdOut, chr$(13,10)

        inc esi
        jmp show_inv_loop

    show_inv_done:
        ret
ShowInventoryItems ENDP

; ---- ShowPosMenu ----
; Builds and displays the POS menu from inventoryRecords

ShowPosMenu PROC
        ; Header
        push offset menuHeader
        call StdOut

        mov esi, 0

    show_menu_loop:
        cmp esi, currentInventoryCount
        jge menu_done

        ; Print item number (1-based)
        mov eax, esi
        inc eax
        invoke StdOut, str$(eax)
        invoke StdOut, chr$('.', ' ')

        ; Compute pointer to record
        mov ecx, esi
        mov eax, SIZEOF ITEM_RECORD
        mul ecx
        lea edi, inventoryRecords
        add edi, eax

        ; Print name
        invoke StdOut, edi

        ; Print " - ₱"
        push offset menuPriceSep
        call StdOut

        ; Print price
        mov eax, [edi+IR_PRICE_OFFSET]
        invoke StdOut, str$(eax)
        invoke StdOut, chr$(13,10)

        inc esi
        jmp show_menu_loop

    menu_done:
        ; Print selection prompt: "Selection [1-N]: "
        push offset selectPrompt1
        call StdOut
        mov eax, currentInventoryCount
        invoke StdOut, str$(eax)
        push offset selectPrompt2
        call StdOut

        ret
ShowPosMenu ENDP

    end start_minimart