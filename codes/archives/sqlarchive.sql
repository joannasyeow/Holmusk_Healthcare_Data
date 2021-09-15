
with tot_bill as (
/* there are multiple bills for each patient's admission. 
this is to sum up the total bill and count number of bills for each admission*/

select id.patient_id, id.date_of_admission
,round(sum(amount),2) tot_bill -- total bill
,count(amount) no_bill -- number of bills
,row_number () over ( partition by patient_id order by date_of_admission ) enc_no -- encounter number per patient
from bill_id id
	left join bill_amount amt on id.bill_id = amt.bill_id
group by id.patient_id, id.date_of_admission

)

,readm as (
select t1.patient_id, t1.date_of_admission -- t2.date_of_admission "t2_date"
,case when DATE_PART('day', t1.date_of_admission::timestamp - t2.date_of_admission::timestamp) < 30 then 1 else 0 end readm30day -- readmission encounter within 30 days

from tot_bill t1
	left join tot_bill t2 on t1.patient_id = t2.patient_id and t1.enc_no = t2.enc_no + 1
)

,allcol as (select *

/* create new variables */
,DATE_PART('year', bill.date_of_admission::date) - DATE_PART('year', date_of_birth::date) age_at_adm -- age at admission
,DATE_PART('day', date_of_discharge::timestamp - bill.date_of_admission::timestamp) LOS -- length of stay

/* clean up */
,case when medical_history_3 = 'Yes' then '1' when medical_history_3 = 'No' then '0' else medical_history_3 end medical_history_3_c -- assumption: yes=1, no=0
,case when gender in ('Female','f') then '1' when gender in ('Male','m') then '0' else gender end gender_c -- standardise female=1, male=0
,case when gender in ('Female','f') then 'Female' when gender in ('Male','m') then 'Male' else gender end gender_str -- standardise
,case when resident_status in ('Singaporean','Singapore citizen') then '0' when resident_status = 'PR' then '1' when resident_status = 'Foreigner' then '2' else resident_status end resident_status_c -- standardise singporean=0 pr=1 foreigner=2
,case when resident_status in ('Singaporean','Singapore citizen') then 'Singaporean' when resident_status = 'PR' then 'PR' when resident_status = 'Foreigner' then 'Foreigner' else resident_status end resident_status_str -- standardise
,case when race in ('Indian','India') then '1' when race in ('Chinese','chinese') then '2' when race in ('Malay') then '3' when race in ('Others') then '4' else race end race_c -- standardise
,case when race in ('Indian','India') then 'Indian' when race in ('Chinese','chinese') then 'Chinese' else race end race_str -- standardise


/* impute null values */
,case when medical_history_2 is null then '0.0' else medical_history_2 end medical_history_2_c -- impute null as 0
,case when medical_history_5 is null then '0.0' else medical_history_5 end medical_history_5_c -- impute null as 0

from tot_bill bill

	/* join clinical_data at admission level and demographics at patient level*/
	left join clinical_data data on bill.patient_id = data.id and bill.date_of_admission = data.date_of_admission
	left join demographics demo on bill.patient_id = demo.patient_id
	left join readm on bill.patient_id = readm.patient_id and bill.date_of_admission = readm.date_of_admission
)

select 

patient_id, date_of_admission, 
gender_c, gender_str,resident_status_c,resident_status_str,race_c,race_str,age_at_adm,los
medical_history_1, medical_history_2_c,medical_history_3_c,
medical_history_4,medical_history_5_c,medical_history_6,medical_history_7,
preop_medication_1,preop_medication_2,preop_medication_3,preop_medication_4,preop_medication_5,preop_medication_6,
symptom_1,symptom_2,symptom_3,symptom_4,symptom_5,
lab_result_1,lab_result_2,lab_result_3,weight,height,
tot_bill, no_bill

from allcol
