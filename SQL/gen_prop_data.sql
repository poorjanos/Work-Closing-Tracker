/* Track status of proposals and premiums in commission period */

/* Gen proposal table */
DROP TABLE t_prop_com;
COMMIT;

CREATE TABLE t_prop_com
AS
   SELECT   a.f_ivk,
            CONVERT (f_termcsop, 'US7ASCII') AS f_termcsop,
            CASE
               WHEN F_CSATORNA LIKE 'U%' OR F_CSATORNA LIKE 'O%'
               THEN
                  'Halozat'
               WHEN F_CSATORNA = 'DUF'
               THEN
                  'Alfa'
               WHEN    F_CSATORNA LIKE 'B%'
                    OR F_CSATORNA LIKE 'I%'
                    OR F_CSATORNA LIKE 'S%'
               THEN
                  'Alkusz'
               WHEN F_CSATORNA LIKE 'PRF' OR F_CSATORNA LIKE 'WF'
               THEN
                  'Alternativ'
               WHEN F_CSATORNA = 'PSF'
               THEN
                  'Premium'
               ELSE
                  'Direkt'
            END
               AS F_CSATORNA_KAT,
            CONVERT (f_kecs_pg, 'US7ASCII') AS f_kecs_pg,
            CONVERT (f_kecs, 'US7ASCII') AS f_kecs,
            f_erkezes,
            f_lezaras,
            poorj.jutzar_erk(f_erkezes) as jutzar_erk_idoszak,
            poorj.jutzar_men(f_lezaras) as jutzar_men_idoszak
     FROM   kontakt.t_ajanlat_attrib a
    WHERE   f_erkezes >= date '2018-01-01';

COMMIT;


/* Filter for current period*/
DROP TABLE t_prop_com_current;
COMMIT;

CREATE TABLE t_prop_com_current
as
SELECT   *
  FROM   t_prop_com
 WHERE   
 --first filter for pending cases or cases closed in period (until end of closing the below select evaluates to current period)
 (jutzar_men_idoszak IS NULL
          OR jutzar_men_idoszak =
               (SELECT   TRUNC (MIN (f_menesztes), 'mm')
                  FROM   t_jut_zaras
                 WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd')))
 --second exclude cases that arrive in the closing period (until end of closing the below select evaluates to current period)
         AND jutzar_erk_idoszak <=
               (SELECT   TRUNC (MIN (f_menesztes), 'mm')
                  FROM   t_jut_zaras
                 WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd'));
COMMIT;




/* Add contractid premium fields*/
ALTER TABLE t_prop_com_current
ADD(
szerzazon varchar2(20),
dijbefizdat date,
dijerkdat date,
dijkonyvdat date);
COMMIT;


/* Add contractid*/

UPDATE   t_prop_com_current a
   SET   szerzazon =
            (SELECT   f_szerzazon
               FROM   r_irat_ajanlat b
              WHERE   a.f_ivk = b.f_ivk);

COMMIT;


/* Collect  premiums to proposals*/

CREATE INDEX prop
   ON t_prop_com_current (f_ivk);

COMMIT;

CREATE INDEX contr
   ON t_prop_com_current (szerzazon);

COMMIT;


/* Gen premium table*/
DROP TABLE t_prem_abl;
COMMIT;

CREATE TABLE t_prem_abl
AS
     SELECT   a.szerzazon,
              MIN (f_dijbeido) AS dijbefizdat,
              MIN (f_banknap) AS dijerkdat,
              MIN (f_datum) AS dijkonyvdat
       FROM   t_prop_com_current a, ab_t_dijtabla@dl_peep b
      WHERE   a.szerzazon = b.f_szerz_azon AND a.f_termcsop <> 'ELET'
   GROUP BY   a.szerzazon;

COMMIT;
DROP TABLE t_prem_fufi;
COMMIT;

CREATE TABLE t_prem_fufi
AS
     SELECT   c.szerzazon,
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
              t_prop_com_current c
      WHERE       c.f_ivk = a.proposal_idntfr
              AND a.money_in_idntfr = b.money_in_idntfr
              AND ref_entity_type = 'Premium'
              AND application_status = 'normal'
              AND a.cntry_flg = 'HU'
              AND a.currncy_code = 'HUF'
              AND money_in_type IN ('propprem', 'reguprem')
              AND c.f_termcsop = 'ELET'
   GROUP BY   c.szerzazon;

COMMIT;
DROP TABLE t_prem_helper;
COMMIT;

CREATE TABLE t_prem_helper
AS
   SELECT   * FROM t_prem_abl
   UNION
   SELECT   * FROM t_prem_fufi;

COMMIT;


/* Add premiums to proposals*/

CREATE INDEX prem
   ON t_prem_helper (szerzazon);

COMMIT;

UPDATE   t_prop_com_current a
   SET   (dijbefizdat,dijerkdat,dijkonyvdat) =
            (SELECT   dijbefizdat, dijerkdat, dijkonyvdat
               FROM   t_prem_helper b
              WHERE   a.szerzazon = b.szerzazon);

COMMIT;

/* Gen premium flag*/
ALTER TABLE t_prop_com_current
ADD(
dijkonyv varchar2(20));
COMMIT;

UPDATE   t_prop_com_current
   SET   dijkonyv = 'Van konyvelt dij'
 WHERE   dijkonyvdat IS NOT NULL;

COMMIT;

UPDATE   t_prop_com_current
   SET   dijkonyv = 'Nincs konyvelt dij'
 WHERE   dijkonyvdat IS NULL;

COMMIT;
DROP INDEX prop;
DROP INDEX contr;
DROP INDEX prem;
COMMIT;