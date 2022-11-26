SELECT 'Hello world!';

/* Запити з одної таблиці */

-- Вивести всіх пацієнтів
SELECT * FROM patients;

-- Вивести кількість пацієнтів
SELECT count(*) FROM patients;

-- Вивести імʼя, прізвище, висоту пацієнтів, відсотрувавши їх за зростанням зросту
SELECT first_name, last_name, height FROM patients
order by height asc;

-- Вивести імʼя, прізвище, вагу пацієнтів, відсотрувавши їх за спаданням ваги
SELECT first_name, last_name, weight FROM patients
order by weight desc;

-- Які різні алергії є в наборі даних
SELECT DISTINCT allergies FROM patients;


/* Aliasing - переназивання */
SELECT 
	first_name as patient_first_name, 
	last_name as patient_last_name
FROM patients;

/* */
/*  Фільтрація */
-- Вивести ім'я та прізвище пацієнтів, які не мають алергії.
SELECT first_name, last_name
FROM patients
WHERE allergies is NULL;

-- Вивести відсоток пацієнтів без алергії до всіх пацієнтів в базі.
SELECT 
	round(
      SUM(
        case when allergies is NULL then 1 else 0 end
      ) * 1.0 / count(1) * 100, 2) percentage_no_allergy
FROM patients

-- Показати ім’я, прізвище та стать пацієнтів, які мають стать «M»
SELECT first_name, last_name, gender
FROM patients
WHERE gender = 'M';

-- Показати ім’я та прізвище пацієнтів із вагою від 100 до 120 (включно)
SELECT first_name, last_name
FROM patients
WHERE weight between 100 and 120;

/* Робота з рядками */
-- Показати імена пацієнтів, які починаються з літери "C"
SELECT first_name
FROM patients
WHERE first_name like 'C%';

-- Показати імена пацієнтів, які починаються з літери "C" і закінчуються на "a"
SELECT first_name
FROM patients
WHERE first_name like 'C%a' ;

-- Сконкатенувати імена та прізвища пацієнтів
SELECT first_name || '_' || last_name
FROM patients

-- Вивести довжину рядка
SELECT LENGTH('text');

/* 

Більше про роботу з рядками 
- в SQLLite:https://www.sqlitetutorial.net/sqlite-string-functions/
- в MySQL: https://dev.mysql.com/doc/refman/8.0/en/string-functions.html 
*/


/* Робота з датами */
-- Показати унікальні роки народження пацієнтів і впорядкувати їх за зростанням.

SELECT
  DISTINCT YEAR(birth_date) AS birth_year
FROM patients
ORDER BY birth_year;

-- або

SELECT year(birth_date)
FROM patients
GROUP BY year(birth_date)

-- В який місяць народилась більшість пацієнтів? Вивести місяць та кількість пацієнтів
SELECT month(birth_date), count(1) as count_people
FROM patients
group by month(birth_date)
order by count_people DESC
LIMIT 1;


--JOINs

-- Вивести вcю інформацію про діагнози пацієнта з patient_id рівний 4529
select *  
from patients p join admissions a ON a.patient_id = p.patient_id
where p.patient_id=4529

-- Показати patient_id, first_name, last_name із діагнозом "Dementia".

SELECT
  p.patient_id,
  first_name,
  last_name
FROM patients p
  JOIN admissions a ON a.patient_id = p.patient_id
WHERE diagnosis = 'Dementia';

-- Скільки в базі пацієнтів без діагнозів? Чи вони взагалі є?
SELECT
  count(p.patient_id)
FROM patients p left JOIN admissions a on a.patient_id = p.patient_id
where diagnosis is null 

-- Вивести пацієнтів за спаданням кількості діагнозів. У пацієнта може не бути діагнозів!
SELECT
  p.patient_id,
  sum(case when diagnosis is null then 0 else 1 end) as count_diagnosis
FROM patients p left JOIN admissions a on a.patient_id = p.patient_id
group by p.patient_id
order by count_diagnosis asc;



-- Порівняємо вагу вагітних і невагітних жінок
-- Варіант 1
SELECT
  AVG(case when diagnosis = 'Pregnancy' then weight end) as pregnant_weigth,
  AVG(case when diagnosis != 'Pregnancy' then weight end) as non_pregnant_weigth
FROM patients
  JOIN admissions ON admissions.patient_id = patients.patient_id;

-- Варіант 2
select
  is_pregnant,
  avg(weight)
from(
    SELECT
      weight,
      case when diagnosis = 'Pregnancy' then 1 else 0 end is_pregnant
    FROM patients
      JOIN admissions ON admissions.patient_id = patients.patient_id
  ) temp
group by is_pregnant;

-- Відобразити загальну кількість пацієнтів для кожної провінції. Порядок за спаданням.
SELECT
  province_name,
  COUNT(*) as patient_count
FROM patients pa
  join province_names pr on pr.province_id = pa.province_id
group by pr.province_id
order by patient_count desc;

-- Показати ідентифікатор пацієнта, діагноз з госпіталізації. Знайдіть пацієнтів, які госпіталізувалися кілька разів з одним і тим же діагнозом.
SELECT
  patient_id,
  diagnosis
FROM admissions
GROUP BY
  patient_id,
  diagnosis
HAVING COUNT(*) > 1;

-- Покажіть провінції, у яких більше пацієнтів, ідентифікованих як «M», ніж як «F». Має відображатися лише повна назва провінції
SELECT pr.province_name
FROM patients AS pa
  JOIN province_names AS pr ON pa.province_id = pr.province_id
GROUP BY pr.province_name
HAVING
  COUNT( CASE WHEN gender = 'M' THEN 1 END) > COUNT( CASE WHEN gender = 'F' THEN 1 END);

-- АБО

SELECT province_name
FROM patients p
  JOIN province_names r ON p.province_id = r.province_id
GROUP BY province_name
HAVING
  SUM(CASE WHEN gender = 'M' THEN 1 ELSE -1 END) > 0

-- АБО

SELECT province_name
FROM (
SELECT
  province_name,
  SUM(gender = 'M') AS n_male,
  SUM(gender = 'F') AS n_female
FROM patients pa
  JOIN province_names pr ON pa.province_id = pr.province_id
GROUP BY province_name
)
WHERE n_male > n_female

-- UNION

-- Покажіть ім'я, прізвище та роль кожної особи, яка є пацієнтом або лікарем.
-- Ролі: «Пацієнт» або «Лікар»

SELECT first_name, last_name, 'Patient' as role FROM patients
    union all
select first_name, last_name, 'Doctor' from doctors;