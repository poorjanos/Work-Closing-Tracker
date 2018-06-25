CREATE OR REPLACE PROCEDURE POORJ.first_prem
IS
BEGIN
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_bsc_irat';

   COMMIT;

   INSERT INTO t_prop_com (f_ivk, f_termcsop)
      SELECT   DISTINCT
               a.f_ivk, CONVERT (f_termcsop, 'US7ASCII') AS f_termcsop
        FROM   kontakt.t_ajanlat_attrib a
       WHERE   f_erkezes >=
                  (SELECT   ADD_MONTHS (TRUNC (MIN (f_menesztes), 'mm'), -9)
                     FROM   t_jut_zaras
                    WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd'));

   COMMIT;


   /* Add contractid*/

   UPDATE   t_prop_com a
      SET   szerzazon =
               (SELECT   f_szerzazon
                  FROM   r_irat_ajanlat b
                 WHERE   a.f_ivk = b.f_ivk);

   COMMIT;


   /* Collect  premiums to proposals*/
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_prem_abl';

   INSERT INTO t_prem_abl (f_ivk,
                           szerzazon,
                           dijbefizdat,
                           dijerkdat,
                           dijkonyvdat)
        SELECT   a.f_ivk,
                 a.szerzazon,
                 MIN (f_dijbeido) AS dijbefizdat,
                 MIN (f_banknap) AS dijerkdat,
                 MIN (f_datum) AS dijkonyvdat
          FROM   t_prop_com a, ab_t_dijtabla@dl_peep b
         WHERE   a.szerzazon = b.f_szerz_azon AND a.f_termcsop <> 'ELET'
      GROUP BY   a.f_ivk, a.szerzazon;

   COMMIT;


   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_prem_fufi';

   INSERT INTO t_prem_fufi (f_ivk,
                           szerzazon,
                            dijbefizdat,
                            dijerkdat,
                            dijkonyvdat)
        SELECT   c.f_ivk,
                 c.szerzazon,
                 MIN (b.payment_date) AS dijbefizdat,
                 MIN (b.value_date) AS dijerkdat,
                 MIN (a.application_date) AS dijkonyvdat
          FROM   fmoney_in_application@dl_peep a,
                 (SELECT   DISTINCT money_in_idntfr,
                                    payment_mode,
                                    money_in_type,
                                    ifi_mozgaskod,
                                    payment_date,
                                    value_date
                    FROM   fmoney_in@dl_peep) b,
                 t_prop_com c
         WHERE       c.f_ivk = a.proposal_idntfr
                 AND a.money_in_idntfr = b.money_in_idntfr
                 AND ref_entity_type = 'Premium'
                 AND application_status = 'normal'
                 AND a.cntry_flg = 'HU'
                 AND a.currncy_code = 'HUF'
                 AND money_in_type IN ('propprem', 'reguprem')
                 AND c.f_termcsop = 'ELET'
      GROUP BY   c.f_ivk, c.szerzazon;

   COMMIT;


   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_first_paid_prem';

   INSERT INTO t_first_paid_prem (f_ivk,
                                  szerzazon,
                                  dijbefizdat,
                                  dijerkdat,
                                  dijkonyvdat)
        SELECT   * FROM t_prem_abl
      UNION
        SELECT   * FROM t_prem_fufi;

   COMMIT;
END first_prem;
/