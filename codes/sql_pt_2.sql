with tot_bill as (
	
	/* total bill per patient per year */
	select 
	max(id.bill_id) id_ -- unique identifier
	,id.patient_id -- patient identifier
	,round(sum(amount),2) tot_bill_yr -- total bill
	,date_part('year',date_of_admission) year_

	from bill_id id
		left join bill_amount amt on id.bill_id = amt.bill_id
	group by id.patient_id, year_
	
)

,pt_clinical as (
	select id
	,date_part('year',date_of_admission) year_
	,round(cast(avg(weight)/(power((avg(height)/100),2))as numeric),2) avg_bmi -- (weight kg) / (height m)**2
	,max(medical_history_1) medical_history_1
	,case when max(medical_history_2) is null then 0 else cast(max(medical_history_2) as integer) end medical_history_2_c -- impute null as 0
	,case when max(medical_history_3) = 'Yes' then 1 when max(medical_history_3) = 'No' then 0 else cast(max(medical_history_3) as integer) end medical_history_3_c -- assumption: yes=1, no=0
	,max(medical_history_4)medical_history_4
	,case when max(medical_history_5) is null then 0 else cast(max(medical_history_5) as integer) end medical_history_5_c -- impute null as 0
	,max(medical_history_6) medical_history_6
	,max(medical_history_7) medical_history_7

	from clinical_data

	group by id, year_
)

select id_
,bill.patient_id
/*
,medical_history_1, medical_history_2_c,medical_history_3_c,medical_history_4,medical_history_5_c,medical_history_6,medical_history_7
,(medical_history_1+medical_history_2_c+medical_history_3_c+medical_history_4+medical_history_5_c+medical_history_6+medical_history_7) no_med_hist -- number of medical history
,cast(bill.year_ - DATE_PART('year', date_of_birth::date)as integer) age_at_yr -- age at year
,case when gender in ('Female','f') then 1 when gender in ('Male','m') then 0 else null end gender_c-- standardise female=1, male=0
,case when race in ('Indian','India') then 1 when race in ('Chinese','chinese') then 2 when race in ('Malay') then 3 when race in ('Others') then 4 else null end race_c -- standardise
,case when resident_status in ('Singaporean','Singapore citizen') then 0 when resident_status = 'PR' then 1 when resident_status = 'Foreigner' then 2 else null end resident_status_c -- standardise singporean=0 pr=1 foreigner=2

,tot_bill_yr
*/
from tot_bill bill 

	left join demographics demo on bill.patient_id = demo.patient_id
	left join pt_clinical clinical on bill.patient_id = clinical.id and bill.year_ = clinical.year_
