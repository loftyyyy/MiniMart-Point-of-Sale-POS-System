
# **MiniMart POS System (Assembly)**

A simple Point of Sale (POS) system written in **x86 Assembly (MASM32)** for our **Computer Architecture and Organization** course.

---

## **Description**

MiniMart simulates a basic checkout system where the user selects items, enters quantities, and the program computes subtotals, tax, and total amount.
All item codes, names, and prices are stored in memory and accessed through indexing.

---

## **Features**

* Item menu display
* Input item code and quantity
* Subtotal and total computation
* Tax calculation
* Receipt summary
* Loop for multiple items per transaction

---

## **Program Flow**

```
START
→ Display item list
→ Enter item code & quantity
→ Compute subtotal
→ Add to running total
→ Add another item? (Y/N)
→ Compute tax & final total
→ Display receipt
END
```

---

## **Development Environment**

* **Assembler:** MASM32
* **OS:** Windows 11

---

## **How to Build & Run (MASM32)**

1. Open **MASM32 Command Prompt**
2. Assemble and link:

```
ml /c /coff MiniMart.asm
Link /SUBSYSTEM:CONSOLE MiniMart.obj
```

3. Run:

```
MiniMart.exe
```

---

## **Course**

**Computer Architecture and Organization**

