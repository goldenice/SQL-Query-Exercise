-- Licensed under the MIT license by Rick Lubbers, 2014.

DROP TABLE IF EXISTS new_studie; CREATE TABLE new_studie(
		code		VARCHAR(10)			PRIMARY KEY			NOT NULL,
		naam		VARCHAR(64)							NOT NULL,
		faccode		VARCHAR(10)
	);

DROP TABLE IF EXISTS new_faculteit; CREATE TABLE new_faculteit(
		code		VARCHAR(10)			PRIMARY KEY		NOT NULL,
		naam		VARCHAR(64)							NOT NULL
	);

DROP TABLE IF EXISTS new_vak; CREATE TABLE new_vak(
		code 			INT 			PRIMARY KEY 			NOT NULL,
		naam			VARCHAR(64)						NOT NULL,
		beschrijving		TEXT,
		studie			VARCHAR(10)						NOT NULL,
		ects			INT							NOT NULL,
		ismodule		BOOLEAN							NOT NULL
	);

DROP TABLE IF EXISTS new_vakeditie; CREATE TABLE new_vakeditie(
		jaar		INT								NOT NULL,
		semester	CHAR(1)								NOT NULL,
		vakcode		INT								NOT NULL,
		hoofddocent	INT,
		PRIMARY KEY(jaar, semester, vakcode)
	);

DROP TABLE IF EXISTS new_docent; CREATE TABLE new_docent(
		nr		INT				PRIMARY KEY			NOT NULL,
		naam		VARCHAR(255)							NOT NULL,
		indienst	DATE								NOT NULL,
		uitdienst 	DATE,
		faccode		VARCHAR(10)
	);
	
DROP TABLE IF EXISTS new_docent_vakeditie; CREATE TABLE new_docent_vakeditie(
		docentnr	INT								NOT NULL,
		jaar		INT								NOT NULL,
		semester	CHAR(1)								NOT NULL,
		vakcode		INT								NOT NULL,
		PRIMARY KEY(docentnr, jaar, semester, vakcode)
	);

DROP TABLE IF EXISTS new_studenten; CREATE TABLE new_studenten(
		nr	 	INT				PRIMARY KEY			NOT NULL,
		naam		VARCHAR(255)							NOT NULL
	);

DROP TABLE IF EXISTS new_studenten_studie; CREATE TABLE new_studenten_studie(
		studentnr	INT								NOT NULL,
		studiecode	VARCHAR(10)							NOT NULL,
		start_date	DATE								NOT NULL,
		stop_date	DATE,
		PRIMARY KEY(studentnr, studiecode)
	);

DROP TABLE IF EXISTS new_cijfers; CREATE TABLE new_cijfers(
		id		SERIAL		 		PRIMARY KEY			NOT NULL,
		studentnr	INT								NOT NULL,
		vakcode		INT								NOT NULL,
		cijfer		INT								NOT NULL,
		isdeelcijfer	BOOLEAN								NOT NULL
	);

DROP TABLE IF EXISTS new_sa; CREATE TABLE new_sa(
		studentnr	INT			NOT NULL,
		vakcode		INT			NOT NULL,
		PRIMARY KEY (studentnr, vakcode)
	);

-- Query voor studies overzetten
INSERT INTO new_studie (code, naam, faccode) SELECT DISTINCT studie, studie, 0  FROM onderwijs ORDER BY studie ASC;

-- Onderstaande data is handmatig bepaald, komt niet uit de oude database
INSERT INTO new_faculteit (code, naam) 
	VALUES 
		('EWI', 'Elektrotechniek, Wiskunde en Informatica'),
		('TNW', 'Technische Natuurwetenschappen'),
		('MB', 'Management en Bestuur'),
		('CTW', 'Construerende Technische Wetenschappen'),
		('GW', 'Gedragswetenschappen');

UPDATE new_studie SET naam = 'Technische Informatica', faccode = 'EWI' 					WHERE code = 'INF';
UPDATE new_studie SET naam = 'Business and IT', faccode = 'EWI'							WHERE code = 'BIT';
UPDATE new_studie SET naam = 'Biomedische Technologie', faccode = 'TNW'					WHERE code = 'BMT';
UPDATE new_studie SET naam = 'Bestuurskunde', faccode = 'MB' 							WHERE code = 'BSK'; 
UPDATE new_studie SET naam = 'Civiele Techniek', faccode = 'CTW' 						WHERE code = 'CIT'; 
UPDATE new_studie SET naam = 'Elektrotechniek', faccode = 'EWI'							WHERE code = 'EL'; 
UPDATE new_studie SET naam = 'Psychologie', faccode = 'GW'								WHERE code = 'PSY';
UPDATE new_studie SET naam = 'Technische Bedrijfskunde', faccode = 'MB'					WHERE code = 'TBK';
UPDATE new_studie SET naam = 'Telematics', faccode = 'EWI'								WHERE code = 'TEL';
UPDATE new_studie SET naam = 'Technische Wiskunde', faccode = 'EWI'						WHERE code = 'TW';
UPDATE new_studie SET naam = 'Wetenschap, Technologie en Maatschappij', faccode = 'EWI' WHERE code = 'WTM';

-- Query voor vakken opzetten
INSERT INTO new_vak (code, naam, beschrijving, studie, ects, ismodule) 
	SELECT o.vakcode, o.vaknaam, (SELECT v.beschrijving FROM vakbeschrijving AS v WHERE v.vakcode = o.vakcode), o.studie, 5, FALSE 
		FROM onderwijs AS o 
		GROUP BY o.vakcode, o.vaknaam, o.studie
		ORDER BY o.vakcode ASC;
INSERT INTO new_vakeditie (jaar, semester, vakcode) 
	SELECT CAST(SUBSTR(semester, 2, 4) AS INT), SUBSTR(semester, 1, 1), vakcode 
		FROM onderwijs 
		GROUP BY vakcode, semester 
		ORDER BY vakcode, semester ASC;

-- Query voor docenten overnemen
INSERT INTO new_docent (nr, naam, indienst, faccode) 
	SELECT DISTINCT ON (o.docentnr) o.docentnr, o.docent, NOW(), s.faccode
		FROM onderwijs AS o
		LEFT OUTER JOIN new_docent_vakeditie AS dve ON o.docentnr = dve.docentnr
		LEFT OUTER JOIN new_vak AS v ON dve.vakcode = v.code
		LEFT OUTER JOIN new_studie AS s ON v.studie = s.code
		ORDER BY o.docentnr ASC;

-- Query voor koppelen docenten aan vakken
INSERT INTO new_docent_vakeditie (docentnr, jaar, semester, vakcode) 
	SELECT docentnr, CAST(SUBSTR(semester, 2, 4) AS INT), SUBSTR(semester, 1, 1), vakcode 
		FROM onderwijs 
		GROUP BY vakcode, semester 
		ORDER BY docentnr, vakcode, semester ASC;

-- Query voor laden studenten
INSERT INTO new_studenten (nr, naam) 
	SELECT DISTINCT studentnr, student 
		FROM cijfers 
		ORDER BY studentnr ASC;

-- Query voor koppelen studenten aan studie
INSERT INTO new_studenten_studie (studentnr, studiecode, start_date) 
	SELECT DISTINCT student.nr, studie.code, NOW() 
		FROM new_studenten AS student, new_studie AS studie, new_vak AS vak, cijfers AS cijfers 
		WHERE student.nr = cijfers.studentnr AND cijfers.vakcode = vak.code AND vak.studie = studie.code 
		ORDER BY student.nr ASC;

-- Query voor koppelen studenten, vakken en cijfers
INSERT INTO new_cijfers (studentnr, vakcode, cijfer, isdeelcijfer) 
	SELECT studentnr, vakcode, cijfer, FALSE FROM cijfers;



