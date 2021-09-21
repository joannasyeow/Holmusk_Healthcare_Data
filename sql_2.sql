with tot_bill as (
	
	/* total bill per patient per year */
	select 
	max(id.bill_id) id_ -- unique identifier
	,id.patient_id -- patient identifier
	,round(sum(amount),2) tot_bill -- total bill
	,id.date_of_admission

	from bill_id id
		left join bill_amount amt on id.bill_id = amt.bill_id
	group by id.patient_id, id.date_of_admission
	
)

,pt_clinical as (
	select id, date_of_admission
	,round(cast(weight/(power((height/100),2))as numeric),2) bmi -- (weight kg) / (height m)**2
	,medical_history_1
	,case when medical_history_2 is null then 0 else cast(medical_history_2 as integer) end medical_history_2_c -- impute null as 0
	,case when medical_history_3 = 'Yes' then 1 when medical_history_3 = 'No' then 0 else cast(medical_history_3 as integer) end medical_history_3_c -- assumption: yes=1, no=0
	,medical_history_4
	,case when medical_history_5 is null then 0 else cast(medical_history_5 as integer) end medical_history_5_c -- impute null as 0
	,medical_history_6
	,medical_history_7
	,symptom_1,symptom_2,symptom_3,symptom_4,symptom_5

	from clinical_data

)


select id_
,bill.patient_id
,medical_history_1, medical_history_2_c,medical_history_3_c,medical_history_4,medical_history_5_c,medical_history_6,medical_history_7
,(medical_history_1+medical_history_2_c+medical_history_3_c+medical_history_4+medical_history_5_c+medical_history_6+medical_history_7) no_med_hist -- number of medical history

,cast(DATE_PART('year', bill.date_of_admission::date) - DATE_PART('year', date_of_birth::date)as integer) age_at_adm -- age at admission

,case when cast(DATE_PART('year', bill.date_of_admission::date) - DATE_PART('year', date_of_birth::date)as integer) < 56 then 0 else 1 end age_grp
,case when gender in ('Female','f') then 1 when gender in ('Male','m') then 0 else null end gender_c-- standardise female=1, male=0
,case when race in ('Indian','India') then 1 when race in ('Chinese','chinese') then 2 when race in ('Malay') then 3 when race in ('Others') then 4 else null end race_c -- standardise
,case when resident_status in ('Singaporean','Singapore citizen') then 0 when resident_status = 'PR' then 1 when resident_status = 'Foreigner' then 2 else null end resident_status_c -- standardise singporean=0 pr=1 foreigner=2
,bmi
,case when bmi > 27.5 then 4 when bmi > 23 then 3 when bmi > 18.5 then 2 else 1 end bmi_risk -- bmi risk from healthhub.sg 

,case when bmi > 27.5 then 1 else 0 end bmi_high
,case when race in ('Indian','India') then 1 else 0 end indian
,case when race in ('Chinese','chinese') then 1 else 0 end chinese
,case when race in ('Malay') then 1 else 0 end malay
,case when race in ('Others') then 1 else 0 end other

,case when resident_status in ('Singaporean','Singapore citizen') then 1 else 0 end sg
,case when resident_status = 'PR' then 1 else 0 end pr
,case when resident_status = 'Foreigner' then 1 else 0 end foreigner
,case when resident_status not in ('Singaporean','Singapore citizen') then 1 else 0 end not_sg

,symptom_1,symptom_2,symptom_3,symptom_4,symptom_5,(symptom_1+symptom_2+symptom_3+symptom_4+symptom_5) no_sym -- number of symptoms

,tot_bill

from tot_bill bill 

	left join demographics demo on bill.patient_id = demo.patient_id
	left join pt_clinical clinical on bill.patient_id = clinical.id and bill.date_of_admission = clinical.date_of_admission
