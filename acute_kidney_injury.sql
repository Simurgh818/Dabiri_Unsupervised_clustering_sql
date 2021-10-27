SELECT *
FROM patients;

-- 1: group patients into age groups: neonatals, adults, older adults(>89)
WITH first_admission_time AS
(
	SELECT 
		p.subject_id, p.dob
		, MIN(a.admittime) AS first_admittime
		, MIN( ROUND((cast (admittime as date) - cast(dob as date)) / 365.242, 2))
			AS first_admit_age
	FROM patients p
	INNER JOIN admissions a
	ON p.subject_id = a.subject_id
	GROUP BY p.subject_id, p.dob
	ORDER BY p.subject_id
)
, age as
(
	SELECT 
		subject_id, dob
		, first_admittime, first_admit_age
		, CASE
			-- All ages > 89 where replaced with >89
			WHEN first_admit_age > 89
				THEN '>89'
			WHEN first_admit_age >= 14
				THEN 'adult'
			WHEN first_admit_age <= 1
				THEN 'neonate'
			when first_admit_age < 14 and first_admit_age > 1
				THEN 'child'
			END AS age_group
	FROM first_admission_time
)
select g.subject_id, g.age_group, c.icd9_code, l.itemid, d.label, l.valuenum, o.itemid, di.label, o.value
from age g
	INNER JOIN diagnoses_icd c
	ON g.subject_id = c.subject_id

-- 3: find serum creatinine and urine output info about them
	INNER JOIN labevents AS l
	ON c.subject_id = l.subject_id
	
	INNER JOIN d_labitems as d
	ON l.itemid = d.itemid 
	
	INNER JOIN outputevents as o
	ON c.subject_id = o.subject_id
	
	INNER JOIN d_items as di
	ON o.itemid = di.itemid
-- 2: Select the adult and older adult group, diagnosed for acute kidney injury icd9_code = '5849'
	WHERE (age_group='adult' or age_group='>89') and icd9_code = '5849' and 
	d.label ='Creatinine, Serum' and di.itemid = '40055'
-- 	 'Creatine Kinase (CK)' or d.label = 'Creatine Kinase, MB Isoenzyme' or	d.fluid = 'Urine'
	GROUP BY g.subject_id, g.age_group, c.icd9_code, l.itemid, d.label, l.valuenum, o.itemid, di.label, o.value
	-- d.label
	ORDER BY g.subject_id
	
-- 4: unsupervised clustering


-- 5: plot using rSNE and UMAP
