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

    ; ==== Receipt File Handling ====
    receiptFileName db 64 dup(0)  
    receiptFileHandle DWORD ?
    receiptBuffer db 2048 dup(0)  
    receiptBufferPtr DWORD ?
    ; Temporary variables for receipt procedures (avoid LOCAL to prevent stack issues)
    tempReceiptBytes DWORD ?
    tempReceiptHandle DWORD ?
    tempReceiptHour DWORD ?
    tempReceiptMinute DWORD ?
    tempReceiptIsPM DWORD ?
    tempReceiptIndex DWORD ?       

    ; ==== Receipt File Messages ====
    receiptSavedMsg db 13,10,"Receipt saved as: ",0
    receiptSaveErrorMsg db 13,10,"Warning: Could not save receipt to file.",13,10,0




    ; ==== File handling for inventory and summary ====
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
    inventoryHeader db 13,10,"============== Current Inventory ==============",13,10,13,10,0
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
                   db "4. Delete Item",13,10
                   db "5. POS (Point of Sale)", 13,10
                   db "6. View Sales Summary", 13,10
                   db "7. Exit", 13,10, 13,10
                   db "Selection [1-7]: ", 0



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
    posExitOptionMsg db "0. Exit/Cancel",13,10,0
    posCancelMsg db 13,10,"Transaction cancelled. Returning to main menu.",13,10,0
    addItemCancelPrompt db "Enter 0 at any prompt to cancel",13,10,0
    addItemCancelledMsg db "Add item cancelled.",13,10,0

                
    ; ==== Receipt Messages ====
    receiptHdr db 13,10, "========= RECEIPT =========",13,10,0
    dateText db "Date: ",0
    timeText db "   Time: ",0
    dateTimeBuf db 64 dup(0)
    newlineStr db 13,10,0
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
    exitProgramMsg db "Exiting.....thank youuu", 0


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


    ; ===== Delete Item menu and messages ====
    deleteItemMenu db 13,10,"========= Delete Item =========",13,10,0
    selectItemToDeletePrompt db "Enter item ID to delete (0 to cancel): ",0
    itemDeletedMsg db "Item deleted successfully!",13,10,0
    deleteCancelledMsg db "Delete cancelled.",13,10,0
    confirmDeleteMsg db "Are you sure you want to delete this item? (Y/N): ",0
    noItemsToDeleteMsg db "No items in inventory to delete.",13,10,0


    ; ===== Add Item menu and messages ====
    addItemMenu db 13,10,"========= Add New Item =========",13,10
                db "Enter item details", 13,10, 0
    namePrompt db "Item Name: ",0
    pricePrompt db "Price (₱): ",0
    initialStockPrompt db "Initial Stock: ", 0
    itemAddedMsg db "Item added succesffully!",13,10,0
    inventoryFullMsg db "Inventory is full! Cannot add more items!",13,10,0


    ; ==== Summary Messages ====
    totalSalesMsg db "Total Transactions: ",0
    totalRevenueMsg db "Total Revenue: ₱",0
    mostSoldItemMsg db "Most Sold Item: ",0
    leastStockMsg db "Items Low on Stock (< 10): ",13,10,0
    noSalesMsg db "No sales recorded yet.",13,10,0
    salesBreakdownMsg db 13,10,"--- Sales Breakdown by Item ---",13,10,0
    itemSalesLine db 64 dup(0)
    dashLine3 db "================================",13,10,0
    recordFullMsg db "Sorry, summary file is full. Please move the current summary.dat to create a new empty one",0
    soldPrefixMsg db " (Sold: ",0
    soldSuffixMsg db ")",13,10,0
    lowStockPrefixMsg db "  - ",0
    lowStockOpenParenMsg db " (",0
    lowStockSuffixMsg db " left)",13,10,0

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

    ; ==== Console Color Support ====
    hConsoleOutput DWORD ?  ; Console output handle
    ; Color constants (Windows console colors) - using CON_ prefix to avoid conflicts
    CON_COLOR_DEFAULT equ 07h      ; Gray on black
    CON_COLOR_HEADER equ 0Bh        ; Light cyan
    CON_COLOR_MENU equ 0Ah           ; Light green
    CON_COLOR_SUCCESS equ 0Ah       ; Light green
    CON_COLOR_WARNING equ 0Eh       ; Yellow
    CON_COLOR_ERROR equ 0Ch         ; Light red
    CON_COLOR_HIGHLIGHT equ 0Fh     ; Bright white
    CON_COLOR_PRICE equ 0Bh         ; Light cyan
    CON_COLOR_STOCK equ 0Eh         ; Yellow
    CON_COLOR_RECEIPT equ 0Bh       ; Light cyan
    CON_COLOR_TITLE equ 0Eh         ; Yellow

    ; ==== Box Drawing Characters (ASCII compatible) ====
    boxTopLeft db "+", 0
    boxTopRight db "+", 0
    boxBottomLeft db "+", 0
    boxBottomRight db "+", 0
    boxHorizontal db "=", 0
    boxVertical db "|", 0
    boxSingleLine db "-", 0
    boxDoubleLine db "=", 0



.code

    ; ========================================
    ; Initialize Console Colors
    ; ========================================
    InitConsoleColors PROC
        invoke GetStdHandle, STD_OUTPUT_HANDLE
        mov hConsoleOutput, eax
        ret
    InitConsoleColors ENDP

    ; ========================================
    ; Set Console Text Color
    ; ========================================
    SetColor PROC color:DWORD
        push eax
        mov eax, hConsoleOutput
        test eax, eax
        jz set_color_done
        invoke SetConsoleTextAttribute, eax, color
    set_color_done:
        pop eax
        ret
    SetColor ENDP

    ; ========================================
    ; Print Colored Text
    ; ========================================
    PrintColored PROC textPtr:DWORD, color:DWORD
        push eax
        invoke SetColor, color
        push textPtr
        call StdOut
        invoke SetColor, CON_COLOR_DEFAULT
        pop eax
        ret
    PrintColored ENDP

    ; ========================================
    ; Print Box Header
    ; ========================================
    PrintBoxHeader PROC headerTextPtr:DWORD, boxWidth:DWORD
        LOCAL i:DWORD
        push eax
        push ebx
        push ecx
        push edx
        push esi
        
        ; Set header color
        invoke SetColor, CON_COLOR_HEADER
        
        ; Top border
        invoke StdOut, addr boxTopLeft
        mov ecx, boxWidth
        sub ecx, 2
        mov i, 0
    top_border_loop:
        cmp i, ecx
        jge top_border_done
        invoke StdOut, addr boxHorizontal
        inc i
        jmp top_border_loop
    top_border_done:
        invoke StdOut, addr boxTopRight
        invoke StdOut, chr$(13,10)
        
        ; Header text with padding
        invoke StdOut, addr boxVertical
        invoke StdOut, chr$(" ")
        push headerTextPtr
        call StdOut
        
        ; Calculate padding
        push headerTextPtr
        call lstrlen
        mov ebx, boxWidth
        sub ebx, 4
        sub ebx, eax
        mov i, 0
    padding_loop:
        cmp i, ebx
        jge padding_done
        invoke StdOut, chr$(" ")
        inc i
        jmp padding_loop
    padding_done:
        invoke StdOut, chr$(" ")
        invoke StdOut, addr boxVertical
        invoke StdOut, chr$(13,10)
        
        ; Bottom border
        invoke StdOut, addr boxBottomLeft
        mov ecx, boxWidth
        sub ecx, 2
        mov i, 0
    bottom_border_loop:
        cmp i, ecx
        jge bottom_border_done
        invoke StdOut, addr boxHorizontal
        inc i
        jmp bottom_border_loop
    bottom_border_done:
        invoke StdOut, addr boxBottomRight
        invoke StdOut, chr$(13,10)
        
        invoke SetColor, CON_COLOR_DEFAULT
        
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
    PrintBoxHeader ENDP

    ; ========================================
    ; Print Simple Styled Header
    ; Format: ========= Section =========
    ; ========================================
    PrintStyledHeader PROC headerTextPtr:DWORD
        push eax
        
        invoke SetColor, CON_COLOR_HEADER
        invoke StdOut, chr$(13,10)
        
        ; Print left side equals (9 characters)
        invoke StdOut, chr$("============== ")
        
        ; Print header text (only once)
        push headerTextPtr
        call StdOut
        
        ; Print right side equals (9 characters)
        invoke StdOut, chr$(" ==============")
        
        invoke StdOut, chr$(13,10)
        invoke SetColor, CON_COLOR_DEFAULT
        
        pop eax
        ret
    PrintStyledHeader ENDP

    start_minimart: 
        ; ==== Initialize Console Colors ====
        call InitConsoleColors
        
        invoke SetColor, CON_COLOR_TITLE
        invoke StdOut, chr$("Program starting...",13,10)
        invoke SetColor, CON_COLOR_DEFAULT
        invoke Sleep, 1500  ; Wait 1.5 seconds
        ; ==== Load inventory at startup ====
        call LoadInventory 

        ; ==== Load sales at startup ====
        call LoadSalesData

        invoke SetColor, CON_COLOR_SUCCESS
        invoke StdOut, chr$("LoadInventory and LoadSalesData completed...",13,10)
        invoke StdOut, chr$("System initialized successfully!",13,10)
        invoke SetColor, CON_COLOR_DEFAULT
        invoke Sleep, 1000

        ; ==== Clear Console Screen ====
        invoke crt_system, addr clsCmd

        ; ==== Display JJRC Minimart Art ====;
        invoke SetColor, CON_COLOR_TITLE
        push offset jjrcMinimartArt
        call StdOut
        invoke SetColor, CON_COLOR_DEFAULT
        
        option_loop:
            ; ==== Display JJRC Menu with Styled Header ====
            invoke PrintStyledHeader, chr$("JJRC Minimart - Main Menu")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("1. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("View Inventory")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("2. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("Add New Item")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("3. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("Update Item Stock")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("4. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("Delete Item")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("5. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("POS (Point of Sale)")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("6. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("View Sales Summary")
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("7. ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("Exit")
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10,13,10,"  Selection [1-7]: ")
        
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
            
            ; ==== Validate input (1-7) ====
            cmp eax, 1
            jl invalid_selection_input_minimart
            cmp eax, 7
            jg invalid_selection_input_minimart

            cmp eax, 1
            je start_inventory
            cmp eax, 2
            je start_add_item
            cmp eax, 3
            je start_update_stock
            cmp eax, 4
            je start_delete_item
            cmp eax, 5
            je start_pos
            cmp eax, 6
            je start_summary
            cmp eax, 7
            je exit_program
             
        invalid_selection_input_minimart:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidSelectionMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp read_option
            
        invalid_type_input_minimart:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidTypeMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp read_option

    start_inventory:     
        call DisplayInventory
        invoke crt_system, chr$("pause")
        invoke crt_system, addr clsCmd
        jmp option_loop
        
        start_add_item:
            invoke PrintStyledHeader, chr$("Add New Item")
            call AddNewItem
            invoke crt_system, chr$("pause")
            invoke crt_system, addr clsCmd
            jmp option_loop

        start_update_stock:
            invoke PrintStyledHeader, chr$("Update Item Stock")
            call UpdateItemStock
            invoke crt_system, chr$("pause")
            invoke crt_system, addr clsCmd
            jmp option_loop

        start_delete_item:
            invoke PrintStyledHeader, chr$("Delete Item")
            call DeleteItem
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
        invoke SetColor, CON_COLOR_TITLE
        push offset shoppingCartArt
        call StdOut
        invoke SetColor, CON_COLOR_DEFAULT
        
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
     
            ; ===== Check for exit (0) =====
            cmp eax, 0
            je pos_exit_cancel
     
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
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset anotherMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT

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
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, addr totalText
            invoke SetColor, CON_COLOR_PRICE
            invoke StdOut, str$(finalTotal)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            payment_loop:
                
                ; ==== Ask for payment ====
                invoke SetColor, CON_COLOR_MENU
                invoke StdOut, chr$("  ")
                push offset paymentMsg
                call StdOut
                invoke SetColor, CON_COLOR_DEFAULT
                
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
                    
                    ; ==== Print Receipt with Styling ==== 
                    invoke PrintStyledHeader, chr$("RECEIPT")

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
                    invoke lstrlen, addr dateTimeBuf
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
                    ; ==== Print Date/Time with Color ====
                    invoke SetColor, CON_COLOR_RECEIPT
                    push offset dateTimeBuf
                    call StdOut
                    invoke SetColor, CON_COLOR_DEFAULT
                    invoke StdOut, chr$(13,10)
                    
                    ; ==== Print Separator Line ====
                    invoke SetColor, CON_COLOR_MENU
                    invoke StdOut, chr$("  ")
                    invoke StdOut, chr$("------------------------------------------")
                    invoke StdOut, chr$(13,10)
                    invoke SetColor, CON_COLOR_DEFAULT

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
            
            ; ==== Print item with colors ====
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset itemText
            call StdOut
            mov eax, esi
            inc eax
            invoke StdOut, str$(eax)
            push offset colonText
            call StdOut
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, edi
            invoke SetColor, CON_COLOR_RECEIPT
            push offset priceText
            call StdOut
            invoke SetColor, CON_COLOR_STOCK
            invoke StdOut, str$(receiptQtys[esi*4])
            invoke SetColor, CON_COLOR_RECEIPT
            push offset atText
            call StdOut
            invoke SetColor, CON_COLOR_PRICE
            mov eax, [edi + NAME_SIZE]  ; Get price from database
            invoke StdOut, str$(eax)
            invoke SetColor, CON_COLOR_RECEIPT
            push offset equalText
            call StdOut
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, str$(receiptTotals[esi*4])
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            ;==== Increase item count ====
            inc esi

            ; ==== continue loop ====
            jmp print_items


        print_totals:

            ;==== Print Separator ==== 
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            invoke StdOut, chr$("------------------------------------------")
            invoke StdOut, chr$(13,10)
            invoke SetColor, CON_COLOR_DEFAULT

            ; ==== Print Subtotal ====
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset subText
            call StdOut
            invoke SetColor, CON_COLOR_PRICE
            invoke StdOut, str$(runningTotal)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)

            ; ==== Print Tax Amount ====
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset taxText
            call StdOut
            invoke SetColor, CON_COLOR_PRICE
            invoke StdOut, str$(tax)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            ;==== Print Separator ==== 
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            invoke StdOut, chr$("------------------------------------------")
            invoke StdOut, chr$(13,10)
            invoke SetColor, CON_COLOR_DEFAULT
            
            ; ==== Print Final Total ====
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, chr$("  ")
            push offset totalText
            call StdOut
            invoke SetColor, CON_COLOR_PRICE
            invoke StdOut, str$(finalTotal)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            ;==== Print Separator ==== 
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            invoke StdOut, chr$("==========================================")
            invoke StdOut, chr$(13,10)
            invoke SetColor, CON_COLOR_DEFAULT
            

            ; ==== Print Payment Details ====
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset paidText
            call StdOut
            invoke SetColor, CON_COLOR_SUCCESS
            invoke StdOut, str$(payment)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset changeText
            call StdOut
            invoke SetColor, CON_COLOR_SUCCESS
            invoke StdOut, str$(change)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)

            ; ==== Print Thank you message ====
            invoke SetColor, CON_COLOR_SUCCESS
            invoke StdOut, chr$(13,10,"  ")
            push offset thankYouMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT

            ; ==== Build and Save Receipt to File ====
            ; Build receipt content
            call BuildReceiptContent
            ; Save receipt to file
            call SaveReceiptToFile
            ; Continue even if receipt save fails

            ; ==== Record the sale ====
            call RecordSale
            call SaveSalesData
            
            ; Returns to main menu, prior to this it was exiting instantly
            invoke StdOut, chr$(13,10)
            invoke crt_system, chr$("pause")
            invoke crt_system, addr clsCmd
            jmp option_loop  ; Return to main menu instead of exiting

        out_of_stock_error:
            invoke SetColor, CON_COLOR_ERROR
            push offset outOfStockMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp item_loop

        insufficient_stock_error:
            invoke SetColor, CON_COLOR_WARNING
            push offset insufficientStockMsg
            call StdOut
            invoke SetColor, CON_COLOR_HIGHLIGHT
            mov ebx, stock
            invoke StdOut, str$(stock)
            invoke SetColor, CON_COLOR_WARNING
            push offset availableMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp read_quantity
            

        invalid_inventory_selection_input:
            push offset invalidSelectionMsg
            call StdOut
            
            jmp read_item
            
        pos_exit_cancel:
            ; Check if there are items in cart
            mov eax, itemCount
            cmp eax, 0
            jg pos_exit_with_items
            
            ; No items, just exit
            invoke SetColor, CON_COLOR_WARNING
            push offset posCancelMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            invoke crt_system, addr clsCmd
            jmp option_loop
            
        pos_exit_with_items:
            ; Items in cart, confirm cancellation
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$(13,10,"  You have items in your cart. Cancel transaction? (Y/N): ")
            invoke SetColor, CON_COLOR_DEFAULT
            push 32
            push offset inputBuf
            call StdIn
            
            mov al, byte ptr [inputBuf]
            cmp al, 'Y'
            je pos_confirm_cancel
            cmp al, 'y'
            je pos_confirm_cancel
            cmp al, 'N'
            je pos_continue_transaction
            cmp al, 'n'
            je pos_continue_transaction
            ; Invalid input, continue transaction
            jmp pos_continue_transaction
            
        pos_confirm_cancel:
            ; Reset cart
            mov runningTotal, 0
            mov itemCount, 0
            invoke SetColor, CON_COLOR_WARNING
            push offset posCancelMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            invoke crt_system, addr clsCmd
            jmp option_loop
            
        pos_continue_transaction:
            invoke crt_system, addr clsCmd
            jmp item_loop
            
        invalid_selection_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidSelectionMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp read_item
            
        invalid_quantity_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidQuantityMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp read_quantity

        invalid_type_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidTypeMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp read_item

        invalid_payment_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidPay
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp payment_loop
        
        insufficient_payment:
            invoke SetColor, CON_COLOR_ERROR
            push offset insuffMsg
            call StdOut
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, str$(finalTotal)
            invoke SetColor, CON_COLOR_DEFAULT
            jmp payment_loop

        exit_program:
            invoke SetColor, CON_COLOR_TITLE
            invoke StdOut, chr$(13,10,"  ")
            push offset exitProgramMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
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

        invoke PrintStyledHeader, chr$("MiniMart POS System - Select Items")


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
            
            ; Display with colors
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            mov eax, itemNum
            inc eax ;To display as 1-based since by default it is 0 based
            invoke StdOut, str$(eax)
            invoke StdOut, chr$(". ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, esi
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(" - ")
            invoke SetColor, CON_COLOR_PRICE
            invoke StdOut, chr$("₱")
            invoke StdOut, str$(itemPrice)
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(" ")
            invoke SetColor, CON_COLOR_STOCK
            invoke StdOut, addr stockDisplayPrompt
            invoke StdOut, str$(itemStock)
            invoke StdOut, addr closeParen
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            inc itemNum
            jmp display_loop
            
        no_items:
            invoke SetColor, CON_COLOR_WARNING
            push offset noItemsMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
        

        display_done:
            ; Display exit option
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$(13,10,"  ")
            invoke StdOut, chr$("0. ")
            invoke SetColor, CON_COLOR_ERROR
            invoke StdOut, chr$("Exit/Cancel")
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10,13,10,"  Selection [0-")
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
        
        ;Display add item menu with colors
        invoke SetColor, CON_COLOR_MENU
        invoke StdOut, chr$("  Enter item details",13,10)
        invoke SetColor, CON_COLOR_WARNING
        invoke StdOut, chr$("  ")
        push offset addItemCancelPrompt
        call StdOut
        invoke SetColor, CON_COLOR_DEFAULT
        invoke StdOut, chr$(13,10)

        ; Get item name
        get_name:
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset namePrompt
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT

            push NAME_SIZE
            push offset tempName
            call StdIn
            
            ; Check for cancel - input must be exactly "0"
            cmp byte ptr [tempName], '0'
            jne check_name_empty
            ; Check if second char is null, CR, or LF (meaning just "0")
            cmp byte ptr [tempName + 1], 0
            je add_item_cancelled
            cmp byte ptr [tempName + 1], 13
            je add_item_cancelled
            cmp byte ptr [tempName + 1], 10
            je add_item_cancelled
            
        check_name_empty:
            ; Check if name is empty (invalid, ask again)
            cmp byte ptr [tempName], 0
            je name_empty_error
            cmp byte ptr [tempName], 13
            je name_empty_error
            cmp byte ptr [tempName], 10
            je name_empty_error
            jmp get_price  ; Name is valid, proceed
            
        name_empty_error:
            push offset invalidSelectionMsg
            call StdOut
            jmp get_name
        
        ;Get item price
        get_price:
            ; Display price prompt
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset pricePrompt
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
            ; Input
            push 32
            push offset inputBuf
            call StdIn

            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_price_input
            
            ; ==== Check for cancel (0) before validating digits ====
            cmp byte ptr [inputBuf], '0'
            jne validate_price_digits
            ; Check if it's just "0" (next char should be null, CR, or LF)
            cmp byte ptr [inputBuf + 1], 0
            je add_item_cancelled
            cmp byte ptr [inputBuf + 1], 13
            je add_item_cancelled
            cmp byte ptr [inputBuf + 1], 10
            je add_item_cancelled
            
        validate_price_digits:
            ; ==== Validate that input contains only digits ====
            mov esi, offset inputBuf
        validate_price_loop:
            mov al, [esi]
            cmp al, 0                    ; End of string?
            je price_digits_valid
            cmp al, 13                   ; Carriage return?
            je price_digits_valid
            cmp al, 10                   ; Line feed?
            je price_digits_valid
            cmp al, '0'                  ; Less than '0'?
            jb invalid_price_input
            cmp al, '9'                  ; Greater than '9'?
            ja invalid_price_input
            inc esi
            jmp validate_price_loop
            
        price_digits_valid:
            ; ==== Convert input to integer ====
            push offset inputBuf
            call atodw
            jc invalid_price_input
            
            ; ==== Validate price is positive ====
            cmp eax, 0
            jle invalid_price_input
            mov tempPrice, eax
            jmp price_valid_done  ; Skip error handler
            
        invalid_price_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidQuantityMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp get_price
            
        price_valid_done:
            
        ;Get item Stock
        get_stock:
            ; Display stock prompt
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset initialStockPrompt
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
            ;input
            push 32
            push offset inputBuf
            call StdIn
            
            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_stock_input

            ; ==== Check for cancel (0) before validating digits ====
            cmp byte ptr [inputBuf], '0'
            jne validate_stock_digits
            ; Check if it's just "0" (next char should be null, CR, or LF)
            cmp byte ptr [inputBuf + 1], 0
            je add_item_cancelled
            cmp byte ptr [inputBuf + 1], 13
            je add_item_cancelled
            cmp byte ptr [inputBuf + 1], 10
            je add_item_cancelled
            
        validate_stock_digits:
            ; ==== Validate that input contains only digits ====
            mov esi, offset inputBuf
        validate_stock_loop:
            mov al, [esi]
            cmp al, 0                    ; End of string?
            je stock_digits_valid
            cmp al, 13                   ; Carriage return?
            je stock_digits_valid
            cmp al, 10                   ; Line feed?
            je stock_digits_valid
            cmp al, '0'                  ; Less than '0'?
            jb invalid_stock_input
            cmp al, '9'                  ; Greater than '9'?
            ja invalid_stock_input
            inc esi
            jmp validate_stock_loop
            
        stock_digits_valid:
            ; ==== Convert input to integer ====
            push offset inputBuf
            call atodw
            jc invalid_stock_input
            
            ; ==== Validate stock is non-negative ====
            ; Note: 0 is valid for stock, but "0" alone is used for cancel
            ; If we get here with 0, it means it was "00" or similar, which is valid
            cmp eax, 0
            jl invalid_stock_input
            mov tempStock, eax
            jmp stock_valid_done  ; Skip error handler
            
        invalid_stock_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidQuantityMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp get_stock
            
        stock_valid_done:
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
            invoke SetColor, CON_COLOR_SUCCESS
            invoke StdOut, chr$("  ")
            push offset itemAddedMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
            ret

        inventory_full:
            invoke SetColor, CON_COLOR_ERROR
            invoke StdOut, chr$("  ")
            push offset inventoryFullMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
            
        add_item_cancelled:
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$("  ")
            push offset addItemCancelledMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret


    AddNewItem ENDP

    ; ========================================
    ; Display Inventory
    ; ========================================

    DisplayInventory PROC
        LOCAL itemNum:DWORD, itemOffset:DWORD
        LOCAL itemPrice:DWORD, itemStock:DWORD

        ;Display inventory header with styling
        invoke PrintStyledHeader, chr$("Current Inventory")

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

        ; Display Item with colors
        invoke SetColor, CON_COLOR_MENU
        invoke StdOut, chr$("  ")
        invoke StdOut, addr boxVertical
        invoke StdOut, chr$(" ID: ")
        invoke SetColor, CON_COLOR_HIGHLIGHT
        mov eax, itemNum
        inc eax
        invoke StdOut, str$(eax)
        invoke SetColor, CON_COLOR_MENU
        invoke StdOut, chr$(" ")
        invoke StdOut, addr boxVertical
        invoke StdOut, chr$(" Name: ")
        invoke SetColor, CON_COLOR_HIGHLIGHT
        invoke StdOut, esi
        invoke SetColor, CON_COLOR_MENU
        invoke StdOut, chr$(" ")
        invoke StdOut, addr boxVertical
        invoke StdOut, chr$(" Price: ")
        invoke SetColor, CON_COLOR_PRICE
        invoke StdOut, chr$("₱")
        invoke StdOut, str$(itemPrice)
        invoke SetColor, CON_COLOR_MENU
        invoke StdOut, chr$(" ")
        invoke SetColor, CON_COLOR_STOCK
        invoke StdOut, chr$("│ Stock: ")
        invoke StdOut, str$(itemStock)
        invoke SetColor, CON_COLOR_MENU
        invoke StdOut, chr$(" ")
        invoke StdOut, addr boxVertical
        invoke StdOut, chr$(13,10)
        invoke SetColor, CON_COLOR_DEFAULT
        
        inc itemNum
        jmp inv_loop

        
    no_items_inv:
        invoke SetColor, CON_COLOR_WARNING
        push offset noItemsMsg
        call StdOut
        invoke SetColor, CON_COLOR_DEFAULT
        
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

        get_item_id:
            ;display prompt for item id
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset selectItemPrompt
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT

            ; get user input
            push 32
            push offset inputBuf
            call StdIn

            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_item_id_input 

            ; ==== Validate that input contains only digits ====
            mov esi, offset inputBuf
        validate_item_id_loop:
            mov al, [esi]
            cmp al, 0                    ; End of string?
            je item_id_digits_valid
            cmp al, 13                   ; Carriage return?
            je item_id_digits_valid
            cmp al, 10                   ; Line feed?
            je item_id_digits_valid
            cmp al, '0'                  ; Less than '0'?
            jb invalid_item_id_input
            cmp al, '9'                  ; Greater than '9'?
            ja invalid_item_id_input
            inc esi
            jmp validate_item_id_loop
            
        item_id_digits_valid:
            ; ==== Convert user input to int ====
            push offset inputBuf
            call atodw
            jc invalid_item_id_input
            
            ; ==== Check for cancel (0) ====
            cmp eax, 0
            je update_cancelled

            mov itemID, eax

            ; ==== Validate item id input range ====
            cmp eax, 1
            jl invalid_item_id
            mov ebx, currentItemCount
            cmp eax, ebx
            jg invalid_item_id
            jmp item_id_valid_done  ; Skip error handler
            
        invalid_item_id_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidTypeMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp get_item_id
            
        item_id_valid_done:
            ; convert user input to 0 based index so I can start changing the database
            dec eax

            ; calculate item offset -> this is where the calculations takes place
            mov ebx, ITEM_SIZE
            mul ebx
            mov itemOffset, eax
            

        get_new_stock:
            ; display prompt for new stock
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset newStockPrompt
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
            ; get user input
            push 32
            push offset inputBuf
            call StdIn

            ; ==== Check if input is empty ====
            cmp byte ptr [inputBuf], 0
            je invalid_new_stock_input
            
            ; ==== Validate that input contains only digits ====
            mov esi, offset inputBuf
        validate_new_stock_loop:
            mov al, [esi]
            cmp al, 0                    ; End of string?
            je new_stock_digits_valid
            cmp al, 13                   ; Carriage return?
            je new_stock_digits_valid
            cmp al, 10                   ; Line feed?
            je new_stock_digits_valid
            cmp al, '0'                  ; Less than '0'?
            jb invalid_new_stock_input
            cmp al, '9'                  ; Greater than '9'?
            ja invalid_new_stock_input
            inc esi
            jmp validate_new_stock_loop
            
        new_stock_digits_valid:
            ; ==== Convert input to integer ====
            push offset inputBuf
            call atodw
            jc invalid_new_stock_input
            
            ; ==== Validate stock is non-negative ====
            ; Note: 0 is valid (no change to stock)
            cmp eax, 0
            jl invalid_new_stock_input
            
            mov newStock, eax
            jmp new_stock_valid_done  ; Skip error handler
            
        invalid_new_stock_input:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidQuantityMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp get_new_stock
            
        new_stock_valid_done:
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
            invoke SetColor, CON_COLOR_SUCCESS
            invoke StdOut, chr$("  ")
            push offset stockUpdatedMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
            
        invalid_item_id:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidSelectionMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp get_item_id
            
        update_cancelled:
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$("  ")
            push offset updateCancelledMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
            
        no_items_to_update:
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$("  ")
            push offset noItemsMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
            
        
    
    UpdateItemStock ENDP
    
    ; ========================================
    ; Delete Item from Inventory
    ; ========================================
    DeleteItem PROC
        LOCAL itemID:DWORD, itemOffset:DWORD
        LOCAL i:DWORD, bytesToMove:DWORD
        LOCAL sourcePtr:DWORD, destPtr:DWORD
        
        ; Check if inventory is empty
        mov eax, currentItemCount
        cmp eax, 0
        je no_items_to_delete
        
        ; Display current inventory first so user can see what to delete
        call DisplayInventory
        
        get_item_to_delete:
            ; Display prompt for item ID
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            push offset selectItemToDeletePrompt
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
            ; Get user input
            push 32
            push offset inputBuf
            call StdIn
            
            ; Validate input
            cmp byte ptr [inputBuf], 0
            je get_item_to_delete
            
            ; Convert user input to int
            push offset inputBuf
            call atodw
            jc get_item_to_delete
            
            ; Check for cancel (0)
            cmp eax, 0
            je delete_cancelled
            
            mov itemID, eax
            
            ; Validate item ID input range
            cmp eax, 1
            jl invalid_delete_item_id
            mov ebx, currentItemCount
            cmp eax, ebx
            jg invalid_delete_item_id
            
            ; Convert user input to 0-based index
            dec eax
            mov itemID, eax
            
            ; Get item name for confirmation display
            mov eax, itemID
            mov ebx, ITEM_SIZE
            mul ebx
            mov itemOffset, eax
            lea esi, itemDatabase
            add esi, itemOffset
            
            ; Display item to be deleted
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$(13,10,"  Item to delete: ")
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, esi
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)
            
            ; Confirm deletion
            invoke SetColor, CON_COLOR_ERROR
            invoke StdOut, chr$("  ")
            push offset confirmDeleteMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
            push 32
            push offset inputBuf
            call StdIn
            
            mov al, byte ptr [inputBuf]
            cmp al, 'Y'
            je confirm_delete
            cmp al, 'y'
            je confirm_delete
            cmp al, 'N'
            je delete_cancelled
            cmp al, 'n'
            je delete_cancelled
            ; Invalid input, treat as cancel
            jmp delete_cancelled
            
        confirm_delete:
            ; Calculate how many bytes need to be moved
            ; Items after the deleted one need to shift forward
            mov eax, currentItemCount
            sub eax, itemID
            dec eax  ; Subtract 1 because we're deleting one item
            cmp eax, 0
            jle no_items_to_shift  ; No items to shift if deleting last item
            
            ; Calculate bytes to move
            mov ebx, ITEM_SIZE
            mul ebx
            mov bytesToMove, eax
            
            ; Calculate source pointer (item after deleted item)
            mov eax, itemID
            inc eax  ; Next item
            mov ebx, ITEM_SIZE
            mul ebx
            lea esi, itemDatabase
            add esi, eax
            mov sourcePtr, esi
            
            ; Calculate destination pointer (deleted item's position)
            mov eax, itemID
            mov ebx, ITEM_SIZE
            mul ebx
            lea edi, itemDatabase
            add edi, eax
            mov destPtr, edi
            
            ; Move items forward (shift left)
            mov ecx, bytesToMove
            shr ecx, 2  ; Divide by 4 for DWORD moves (faster)
            mov esi, sourcePtr
            mov edi, destPtr
            rep movsd  ; Move DWORDs
            
            ; Handle remaining bytes if any (ITEM_SIZE might not be multiple of 4)
            mov ecx, bytesToMove
            and ecx, 3  ; Get remainder
            jz shift_done
            rep movsb  ; Move remaining bytes
            
        shift_done:
        no_items_to_shift:
            ; Clear the last item's space (the one that was shifted from)
            mov eax, currentItemCount
            dec eax  ; Last item index
            mov ebx, ITEM_SIZE
            mul ebx
            lea edi, itemDatabase
            add edi, eax
            invoke RtlZeroMemory, edi, ITEM_SIZE
            
            ; Decrement item count
            dec currentItemCount
            
            ; Save inventory to file
            call SaveInventory
            
            ; Display success message
            invoke SetColor, CON_COLOR_SUCCESS
            invoke StdOut, chr$("  ")
            push offset itemDeletedMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
            
        invalid_delete_item_id:
            invoke SetColor, CON_COLOR_ERROR
            push offset invalidSelectionMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            jmp get_item_to_delete
            
        delete_cancelled:
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$("  ")
            push offset deleteCancelledMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
            
        no_items_to_delete:
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$("  ")
            push offset noItemsToDeleteMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
    
    DeleteItem ENDP
    
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
        invoke GetLocalTime, addr localTime
        
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

            ;jmp start_minimart
            ret
            

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
        mov ebx, SALE_RECORD_SIZE   
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
        LOCAL i:DWORD, j:DWORD, itemOffset:DWORD, itemRevenue:DWORD
        
        ;Display header with styling
        invoke PrintStyledHeader, chr$("Sales Summary")
        
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
            mov ebx, SALE_RECORD_SIZE
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
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset totalSalesMsg
            call StdOut
            invoke SetColor, CON_COLOR_HIGHLIGHT
            invoke StdOut, str$(currentSalesCount)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10)

            ; Display total revenue
            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset totalRevenueMsg
            call StdOut
            invoke SetColor, CON_COLOR_PRICE
            invoke StdOut, str$(totalRevenue)
            invoke SetColor, CON_COLOR_DEFAULT
            invoke StdOut, chr$(13,10, 13,10)

            ; Display most sold item
            cmp mostSoldQty, 0
            je no_most_sold

            invoke SetColor, CON_COLOR_RECEIPT
            invoke StdOut, chr$("  ")
            push offset mostSoldItemMsg
            call StdOut
            invoke SetColor, CON_COLOR_HIGHLIGHT

            ; get item name of the most sold
            mov eax, mostSoldItemID
            mov ebx, ITEM_SIZE
            mul ebx
            lea esi, itemDatabase
            add esi, eax
            invoke StdOut, esi

            invoke SetColor, CON_COLOR_STOCK
            push offset soldPrefixMsg
            call StdOut
            invoke StdOut, str$(mostSoldQty)
            push offset soldSuffixMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
         no_most_sold:
            ; Display sales breakdown with colors
            invoke SetColor, CON_COLOR_HEADER
            invoke StdOut, chr$(13,10,"  ")
            push offset salesBreakdownMsg
            call StdOut
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            invoke StdOut, chr$("========================================")
            invoke StdOut, chr$(13,10)
            invoke SetColor, CON_COLOR_DEFAULT
            
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
                imul eax, edx           ; multiply by price to get revenue per item. left out tax since it's not part of the revenue ata
                mov itemRevenue, eax    ; save revenue before invoke calls (invoke doesn't preserve registers)
                
                ; Format and display with colors
                invoke SetColor, CON_COLOR_MENU
                invoke StdOut, chr$("  ")
                mov ecx, i
                inc ecx
                invoke StdOut, str$(ecx)
                invoke StdOut, chr$(". ")
                invoke SetColor, CON_COLOR_HIGHLIGHT
                invoke StdOut, esi
                invoke SetColor, CON_COLOR_MENU
                invoke StdOut, chr$(": Qty ")
                invoke SetColor, CON_COLOR_STOCK
                mov eax, [edi]
                invoke StdOut, str$(eax)
                invoke SetColor, CON_COLOR_MENU
                invoke StdOut, chr$("  Revenue: ")
                invoke SetColor, CON_COLOR_PRICE
                invoke StdOut, chr$("₱")
                invoke StdOut, str$(itemRevenue)
                invoke SetColor, CON_COLOR_DEFAULT
                invoke StdOut, chr$(13,10)
                
            skip_item:
                inc i
                jmp display_breakdown
                
        breakdown_done:
            invoke SetColor, CON_COLOR_MENU
            invoke StdOut, chr$("  ")
            invoke StdOut, chr$("========================================")
            invoke StdOut, chr$(13,10)
            invoke SetColor, CON_COLOR_DEFAULT
            
            ; Display low stock warning with colors
            invoke SetColor, CON_COLOR_WARNING
            invoke StdOut, chr$("  ")
            push offset leastStockMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            
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
                mov eax, [esi + NAME_SIZE + 4]  ; stock amount
                
                cmp eax, 10
                jge not_low_stock
                
                ; Display item with low stock with colors
                invoke SetColor, CON_COLOR_WARNING
                invoke StdOut, chr$("  ")
                push offset lowStockPrefixMsg
                call StdOut
                invoke SetColor, CON_COLOR_HIGHLIGHT
                invoke StdOut, esi
                invoke SetColor, CON_COLOR_WARNING
                push offset lowStockOpenParenMsg
                call StdOut
                invoke SetColor, CON_COLOR_ERROR
                mov eax, [esi + NAME_SIZE + 4]
                invoke StdOut, str$(eax)
                invoke SetColor, CON_COLOR_WARNING
                push offset lowStockSuffixMsg
                call StdOut
                invoke SetColor, CON_COLOR_DEFAULT
                
            not_low_stock:
                inc i
                jmp check_low_stock
                
        low_stock_done:
            invoke StdOut, chr$(13,10)
            ret
            
        no_sales_summary:
            invoke SetColor, CON_COLOR_WARNING
            push offset noSalesMsg
            call StdOut
            invoke SetColor, CON_COLOR_DEFAULT
            ret
                 
        
    DisplaySalesSummary ENDP
    
    ; ========================================
    ; Append String to Receipt Buffer
    ; ========================================
    AppendToReceipt PROC
        push eax
        push esi
        push edi
        push ecx
        push ebx
        
        ; Safety check: ensure ESI is valid
        test esi, esi
        jz append_done
        
        ; ESI should point to the string to append
        ; Get current buffer position
        mov edi, receiptBufferPtr
        
        ; Safety check: ensure buffer pointer is initialized
        lea ebx, receiptBuffer
        cmp edi, ebx
        jl append_done  ; Invalid pointer, skip
        
        ; Check buffer bounds (2048 bytes total)
        lea ebx, receiptBuffer
        add ebx, 2047  ; Max position (leave room for null terminator)
        cmp edi, ebx
        jge append_done  ; Buffer full, skip
        
        ; Copy string to buffer (excluding null terminator for concatenation)
        lea ebx, receiptBuffer
        add ebx, 2047
        append_loop:
            mov al, [esi]
            test al, al
            jz append_done
            cmp edi, ebx
            jge append_done  ; Buffer full, stop
            mov [edi], al
            inc esi
            inc edi
            jmp append_loop
            
        append_done:
            ; Update buffer pointer (null terminator not copied, will be added at end)
            mov receiptBufferPtr, edi
            
        pop ebx
        pop ecx
        pop edi
        pop esi
        pop eax
        ret
            
    AppendToReceipt ENDP

    ; ========================================
    ; Append Number to Receipt Buffer
    ; ========================================
    AppendNumberToReceipt PROC numberValue:DWORD
        LOCAL tempStr[32]:BYTE
        
        push eax          ; ADD THIS for extra safety
        push esi          ; ADD THIS
        
        ; Convert number to string
        invoke wsprintf, addr tempStr, chr$("%d"), numberValue
        
        ; Append the string
        lea esi, tempStr
        call AppendToReceipt
        
        pop esi           ; ADD THIS
        pop eax           ; ADD THIS
        ret
        
    AppendNumberToReceipt ENDP

    ; ========================================
    ; Generate Receipt Filename from Timestamp
    ; Format: receipt_YYYYMMDD_HHMMSS.txt
    ; ========================================
    GenerateReceiptFilename PROC
        ; Preserve ALL registers that might be used by caller
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi
        
        ; Get current date/time
        invoke GetLocalTime, addr localTime
        
        ; Format: receipt_YYYYMMDD_HHMMSS.txt
        ; Load all time values as 32-bit DWORDs for consistency with wsprintf
        movzx eax, localTime.wYear
        movzx ebx, localTime.wMonth
        movzx ecx, localTime.wDay
        movzx edx, localTime.wHour
        movzx esi, localTime.wMinute
        movzx edi, localTime.wSecond
        
        ; Use wsprintf to format the filename - all parameters are now 32-bit DWORDs
        invoke wsprintf, addr receiptFileName, chr$("receipt_%04d%02d%02d_%02d%02d%02d.txt"), \
               eax, ebx, ecx, edx, esi, edi
        
        ; Restore all registers in reverse order
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
        
    GenerateReceiptFilename ENDP

    ; ========================================
    ; Save Receipt to File
    ; ========================================
    SaveReceiptToFile PROC
        ; Preserve all registers FIRST - critical for stack integrity
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi
        
        ; Initialize file handle to invalid (using global temp variable)
        mov tempReceiptHandle, INVALID_HANDLE_VALUE
        mov tempReceiptBytes, 0
        
        ; Safety check: ensure receiptBufferPtr is initialized
        lea eax, receiptBuffer
        mov ebx, receiptBufferPtr
        test ebx, ebx
        jz save_receipt_exit_safe  ; Null pointer, skip
        cmp ebx, eax
        jl save_receipt_exit_safe  ; Pointer before buffer start, skip
        
        ; Generate filename first
        call GenerateReceiptFilename
        
        ; Calculate bytes to write
        mov eax, receiptBufferPtr
        lea ebx, receiptBuffer
        sub eax, ebx
        mov tempReceiptBytes, eax
        
        ; Check if buffer is empty or invalid
        cmp tempReceiptBytes, 0
        jle save_receipt_exit_safe
        
        ; Safety check: ensure we don't exceed buffer size
        cmp tempReceiptBytes, 2048
        jg save_receipt_exit_safe
        
        ; Create the file
        invoke CreateFile, addr receiptFileName, GENERIC_WRITE, 0, NULL, \
               CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        cmp eax, INVALID_HANDLE_VALUE
        je save_receipt_exit_safe
        mov tempReceiptHandle, eax
        
        ; Write the receipt content
        invoke WriteFile, tempReceiptHandle, addr receiptBuffer, tempReceiptBytes, addr bytesWritten, NULL
        test eax, eax
        jz save_receipt_close_safe
        
        ; Verify bytes written
        mov eax, bytesWritten
        cmp eax, tempReceiptBytes
        jne save_receipt_close_safe
        
        ; Close the file
        invoke CloseHandle, tempReceiptHandle
        mov tempReceiptHandle, INVALID_HANDLE_VALUE
        
        ; Display success message
        push offset receiptSavedMsg
        call StdOut
        push offset receiptFileName
        call StdOut
        invoke StdOut, chr$(13,10)
        invoke StdOut, chr$(13,10)
        
        ; Success - restore registers and return
        jmp save_receipt_exit_safe
        
    save_receipt_close_safe:
        ; Close file if it was opened
        cmp tempReceiptHandle, INVALID_HANDLE_VALUE
        je save_receipt_exit_safe
        invoke CloseHandle, tempReceiptHandle
        
    save_receipt_exit_safe:
        ; Restore all registers in reverse order
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        
        ; Return normally - don't exit program
        ret
        
    SaveReceiptToFile ENDP

    ; ========================================
    ; Build Receipt Content in Buffer
    ; ========================================
    BuildReceiptContent PROC
        ; Preserve all registers
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi

        ; Initialize buffer pointer FIRST - critical for safety
        lea eax, receiptBuffer
        mov receiptBufferPtr, eax
        
        ; Clear buffer
        invoke RtlZeroMemory, addr receiptBuffer, 2048
        
        ; Get current date/time
        invoke GetLocalTime, addr localTime
        
        ; Format Date: YYYY-MM-DD
        movzx eax, localTime.wYear
        movzx ebx, localTime.wMonth
        movzx ecx, localTime.wDay
        invoke wsprintf, addr dateTimeBuf, chr$("Date: %04d-%02d-%02d"), eax, ebx, ecx
        
        ; Format Time: HH:MM AM/PM (using global temp variables)
        movzx eax, localTime.wHour
        movzx ebx, localTime.wMinute
        mov tempReceiptMinute, ebx
        mov tempReceiptIsPM, 0
        
        ; Convert to 12-hour format
        cmp eax, 0
        je build_time_midnight
        cmp eax, 12
        je build_time_noon
        jl build_time_am
        ; PM case (13-23)
        sub eax, 12
        mov tempReceiptIsPM, 1
        jmp build_time_format_done
    build_time_midnight:
        mov eax, 12
        mov tempReceiptIsPM, 0
        jmp build_time_format_done
    build_time_noon:
        mov eax, 12
        mov tempReceiptIsPM, 1
        jmp build_time_format_done
    build_time_am:
        ; AM case (1-11), eax already correct
        mov tempReceiptIsPM, 0
    build_time_format_done:
        mov tempReceiptHour, eax
        
        ; Append time to dateTimeBuf - with safety check
        invoke lstrlen, addr dateTimeBuf
        lea esi, dateTimeBuf
        add esi, eax
        
        ; Safety check: ensure we don't overflow dateTimeBuf (64 bytes)
        lea ebx, dateTimeBuf
        add ebx, 60  ; Leave room for time string and null terminator
        cmp esi, ebx
        jge build_time_complete  ; Too close to end, skip time formatting
        
        ; Format time string
        cmp tempReceiptIsPM, 0
        je build_format_am
        invoke wsprintf, esi, chr$("   Time: %02d:%02d PM"), tempReceiptHour, tempReceiptMinute
        jmp build_time_complete
    build_format_am:
        invoke wsprintf, esi, chr$("   Time: %02d:%02d AM"), tempReceiptHour, tempReceiptMinute
    build_time_complete:
        
        ; Add receipt header
        lea esi, receiptHdr
        call AppendToReceipt
        
        ; Add date/time
        lea esi, dateTimeBuf
        call AppendToReceipt
        lea esi, newlineStr
        call AppendToReceipt
        
        ; Add dash line
        lea esi, dashLine
        call AppendToReceipt
        
        ; Add all items (using global temp variable)
        mov tempReceiptIndex, 0
        
    build_items_loop:
        mov eax, tempReceiptIndex
        cmp eax, itemCount
        jge build_items_done
        
        ; Get item index
        mov eax, receiptItems[eax*4]
        
        ; Calculate item offset in database
        mov ebx, ITEM_SIZE
        mul ebx
        lea edi, itemDatabase
        add edi, eax
        
        ; Add "Item X: "
        lea esi, itemText
        call AppendToReceipt
        
        mov eax, tempReceiptIndex
        inc eax
        invoke AppendNumberToReceipt, eax
        
        lea esi, colonText
        call AppendToReceipt
        
        ; Add item name
        mov esi, edi
        call AppendToReceipt
        
        ; Add " x "
        lea esi, priceText
        call AppendToReceipt
        
        ; Add quantity
        mov eax, tempReceiptIndex
        mov ebx, receiptQtys[eax*4]
        invoke AppendNumberToReceipt, ebx
        
        ; Add " @ ₱"
        lea esi, atText
        call AppendToReceipt
        
        ; Add price
        mov eax, [edi + NAME_SIZE]
        invoke AppendNumberToReceipt, eax
        
        ; Add " = ₱"
        lea esi, equalText
        call AppendToReceipt
        
        ; Add total
        mov eax, tempReceiptIndex
        mov ebx, receiptTotals[eax*4]
        invoke AppendNumberToReceipt, ebx
        
        ; Add newline
        lea esi, newlineStr
        call AppendToReceipt
        
        inc tempReceiptIndex
        jmp build_items_loop
        
    build_items_done:
        ; Add separator
        lea esi, dashLine
        call AppendToReceipt
        
        ; Add subtotal
        lea esi, subText
        call AppendToReceipt
        invoke AppendNumberToReceipt, runningTotal
        lea esi, newlineStr
        call AppendToReceipt
        
        ; Add tax
        lea esi, taxText
        call AppendToReceipt
        invoke AppendNumberToReceipt, tax
        lea esi, newlineStr
        call AppendToReceipt
        
        ; Add separator
        lea esi, dashLine
        call AppendToReceipt
        
        ; Add total
        lea esi, totalText
        call AppendToReceipt
        invoke AppendNumberToReceipt, finalTotal
        lea esi, newlineStr
        call AppendToReceipt
        
        ; Add separator
        lea esi, dashLine2
        call AppendToReceipt
        
        ; Add payment
        lea esi, paidText
        call AppendToReceipt
        invoke AppendNumberToReceipt, payment
        lea esi, newlineStr
        call AppendToReceipt
        
        ; Add change
        lea esi, changeText
        call AppendToReceipt
        invoke AppendNumberToReceipt, change
        lea esi, newlineStr
        call AppendToReceipt
        
        ; Add thank you message
        lea esi, thankYouMsg
        call AppendToReceipt
        
        ; Ensure null terminator at end of buffer
        mov edi, receiptBufferPtr
        lea ebx, receiptBuffer
        add ebx, 2047
        cmp edi, ebx
        jge build_receipt_exit
        mov byte ptr [edi], 0
        
    build_receipt_exit:
        ; Restore all registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        
        ret
            
    BuildReceiptContent ENDP




    end start_minimart

    ;TODO: CLS every new item - Done
    ;-> put Stocks on items - Done
    ;->  add item - Done
    ;-> Summary - Done

    ;TODO: Feature improvements:
    ;-> Persistence - Done
    ;->  create a file for each receipt - WIP

    ;Things that I've found:
    ;-> stock is instantly decreased when trying to add a new item
    ;-> 
