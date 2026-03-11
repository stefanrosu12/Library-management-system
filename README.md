# 📚 Library Management System

A relational database system for managing library books, authors, members, and loan transactions — built with **Oracle SQL** and **PL/SQL**.

---

## 📐 Schema Overview

```
Persoana ──────────────────────────────────────────┐
  │  (people: members & authors)                    │
  │                                                 │
  ├──< Autor >── Carte                              │
  │    (many-to-many)   │                           │
  │                     │                           │
  └──< Imprumut >───────┘                           │
       (loan records)                               │
           │                                        │
           └──< Exceptii (anomalous loans) >────────┘
```

### Tables

| Table | Primary Key | Description |
|-------|-------------|-------------|
| `Persoana` | `id_pers` | People — both library members and authors |
| `Carte` | `id_carte` | Book catalogue with metadata and stock count |
| `Imprumut` | `(id_carte, id_imp)` | Loan records with borrow date, return date, and duration |
| `Autor` | `(id_carte, id_aut)` | Many-to-many relationship between books and authors |
| `Exceptii` | `(id_carte, id_imp)` | Anomalous loans flagged by reading rate |

---

## ⚙️ Constraints & Business Rules

- **Loan duration** (`nr_zile`) must be `> 0`
- **Phone/address consistency**: persons with a `+40` Romanian prefix must have an `RO` address
- **Author requirement**: a book cannot be borrowed unless it has at least one registered author (enforced via trigger)
- **Overdue detection**: a loan is overdue when `datar IS NULL` and `SYSDATE > datai + nr_zile`
- **Reading rate anomaly**: loans where `nr_pagini / days_elapsed > 50 pages/day` are flagged as exceptions

---

## 🗂️ Features

### Queries
- Case-insensitive genre filtering with `UPPER/LIKE`, ordered by genre and page count
- Overdue loan detection with days-of-delay calculation
- Co-author detection: finds author pairs writing in the same genre who have never co-authored a book
- Aggregate loan statistics (min/avg/max duration) grouped by genre
- Most-authored book using `HAVING COUNT = MAX(COUNT)` subquery

### Stored Procedure — `introduce_exceptii`
Refreshes the `Exceptii` table by re-evaluating all loans:
- **Returned loans**: flagged if reading pace exceeded 50 pages/day
- **Active loans**: rate computed against today's date

Commits on success, rolls back with an error message on failure.

### Trigger — `trg_verifica_autor_carte`
`BEFORE INSERT OR UPDATE` on `Imprumut` — raises `ORA-20001` if the book being borrowed has no authors registered in the `Autor` table.

### View — `Carti_Beletristica`
Denormalized view of all `BELETRISTICA` books with their author's personal details.  
Kept writable via an `INSTEAD OF INSERT` trigger that:
1. Inserts the book into `Carte` if it doesn't exist
2. Inserts the person into `Persoana` if not already registered
3. Creates the `Autor` relationship if it doesn't already exist

---

## 🛠️ Tech Stack

- **Oracle Database** (SQL*Plus / SQL Developer)
- **Oracle SQL** — ANSI join syntax, subqueries, `GROUP BY`, `HAVING`, `EXISTS`
- **PL/SQL** — stored procedures, row-level triggers, `INSTEAD OF` triggers
- **Oracle-specific**: `EMPTY_CLOB()`, `TRUNC(SYSDATE)`, `NVL()`, `RAISE_APPLICATION_ERROR`, `CLOB` columns

---

## 🚀 Getting Started

1. Run the table creation scripts in order: `Persoana` → `Carte` → `Imprumut` → `Autor` → `Exceptii`
2. Apply the `ALTER TABLE` modifications and constraints
3. Insert sample data
4. Create the procedure, triggers, and view
5. Execute the procedure to populate `Exceptii`:

```sql
EXEC introduce_exceptii;
```
