CREATE TABLE Persoana (
    id_pers NUMBER PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL,
    telefon VARCHAR2(15),
    adresa VARCHAR2(200)
);

CREATE TABLE Carte (
    id_carte NUMBER PRIMARY KEY,
    titlu VARCHAR2(200) NOT NULL,
    nr_pagini NUMBER,
    nr_exemplare NUMBER,
    gen VARCHAR2(50),
    rezumat VARCHAR2(4000)
);

CREATE TABLE Imprumut (
    id_carte NUMBER,
    id_imp NUMBER,
    datai DATE NOT NULL,
    datar DATE,
    nr_zile NUMBER,
    PRIMARY KEY (id_carte, id_imp),
    FOREIGN KEY (id_carte) REFERENCES Carte(id_carte),
    FOREIGN KEY (id_imp) REFERENCES Persoana(id_pers)
);

CREATE TABLE Autor (
    id_carte NUMBER,
    id_aut NUMBER,
    PRIMARY KEY (id_carte, id_aut),
    FOREIGN KEY (id_carte) REFERENCES Carte(id_carte),
    FOREIGN KEY (id_aut) REFERENCES Persoana(id_pers)
);

ALTER TABLE Carte DROP COLUMN rezumat;
ALTER TABLE Carte ADD rezumat CLOB;
ALTER TABLE Imprumut ADD CONSTRAINT chk_nr_zile_pozitiv CHECK (nr_zile > 0);

ALTER TABLE Persoana ADD CONSTRAINT chk_telefon_adresa 
CHECK (
    telefon NOT LIKE '+40%' OR 
    adresa LIKE 'RO%'
);

INSERT INTO Persoana (id_pers, nume, telefon, adresa) VALUES (1, 'Ion Popescu', '+40712-345678', 'RO-Bucuresti');
INSERT INTO Persoana (id_pers, nume, telefon, adresa) VALUES (2, 'Ana Ionescu', '+40264-567123', 'RO-Cluj');
INSERT INTO Persoana (id_pers, nume, telefon, adresa) VALUES (3, 'George Vasilescu', '0364-999333', 'Cluj-Napoca');
INSERT INTO Persoana (id_pers, nume, telefon, adresa) VALUES (4, 'Maria Enescu', '+40788-123456', 'RO-Timisoara');
INSERT INTO Persoana (id_pers, nume, telefon, adresa) VALUES (5, 'Alex Radu', NULL, 'Oradea');

INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen, rezumat) 
VALUES (1, 'India', 300, 5, 'BELETRISTICA', EMPTY_CLOB());
INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen, rezumat) 
VALUES (2, 'Python Essentials', 450, 5, 'EDUCATIONAL', EMPTY_CLOB());
INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen, rezumat) 
VALUES (3, 'Povesti de seara', 120, 5, 'Beletristica', EMPTY_CLOB());
INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen, rezumat) 
VALUES (4, 'Mic tratat de magie', 210, 5, 'FANTASY', EMPTY_CLOB());
INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen, rezumat) 
VALUES (5, 'Be Smart', 350, 5, 'SELF-HELP', EMPTY_CLOB());

INSERT INTO Autor (id_carte, id_aut) VALUES (1, 1); 
INSERT INTO Autor (id_carte, id_aut) VALUES (2, 2); 
INSERT INTO Autor (id_carte, id_aut) VALUES (3, 3); 
INSERT INTO Autor (id_carte, id_aut) VALUES (4, 4); 

INSERT INTO Imprumut (id_carte, id_imp, datai, datar, nr_zile) 
VALUES (1, 2, TRUNC(SYSDATE) - 50, TRUNC(SYSDATE) - 10, 10); 
INSERT INTO Imprumut (id_carte, id_imp, datai, datar, nr_zile) 
VALUES (2, 3, TRUNC(SYSDATE) - 90, NULL, 45); 
INSERT INTO Imprumut (id_carte, id_imp, datai, datar, nr_zile) 
VALUES (3, 1, TRUNC(SYSDATE) - 100, TRUNC(SYSDATE) - 10, 30); 
INSERT INTO Imprumut (id_carte, id_imp, datai, datar, nr_zile) 
VALUES (4, 5, TRUNC(SYSDATE) - 10, NULL, 5); 
INSERT INTO Imprumut (id_carte, id_imp, datai, datar, nr_zile) 
VALUES (1, 4, TRUNC(SYSDATE) - 40, TRUNC(SYSDATE) - 5, 15); 

SELECT *
FROM Carte
WHERE UPPER(gen) LIKE '%BE%'
ORDER BY gen ASC, nr_pagini DESC;

SELECT i.*, 
       TRUNC(SYSDATE) - (i.datai + i.nr_zile) AS zile_intarziere
FROM Imprumut i
WHERE i.datar IS NULL 
  AND TRUNC(SYSDATE) > (i.datai + i.nr_zile)
ORDER BY zile_intarziere DESC;

SELECT p.nume, p.telefon, 
       (i.datar - (i.datai + i.nr_zile)) AS zile_intarziere
FROM Persoana p
JOIN Imprumut i ON p.id_pers = i.id_imp
WHERE i.datar IS NOT NULL 
  AND (i.datar - (i.datai + i.nr_zile)) > 30  
ORDER BY zile_intarziere DESC;

SELECT DISTINCT a1.id_aut AS id_aut1, a2.id_aut AS id_aut2
FROM Autor a1
JOIN Carte c1 ON a1.id_carte = c1.id_carte
JOIN Carte c2 ON c1.gen = c2.gen AND c1.id_carte <> c2.id_carte
JOIN Autor a2 ON c2.id_carte = a2.id_carte
WHERE a1.id_aut < a2.id_aut
  AND NOT EXISTS (
      SELECT 1
      FROM Autor a3
      JOIN Autor a4 ON a3.id_carte = a4.id_carte
      WHERE a3.id_aut = a1.id_aut 
        AND a4.id_aut = a2.id_aut
  );

SELECT c.*
FROM Carte c
WHERE (c.nr_exemplare, c.gen) IN (
    SELECT c_india.nr_exemplare, c_india.gen
    FROM Carte c_india
    WHERE c_india.titlu = 'India'
)
AND c.titlu <> 'India'; 

SELECT c.*
FROM Carte c
WHERE EXISTS (
    SELECT 1
    FROM Imprumut i
    WHERE i.id_carte = c.id_carte
    AND i.nr_zile <= ALL (
        SELECT i2.nr_zile
        FROM Imprumut i2
    )
);

SELECT c.titlu
FROM Carte c
JOIN Autor a ON c.id_carte = a.id_carte
GROUP BY c.id_carte, c.titlu
HAVING COUNT(a.id_aut) = (
    SELECT MAX(autor_count)
    FROM (
        SELECT COUNT(id_aut) AS autor_count
        FROM Autor
        GROUP BY id_carte
    )
);

SELECT c.gen,
       MIN(i.nr_zile) AS min_zile,
       AVG(i.nr_zile) AS avg_zile,
       MAX(i.nr_zile) AS max_zile
FROM Carte c
JOIN Imprumut i ON c.id_carte = i.id_carte
GROUP BY c.gen
ORDER BY c.gen;

INSERT INTO Persoana (id_pers, nume, telefon, adresa)
VALUES (
    (SELECT NVL(MAX(id_pers), 0) + 1 FROM Persoana), 
    'Mircea Cărtărescu',
    '+4021-0434567',
    'RO...' 
);

INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen)
VALUES (
    (SELECT NVL(MAX(id_carte), 0) + 1 FROM Carte), 
    'Visul',
    294,
    100,
    'SF'
);

INSERT INTO Autor (id_carte, id_aut)
VALUES (
    (SELECT id_carte FROM Carte WHERE titlu = 'Visul'),
    (SELECT id_pers FROM Persoana WHERE nume = 'Mircea Cărtărescu')
);

DELETE FROM Carte
WHERE id_carte NOT IN (
    SELECT id_carte
    FROM Autor
);

UPDATE Imprumut
SET nr_zile = 
    CASE
        WHEN (TRUNC(SYSDATE) - datai) > 90 THEN 90
        ELSE (TRUNC(SYSDATE) - datai)
    END
WHERE datar IS NULL
  AND nr_zile < (TRUNC(SYSDATE) - datai)

CREATE TABLE Exceptii (
    id_carte NUMBER,
    id_imp NUMBER,
    datai DATE NOT NULL,
    datar DATE,
    nr_zile NUMBER,
    rata_citire NUMBER, 
    PRIMARY KEY (id_carte, id_imp),
    FOREIGN KEY (id_carte) REFERENCES Carte(id_carte),
    FOREIGN KEY (id_imp) REFERENCES Persoana(id_pers)
);

CREATE OR REPLACE PROCEDURE introduce_exceptii AS
BEGIN
    DELETE FROM Exceptii;
    
    INSERT INTO Exceptii (id_carte, id_imp, datai, datar, nr_zile, rata_citire)
    SELECT i.id_carte, i.id_imp, i.datai, i.datar, i.nr_zile, 
           c.nr_pagini / (i.datar - i.datai) AS rata_citire
    FROM Imprumut i
    JOIN Carte c ON i.id_carte = c.id_carte
    WHERE i.datar IS NOT NULL  
    AND c.nr_pagini / (i.datar - i.datai) > 50; 
    
    INSERT INTO Exceptii (id_carte, id_imp, datai, datar, nr_zile, rata_citire)
    SELECT i.id_carte, i.id_imp, i.datai, i.datar, i.nr_zile,
           c.nr_pagini / (TRUNC(SYSDATE) - i.datai) AS rata_citire
    FROM Imprumut i
    JOIN Carte c ON i.id_carte = c.id_carte
    WHERE i.datar IS NULL;  
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Procedura a fost executată cu succes. Au fost introduse ' || SQL%ROWCOUNT || ' exceptii noi pentru cartile nerestituite.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('A aparut o eroare: ' || SQLERRM);
END introduce_exceptii;
/

CREATE OR REPLACE TRIGGER trg_verifica_autor_carte
BEFORE INSERT OR UPDATE ON Imprumut
FOR EACH ROW
DECLARE
    v_autor_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_autor_count
    FROM Autor
    WHERE id_carte = :NEW.id_carte;
    
    IF v_autor_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nu se poate imprumuta cartea cu ID ' || :NEW.id_carte || ' deoarece nu are autori asociati.');
    END IF;
END;
/

CREATE VIEW Carti_Beletristica AS
SELECT id_carte, titlu, nr_pagini, nr_exemplare, id_pers, nume AS autor, telefon, adresa
FROM Carte NATURAL JOIN Autor JOIN Persoana ON id_pers = id_aut
WHERE gen = 'BELETRISTICA';

CREATE OR REPLACE TRIGGER trg_insert_carti_beletristica
INSTEAD OF INSERT ON Carti_Beletristica
FOR EACH ROW
DECLARE
    v_carte_id NUMBER;
    v_pers_id NUMBER;
    v_exists_carte NUMBER := 0;
    v_exists_pers NUMBER := 0;
BEGIN
    BEGIN
        SELECT 1 INTO v_exists_carte 
        FROM Carte 
        WHERE id_carte = :NEW.id_carte;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_exists_carte := 0;
    END;
    
    BEGIN
        SELECT 1 INTO v_exists_pers 
        FROM Persoana 
        WHERE id_pers = :NEW.id_pers;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_exists_pers := 0;
    END;
    
    IF v_exists_carte = 0 THEN
        INSERT INTO Carte (id_carte, titlu, nr_pagini, nr_exemplare, gen)
        VALUES (:NEW.id_carte, :NEW.titlu, :NEW.nr_pagini, :NEW.nr_exemplare, 'BELETRISTICA')
        RETURNING id_carte INTO v_carte_id;
    ELSE
        v_carte_id := :NEW.id_carte;
    END IF;
    
    IF v_exists_pers = 0 THEN
        INSERT INTO Persoana (id_pers, nume, telefon, adresa)
        VALUES (:NEW.id_pers, :NEW.autor, :NEW.telefon, :NEW.adresa)
        RETURNING id_pers INTO v_pers_id;
    ELSE
        v_pers_id := :NEW.id_pers;
    END IF;
    
    BEGIN
        DECLARE
            v_relation_exists NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_relation_exists
            FROM Autor
            WHERE id_carte = v_carte_id AND id_aut = v_pers_id;
            
            IF v_relation_exists = 0 THEN
                INSERT INTO Autor (id_carte, id_aut)
                VALUES (v_carte_id, v_pers_id);
            END IF;
        END;
    END;
    
    DBMS_OUTPUT.PUT_LINE('Cartea beletristica "' || :NEW.titlu || '" a fost adaugata cu succes ' || 'cu autorul ' || :NEW.autor);
END;
/