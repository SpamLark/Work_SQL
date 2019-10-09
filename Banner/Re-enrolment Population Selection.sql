/*

Re-enrolment Population Selection

*/

SELECT
    d1.spriden_id,
    t1.sgrstsp_pidm,
    t1.sgrstsp_key_seqno,
    t1.sgrstsp_term_code_eff,
    t1.sgrstsp_stsp_code,
    t2.sorlcur_key_seqno,
    t2.sorlcur_priority_no,
    t2.sorlcur_end_date,
    t2.sorlcur_term_code,
    t2.sorlcur_term_code_end,
    t2.sorlcur_curr_rule,
    t3.sorlfos_csts_code,
    t4.sgbstdn_term_code_eff,
    t4.acenrol_status_1,
    t4.finenrol_status_1,
    t4.overall_enrol_status_1
FROM
    sgrstsp t1
    JOIN sorlcur t2 ON (t1.sgrstsp_pidm = t2.sorlcur_pidm AND t1.sgrstsp_key_seqno = t2.sorlcur_key_seqno)
    JOIN sorlfos t3 ON (t2.sorlcur_pidm = t3.sorlfos_pidm AND t2.sorlcur_seqno = t3.sorlfos_lcur_seqno)
    JOIN spriden d1 ON (t1.sgrstsp_pidm = d1.spriden_pidm)
    JOIN sgbstdn_add t4 ON (t1.sgrstsp_pidm = t4.sgbstdn_pidm)
WHERE
    1=1

-- CURRENT STUDENT NUMBER
    AND d1.spriden_change_ind IS NULL

-- IDENTIFY STUDENTS WITH ACTIVE STUDY PATHS
    AND t1.sgrstsp_term_code_eff = (
        SELECT MAX(a2.sgrstsp_term_code_eff)
        FROM sgrstsp a2
        WHERE t1.sgrstsp_pidm = a2.sgrstsp_pidm AND t1.sgrstsp_key_seqno = a2.sgrstsp_key_seqno
        AND t1.sgrstsp_stsp_code = 'AS'
    )


-- ONLY INCLUDE STUDY PATHS WITH A COMPLETION DATE BEYOND MASTERS DISSERTATION SUBMISSION DEADLINE
    AND t2.sorlcur_term_code = (
        SELECT MAX(b2.sorlcur_term_code)
        FROM sorlcur b2
        WHERE t2.sorlcur_pidm = b2.sorlcur_pidm AND t2.sorlcur_key_seqno = b2.sorlcur_key_seqno
        AND t2.sorlcur_lmod_code = 'LEARNER' AND t2.sorlcur_end_date >= '01-OCT-2019'
    )
    AND t2.sorlcur_lmod_code = 'LEARNER' AND t2.sorlcur_end_date >= '01-OCT-2019'

-- LIMIT TO CURRENT SGBSTDN RECORD
    AND t4.sgbstdn_term_code_eff = (
        SELECT MAX(e2.sgbstdn_term_code_eff)
        FROM sgbstdn e2
        WHERE t4.sgbstdn_pidm = e2.sgbstdn_pidm
    )

-- ONLY INCLUDE MAX PROPER SORLCUR RECORDS
    AND t3.SORLFOS_csts_code = 'INPROGRESS'
    AND t2.sorlcur_current_cde = 'Y'
    AND t2.sorlcur_term_code_end IS NULL

-- EXCLUDE STUDENTS WHO ARE ALREADY EN/AT/UT/WD FOR THE TERM
    AND t1.sgrstsp_pidm NOT IN (
        SELECT sfrensp_pidm FROM sfrensp WHERE sfrensp_term_code = '201909' AND sfrensp_ests_code in ('AT', 'EN', 'UT', 'WD')
    )

-- EXCLUDE NEW STUDENTS
    AND t2.sorlcur_term_code_admit != '201909'

--AND d1.spriden_id = '18013434'
AND t4.acenrol_status_1 IS NULL

ORDER BY
    sorlcur_end_date ASC