

# **JJRC Minimart POS System (Assembly)**

A comprehensive Point of Sale (POS) system written in **x86 Assembly (MASM32)** for our **Computer Architecture and Organization** course.


---

## **Description**

JJRC Minimart is a full-featured retail management system that simulates a real-world minimart checkout experience. The system includes inventory management, stock tracking, sales recording, and comprehensive reporting. All data is persisted to files for continuity between sessions.

---

## **Features**

### **Main Menu Options:**
1. **View Inventory** - Display all items with their prices and stock levels
2. **Add New Item** - Add new products to the inventory (up to 50 items)
3. **Update Item Stock** - Modify stock quantities for existing items
4. **POS (Point of Sale)** - Process customer transactions
5. **View Sales Summary** - Display sales statistics and reports
6. **Exit** - Close the program

### **POS Features:**
* Dynamic item menu display with real-time stock levels
* Input validation for item selection and quantities
* Stock checking (prevents overselling)
* Multiple items per transaction
* Subtotal and total computation
* VAT calculation (12%)
* Detailed receipt with date and time
* Payment processing with change calculation
* Automatic stock deduction after sale

### **Inventory Management:**
* Dynamic item database (supports up to 50 items)
* Item structure: Name (32 bytes), Price (4 bytes), Stock (4 bytes)
* File persistence (`inventory.dat`)
* Real-time stock updates

### **Sales Tracking:**
* Records all transactions with item details
* Tracks quantity sold and revenue per item
* Stores date and time for each sale
* Supports up to 1000 sales records
* File persistence (`summary.dat`)

### **Sales Summary:**
* Total number of transactions
* Total revenue calculation
* Most sold item identification
* Sales breakdown by item (quantity and revenue)
* Low stock warnings (items with stock < 10)

---

## **Program Flow**

```
START
→ Load inventory from file
→ Load sales data from file
→ Display main menu
  ├─→ 1. View Inventory → Display all items
  ├─→ 2. Add New Item → Input name, price, stock → Save to file
  ├─→ 3. Update Item Stock → Select item → Update stock → Save to file
  ├─→ 4. POS
  │    ├─→ Display item menu with stock
  │    ├─→ Select item & enter quantity
  │    ├─→ Validate stock availability
  │    ├─→ Add another item? (Y/N)
  │    ├─→ Compute tax (12%) & final total
  │    ├─→ Process payment & calculate change
  │    ├─→ Print receipt with date/time
  │    ├─→ Record sale & update stock
  │    └─→ Save data to files
  ├─→ 5. View Sales Summary → Display statistics
  └─→ 6. Exit → Save all data & terminate
END
```

---

## **Data Structures**

### **Item Structure:**
- **Name:** 32 bytes (null-terminated string)
- **Price:** 4 bytes (DWORD)
- **Stock:** 4 bytes (DWORD)
- **Total:** 40 bytes per item

### **Sale Record Structure:**
- **ItemID:** 4 bytes (DWORD)
- **Quantity:** 4 bytes (DWORD)
- **TotalPrice:** 4 bytes (DWORD)
- **Date:** 4 bytes (YYYYMMDD format)
- **Time:** 4 bytes (HHMM format)
- **Total:** 20 bytes per sale record

---

## **File Persistence**

The system uses two data files:
- **`inventory.dat`** - Stores item count and all inventory data
- **`summary.dat`** - Stores sales count and all sales records

Both files are automatically created on first run and loaded on subsequent runs.

---

## **Development Environment**

* **Assembler:** MASM32
* **OS:** Windows 11
* **Libraries:** MASM32 Runtime Library (masm32rt.inc)

---

## **How to Build & Run (MASM32)**

1. Open **MASM32 Command Prompt**
2. Navigate to project directory
3. Assemble and link:

```
ml /c /coff POS.asm
Link /SUBSYSTEM:CONSOLE POS.obj
```

4. Run:

```
POS.exe
```


---

## **Course**

**Computer Architecture and Organization**

