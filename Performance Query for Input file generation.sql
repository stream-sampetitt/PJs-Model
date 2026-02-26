;with perf AS
(
select  (case when dtb.loan_group_no = 5 then 'Solar' else 'HI' end) as Product_Type,
	(case when dtb.loan_group_no in (3) and l.open_date < cast('01-mar-2023' as date) then 'AMH Non Recourse' 
			when dtb.loan_group_no in (3,6) then 'AMH Recourse' 
    		when dtb.loan_group_no in (5)  then 'ENDVR-Solar' 
            when dtb.loan_group_no in (8)  then 'AMH Repurchase' 
    		when dtb.loan_group_no in (11)  then 'STRE-2024-1' 
			when dtb.loan_group_no in (12)  then 'STRE-2024-2' 
			when dtb.loan_group_no in (7)  then 'SPV1' 
            when dtb.loan_group_no in (2)  then 'Pilot' 
			when dtb.loan_group_no in (9)  then 'SPV2' 
			when dtb.loan_group_no in (15)  then 'STRE-2025-1' 
			when dtb.loan_group_no in (13)  then '26N' 
			when dtb.loan_group_no in (14)  then 'JPM' 
			when dtb.loan_group_no in (16)  then 'ARES' 
		else 'XXX' end) as Investor,
	(case 	when dtb.loan_group_no in (3,6,5,13,14,16) then 0 
    		when dtb.loan_group_no in (2,7,8,9,11,12,15)  then 1 
		else -1 end) as BS_FLAG,   
ld.userdef43 AS [Territory], 
ld.userdef56 AS [Participating_Investor], 
ld.userdef58 AS [Participating_Date], 
cif.state  as  Mailing_State,   
l.starting_interest_rate AS [interest_rate],
lsetup.term,
year(l.open_date) as Vintage_year,
DATEADD(DAY, 1, EOMONTH((l.open_date), -1)) as Vintage_BOM,
CONVERT(NVARCHAR(6), l.open_date, 112) AS [Vintage_Month],
concat(year(l.open_date), 'Q', datepart(quarter, l.open_date) ) AS [Vintage_Quarter],
DATEDIFF(MONTH, l.open_date, EOMONTH(dtb.trial_balance_date)) AS [MOB],
CONVERT(NVARCHAR(6), dtb.trial_balance_date, 112) AS [TB_Month],
dtb.acctrefno, l.loan_number, dtb.trial_balance_date, dtb.loan_group_no, dtb.loan_amount, l.open_date, dtb.gl_principal_balance, dtb.gl_interest_balance, dtb.gl_fees_balance,
dtb.gl_late_charges_balance, dtb.gl_days_past_due, dtb.status_code_no,   
la.interest_accrual, la.corrected_indicator,
ISNULL(trans.Net_Principal_advance, 0.00) AS [Net_Principal_Advance],
	   ISNULL(trans.NET_Merchant_Discount, 0.00) AS [NET_Merchant_Discount],
	   ISNULL(trans.NET_Investor_Premium, 0.00) AS [NET_Investor_Premium],
	   ISNULL(trans.NET_Investor_Discount, 0.00) AS [NET_Investor_Discount],
	   ISNULL(trans.NET_Interest_Billing_amount, 0.00) AS [NET_Interest_Billing_amount],
	   ISNULL(trans.NET_Principal_Interest_Billing_amount, 0.00) AS [NET_Principal_Interest_Billing_amount],
	   ISNULL(trans.NET_Late_Fee, 0.00) AS [NET_Late_Fee],
	   ISNULL(trans.Net_Principal_Payment, 0.00) AS [Net_Principal_Payment], 
	   ISNULL(trans.Net_Principal_Prepayment, 0.00) AS [Net_Principal_Prepayment], 
	   ISNULL(trans.Net_Interest_Payment, 0.00) AS [Net_Interest_Payment], 
	   ISNULL(trans.NET_Late_Fee_Payment, 0.00) AS [NET_Late_Fee_Payment],
	   ISNULL(-trans.NET_Overpayment_Refund, 0.00) AS [NET_Overpayment_Refund],
	   ISNULL(trans.NET_Interest_Reduction, 0.00) AS [NET_Interest_Reduction],

	   ISNULL(trans.Principal_Write_Off, 0.00) AS [Principal_Write_Off],
       ISNULL(trans.Interest_Write_Off, 0.00) AS [Interest_Write_Off],
       ISNULL(trans.Late_Fee_Write_Off, 0.00) AS [Late_Fee_Write_Off],
       ISNULL(trans.non_cash_principal_advanced, 0.00) AS [non_cash_principal_advanced],
       ISNULL(trans.Post_CO_PMT_Reversal, 0.00) AS [Post_CO_PMT_Reversal],

	   ISNULL(trans.Total_Charge_off_Balance, 0.00) AS [Total_Charge_off_Balance] ,
	   CASE WHEN ISNULL(trans.Total_Charge_off_Balance, 0.00) > 0.00 THEN
			dtbco.eff_principal_balance
	   ELSE 0.00 END AS [CO_Principal_Balance],
	   CASE WHEN lsco.effective_date IS NOT NULL AND dtb.trial_balance_date > lsco.effective_date THEN
			ISNULL(trans.Recovery_Amount,0.00)
	   ELSE 0.00 END AS [Recovery_Amount]  ,    
       ISNULL(trans.Third_Party_collections_fee, 0.00) AS [Third_Party_collections_fee],

       (case when dtb.loan_group_no in (11,12,15,13,14,16) then 0.01
            when dtb.loan_group_no in (3,6) and ld.userdef56 = 'CITADEL' and dtb.trial_balance_date>= ld.userdef58 then 0.0065
            when dtb.loan_group_no in (3,6) and open_date <= '02-28-2023' then 0.0012
            when dtb.loan_group_no in (3,6) and open_date <= '05-31-2023' then 0.0036
            when dtb.loan_group_no in (3,6) and open_date <= '06-30-2023' then 0.0050
            when dtb.loan_group_no in (3,6) and open_date <= '03-31-2024' then 0.0065
            when dtb.loan_group_no in (3,6)  then 0.0090
            when dtb.loan_group_no in (5) and dtb.trial_balance_date>='01-01-2025' then 0.0025
            when dtb.loan_group_no in (2,8,7) then 0
            when dtb.loan_group_no in (9) then 0.01
            else 0 end ) as Servicing_Fee_Rate,
	   CASE WHEN dtb.trial_balance_date = DATEADD(DAY, -1, l.closed_date) AND
				 (SELECT COUNT(*) FROM loanacct_statuses ls (NOLOCK) WHERE ls.acctrefno = l.acctrefno) > 0 THEN
			(SELECT CONVERT(VARCHAR(MAX), CONCAT(lsc.status_code, ' ', FORMAT(ls.effective_date, 'MM/dd/yyyy'), '; '))
			FROM loanacct_statuses ls (NOLOCK)
			JOIN loan_status_codes lsc (NOLOCK) ON ls.status_code_no = lsc.status_code_no
			WHERE ls.acctrefno = l.acctrefno
			FOR XML PATH(''))
		WHEN (SELECT COUNT(*) FROM dtb_statuses ds (NOLOCK) WHERE dtb.row_id = ds.dtb_row_id) > 0 THEN
			(SELECT CONVERT(VARCHAR(MAX), CONCAT(lsc.status_code, ' ', FORMAT(dtb.trial_balance_date, 'MM/dd/yyyy'), '; '))
			 FROM dtb_statuses ds (NOLOCK)
			 JOIN loan_status_codes lsc (NOLOCK) ON ds.status_code_no = lsc.status_code_no
			 WHERE dtb.row_id = ds.dtb_row_id
			 FOR XML PATH(''))
		ELSE '' END AS [Statuses]

FROM daily_trial_balance dtb 
LEFT JOIN (select acctrefno, gl_date, corrected_indicator, sum(interest_accrual) as interest_accrual from loanacct_intaccrual 
                where corrected_indicator = 0 
                group by acctrefno, gl_date, corrected_indicator) la 
    ON dtb.acctrefno = la.acctrefno 
    AND dtb.trial_balance_date = la.gl_date 
LEFT JOIN loanacct l  ON dtb.acctrefno = l.acctrefno
LEFT JOIN Stream_Financial.dbo.cif as cif   on l.cifno = cif.cifno
--LEFT JOIN Stream_Financial.dbo.loanacct_payment as lp  on l.acctrefno = lp.acctrefno
LEFT JOIN loanacct_detail ld (NOLOCK) ON l.acctrefno = ld.acctrefno
LEFT JOIN loanacct_setup lsetup (NOLOCK) ON l.acctrefno = lsetup.acctrefno
--LEFT JOIN (SELECT acctrefno, status_code_no, effective_date FROM loanacct_statuses WHERE status_code_no = 18) AS lsr ON l.acctrefno = lsr.acctrefno
LEFT JOIN (SELECT acctrefno, status_code_no, effective_date FROM loanacct_statuses WHERE status_code_no = 6) AS lsco ON l.acctrefno = lsco.acctrefno
LEFT JOIN daily_trial_balance dtbco ON l.acctrefno = dtbco.acctrefno AND dtbco.trial_balance_date = lsco.effective_date 
LEFT JOIN (SELECT lth.acctrefno, lth.gl_date,
				  SUM(CASE WHEN lth.transaction_code = 100 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 101 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Principal_advance],
				  SUM(CASE WHEN lth.transaction_code = 608 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 609 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Merchant_Discount],
				  SUM(CASE WHEN lth.transaction_code = 614 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 615 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Investor_Premium],
				  SUM(CASE WHEN lth.transaction_code = 620 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 621 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Investor_Discount],
				  SUM(CASE WHEN lth.transaction_code = 122 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 123 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Interest_Billing_amount], 
				  SUM(CASE WHEN lth.transaction_code = 124 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 125 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Principal_Interest_Billing_amount],    
				  SUM(CASE WHEN lth.transaction_code = 150 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 151 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Late_Fee],
				  SUM(CASE WHEN lth.transaction_code = 204 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 205 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Principal_Payment],
				  SUM(CASE WHEN lth.transaction_code = 206 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 207 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Interest_Payment],
				  SUM(CASE WHEN lth.transaction_code = 220 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 221 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Principal_Prepayment],
				  SUM(CASE WHEN lth.transaction_code = 250 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 251 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Late_Fee_Payment],
				  SUM(CASE WHEN lth.transaction_code = 222 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 223 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Interest_Reduction],    
				  SUM(CASE WHEN lth.transaction_code = 702 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 703 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [NET_Overpayment_Refund],
				  SUM(CASE WHEN lth.transaction_code IN (204,206,220,250) THEN lth.transaction_amount
						   WHEN lth.transaction_code IN (205,207,221,251) THEN -1 * lth.transaction_amount
					  ELSE 0 END) AS [Recovery_Amount],
				  SUM(CASE WHEN lth.transaction_code = 490 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 491 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [Total_Charge_off_Balance],

                  SUM(CASE WHEN lth.transaction_code = 440 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 441 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [Principal_Write_Off],
                  SUM(CASE WHEN lth.transaction_code = 444 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 445 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [Interest_Write_Off],
                  SUM(CASE WHEN lth.transaction_code = 448 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 449 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [Late_Fee_Write_Off],
                  SUM(CASE WHEN lth.transaction_code = 716 THEN lth.transaction_amount 
						   WHEN lth.transaction_code = 717 THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [non_cash_principal_advanced],
                  SUM(CASE WHEN lth.transaction_code  in (706,712) THEN lth.transaction_amount 
						   WHEN lth.transaction_code in (707,713) THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [Third_Party_collections_fee],
                  SUM(CASE WHEN lth.transaction_code  in (714) THEN lth.transaction_amount 
						   WHEN lth.transaction_code in (715) THEN -1 * lth.transaction_amount 
					  ELSE 0 END) AS [Post_CO_PMT_Reversal]
FROM loanacct_trans_history lth  --join daily_trial_balance dtb3 (NOLOCK) ON lth.acctrefno = dtb3.acctrefno
	WHERE  lth.participantrefno IS NULL 
    GROUP BY lth.acctrefno, lth.gl_date
	) AS trans
    ON dtb.acctrefno = trans.acctrefno and dtb.trial_balance_date = trans.gl_date
where  l.loan_number not in (-9999, 1248,1117) and dtb.loan_group_no <>8
--AND l.loan_number =14971
),
perf1 AS
(
select 
Product_Type,  
BS_FLAG,  
loan_number, 
open_date,
Territory,
Mailing_State,   
interest_rate,
term,
Vintage_year,
Vintage_Month,
Vintage_BOM,
Vintage_Quarter,
loan_group_no,
min(loan_group_no) as initial_LG,
max(loan_group_no) as Final_LG,
min(trial_balance_date) as min_trial_balance_date,
max(trial_balance_date) as max_trial_balance_date,
sum(Net_Principal_Advance) as Net_Principal_Advance,
sum(NET_Merchant_Discount) as NET_Merchant_Discount,
sum(NET_Investor_Premium) as NET_Investor_Premium,
sum(NET_Investor_Discount) as NET_Investor_Discount,
max(Servicing_Fee_Rate) as Servicing_Fee_Rate,
sum(interest_rate * Net_Principal_Advance) as IRxPA,
sum(Term * Net_Principal_Advance) as TERMxPA
from perf --where trial_balance_date < '06-01-2025' and loan_group_no <>5
group by 
Product_Type,  
BS_FLAG,  
loan_number, 
open_date,
Territory,
Mailing_State,   
interest_rate,
term,
Vintage_Month, vintage_year, vintage_bom,
Vintage_Quarter,loan_group_no
),
perf2 AS
(
select 
Product_type , 
Vintage_year,
vintage_BOM,
vintage_month,
loan_number, open_date, interest_rate, term,
min(initial_lg) as initial_lg,
max(final_lg) as Final_LG,
max(min_trial_balance_date) as potential_origination_date,
min(max_trial_balance_date) as potential_transfer_date,
sum(net_principal_advance) as net_principal_advance,
sum(net_merchant_discount) as net_merchant_discount,
sum(net_investor_premium) as net_investor_premium,
sum(net_investor_discount) as net_investor_discount,
max(servicing_fee_rate) as servicing_fee_rate,
sum(IRxPA) as IRxPA,
sum(TERMxPA) as TERMxPA
from perf1 group by Product_type , 
Vintage_year,
vintage_BOM,
vintage_month,
loan_number, open_date, interest_rate, term
)

--select * from perf2 where initial_LG in (7,9,2) and final_lg in (3,6,8)

select 

Product_type , 
Vintage_year,
vintage_BOM,
(case when initial_LG in (3) and open_date < cast('01-mar-2023' as date) then 'AMH Non Recourse' 
			when initial_LG in (3,6) then 'AMH Recourse' 
			when initial_lg in (8) then 'AMH Repurchase' 
    		when initial_LG in (5)  then 'ENDVR-Solar' 
    		when initial_LG in (11)  then 'STRE-2024-1' 
			when initial_LG in (12)  then 'STRE-2024-2' 
			when initial_LG in (2,7)  then 'SPV1' 
            when initial_LG in (9)  then 'SPV2'
			when initial_LG in (15)  then 'STRE-2025-1' 
			when initial_LG in (13)  then '26N' 
			when initial_LG in (14)  then 'JPM' 
			when initial_LG in (16)  then 'ARES' 
		else 'XXX' end) as Initial_Investor,
(case when final_LG in (3) and open_date < cast('01-mar-2023' as date) then 'AMH Non Recourse' 
			when final_LG in (3,6) then 'AMH Recourse' 
			when final_LG in (8) then 'AMH Repurchase' 
    		when final_LG in (5)  then 'ENDVR-Solar' 
    		when final_LG in (11)  then 'STRE-2024-1' 
			when final_LG in (12)  then 'STRE-2024-2' 
			when final_LG in (2,7)  then 'SPV1' 
			when final_LG in (9)  then 'SPV2' 
			when final_LG in (15)  then 'STRE-2025-1' 
			when final_LG in (13)  then '26N' 
			when final_LG in (14)  then 'JPM' 
			when initial_LG in (16)  then 'ARES' 
		else 'XXX' end) as Final_Investor,
(case when final_LG in (2,7,9,11,12,15) then 'BS' else 'FF' end) as Final_deal_type,    
(case when initial_lg=final_lg then '' else eomonth(potential_transfer_date) end) as Transfer_date,
(case when initial_lg=5 then 0.01 else 0.05 end) as CNL,
max('Curve') as CPR,
sum(net_principal_advance) as Origination_amount,
round(sum(IRxPA)/sum(net_principal_advance),2)/100 as WA_IR,
round(sum(TERMxPA)/sum(net_principal_advance),0) as WA_TERM,
max(Servicing_Fee_Rate) as Servicing_Fee_Rate,
sum(NET_Merchant_Discount)/sum(net_principal_advance) as Merchant_discount_rate,
sum(NET_Investor_Premium-net_investor_discount)/sum(net_principal_advance) as Investor_premium_rate,
sum(net_principal_advance)/count(loan_number) as Average_Loan_Amount,
count(loan_number) as Number_of_Loans,
max(0) as [Initial Cost of Funds],
max(0) as [Initial Advance Rate],
max(0) as [Final Cost of Funds],
max(0) as [Final Advance Rate],
sum(0) as [ABS Expense Rate],
sum(0) as [ABS Expense Amortization Period in Months] ,
sum(0) as [ABS Monthly Expense],
sum(0) as [Originations expense per loan]
from perf2 where net_principal_advance>0 
group BY

Product_type , 
Vintage_year,
vintage_BOM,
(case when initial_LG in (3) and open_date < cast('01-mar-2023' as date) then 'AMH Non Recourse' 
			when initial_LG in (3,6) then 'AMH Recourse' 
			when initial_lg in (8) then 'AMH Repurchase' 
    		when initial_LG in (5)  then 'ENDVR-Solar' 
    		when initial_LG in (11)  then 'STRE-2024-1' 
			when initial_LG in (12)  then 'STRE-2024-2' 
			when initial_LG in (2,7)  then 'SPV1' 
            when initial_LG in (9)  then 'SPV2'
			when initial_LG in (15)  then 'STRE-2025-1' 
			when initial_LG in (13)  then '26N' 
			when initial_LG in (14)  then 'JPM' 
			when initial_LG in (16)  then 'ARES' 
		else 'XXX' end) ,
(case when final_LG in (3) and open_date < cast('01-mar-2023' as date) then 'AMH Non Recourse' 
			when final_LG in (3,6) then 'AMH Recourse' 
			when final_LG in (8) then 'AMH Repurchase' 
    		when final_LG in (5)  then 'ENDVR-Solar' 
    		when final_LG in (11)  then 'STRE-2024-1' 
			when final_LG in (12)  then 'STRE-2024-2' 
			when final_LG in (2,7)  then 'SPV1' 
			when final_LG in (9)  then 'SPV2' 
			when final_LG in (15)  then 'STRE-2025-1' 
			when final_LG in (13)  then '26N' 
			when final_LG in (14)  then 'JPM' 
			when final_LG in (16)  then 'ARES' 
		else 'XXX' end),
(case when final_LG in (2,7,9,11,12,15) then 'BS' else 'FF' end) ,    
(case when initial_lg=final_lg then ''
    else eomonth(potential_transfer_date) end) ,
(case when initial_lg=5 then 0.01 else 0.05 end) 
order by 
vintage_year,vintage_bom, transfer_date