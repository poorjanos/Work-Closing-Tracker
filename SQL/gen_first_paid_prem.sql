/* Formatted on 2018. 06. 25. 9:28:35 (QP5 v5.115.810.9015) */
/* Generate premium data once a day */

/* Gen proposal table */
DROP TABLE t_prop_com;
COMMIT;

CREATE TABLE t_prop_com
AS
   SELECT   DISTINCT a.f_ivk, CONVERT (f_termcsop, 'US7ASCII') AS f_termcsop
     FROM   kontakt.t_ajanlat_attrib a
    WHERE   f_erkezes >=
               (SELECT   ADD_MONTHS (TRUNC (MIN (f_menesztes), 'mm'), -9)
                  FROM   t_jut_zaras
                 WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd'));

COMMIT;



/* Add contractid premium fields*/
ALTER TABLE t_prop_com
ADD(
szerzazon varchar2(20),
dijbefizdat date,
dijerkdat date,
dijkonyvdat date);
COMMIT;


/* Add contractid*/

UPDATE   t_prop_com a
   SET   szerzazon =
            (SELECT   f_szerzazon
               FROM   r_irat_ajanlat b
              WHERE   a.f_ivk = b.f_ivk);

COMMIT;


/* Collect  premiums to proposals*/

CREATE INDEX prop
   ON t_prop_com (f_ivk);

COMMIT;

CREATE INDEX contr
   ON t_prop_com (szerzazon);

COMMIT;


/* Gen premium table*/
DROP TABLE t_prem_abl;
COMMIT;

CREATE TABLE t_prem_abl
AS
     SELECT   a.f_ivk,
              a.szerzazon,
              MIN (f_dijbeido) AS dijbefizdat,
              MIN (f_banknap) AS dijerkdat,
              MIN (f_datum) AS dijkonyvdat
       FROM   t_prop_com a, ab_t_dijtabla@dl_peep b
      WHERE   a.szerzazon = b.f_szerz_azon AND a.f_termcsop <> 'ELET'
   GROUP BY   a.f_ivk, a.szerzazon;

COMMIT;
DROP TABLE t_prem_fufi;
COMMIT;

CREATE TABLE t_prem_fufi
AS
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
DROP TABLE t_first_paid_prem;
COMMIT;

CREATE TABLE t_first_paid_prem
AS
   SELECT   * FROM t_prem_abl
   UNION
   SELECT   * FROM t_prem_fufi;

COMMIT;


/* Clean up*/
COMMIT;
DROP INDEX prop;
DROP INDEX contr;
COMMIT;