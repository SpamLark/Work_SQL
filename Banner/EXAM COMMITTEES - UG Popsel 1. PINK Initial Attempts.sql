

spriden_pidm IN 
		(
    SELECT DISTINCT shrmrks_pidm
FROM
    shrmrks
    JOIN shrgcom ON shrmrks_term_code = shrgcom_term_code AND shrmrks_crn = shrgcom_crn  AND shrmrks_gcom_id = shrgcom_id
    JOIN ssbsect ON shrmrks_crn = ssbsect_crn AND shrmrks_term_code = ssbsect_term_code
    JOIN sfrstcr ON shrmrks_term_code = sfrstcr_term_code AND shrmrks_crn = sfrstcr_crn AND shrmrks_pidm = sfrstcr_pidm
    JOIN stvrsts ON stvrsts_code = sfrstcr_rsts_code
    JOIN sorlcur s1 ON sfrstcr_pidm = s1.sorlcur_pidm AND sfrstcr_stsp_key_sequence = s1.sorlcur_key_seqno
WHERE
    1=1

    -- Only return module runs that meet these criteria
    AND shrmrks_crn IN (
        SELECT
            ssbsect_crn
        FROM
            ssbsect
            JOIN sobptrm ON ssbsect_term_code = sobptrm_term_code AND ssbsect_ptrm_code = sobptrm_ptrm_code
        WHERE
            1=1

            -- Limit to UMP modules

            AND ssbsect_subj_code||chr(1)||ssbsect_crse_numb IN (
                SELECT gorsdav_pk_parenttab
                FROM gorsdav
                WHERE gorsdav_table_name = 'SCBCRKY' AND gorsdav_attr_name = 'UMP' AND sys.ANYDATA.accessvarchar2(gorsdav_value) = 'Y'
            )
            
            -- Limit to modules that end between specified dates
            AND sobptrm_end_date BETWEEN :EX_2_TAUGHT_MOD_START AND :EX_3_TAUGHT_MOD_END
        )

    -- Only include students who are still registered on the module
    AND stvrsts_incl_sect_enrl = 'Y'
    
    AND s1.sorlcur_cact_code = 'ACTIVE'
    AND s1.sorlcur_current_cde = 'Y'
    AND s1.sorlcur_lmod_code = 'LEARNER'
    AND s1.sorlcur_term_code_end IS NULL
    AND s1.sorlcur_term_code = (
    	SELECT MAX(s2.sorlcur_term_code)
    	FROM sorlcur s2
    	WHERE
    		1=1
    		AND s1.sorlcur_pidm = s2.sorlcur_pidm
    		AND s1.sorlcur_key_seqno = s2.sorlcur_key_seqno
    		AND s2.sorlcur_cact_code = 'ACTIVE'
    		AND s2.sorlcur_current_cde = 'Y'
    		AND s2.sorlcur_lmod_code = 'LEARNER'
    )
    
    --Students on a current X1 attribute or currently on a Foundation Year
	AND (sorlcur_pidm||sorlcur_key_seqno IN (
		SELECT
			v1.sgrsatt_pidm||v1.sgrsatt_stsp_key_sequence
		FROM
			sgrsatt v1
		WHERE
			1=1
			AND v1.sgrsatt_term_code_eff <= :EX_0_TERM_CODE AND v1.sgrsatt_atts_code = 'X1'
			AND v1.sgrsatt_pidm NOT IN
				(
				SELECT v2.sgrsatt_pidm 
				FROM sgrsatt v2 
				WHERE 
					1=1
					AND v1.sgrsatt_pidm = v2.sgrsatt_pidm 
					AND v1.sgrsatt_stsp_key_sequence = v2.sgrsatt_stsp_key_sequence 
					AND v2.sgrsatt_term_code_eff <= :EX_0_TERM_CODE 
					AND v2.sgrsatt_atts_code IN ('X2', 'X3','SW')
				)
	)
    OR s1.sorlcur_program IN ('FNDIP-FBE','FNDIP-FBU','FNDIP-FCO','FNDIP-FEG','FNDIP-FHU','FNDIP-FLL', 'FNDIP-LSF')
    )		
)