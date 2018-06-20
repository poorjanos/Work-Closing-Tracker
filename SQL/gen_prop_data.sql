/* Track status of proposals and premiums in commission period */

/* Gen proposal table */
DROP TABLE t_prop_com;
COMMIT;

CREATE TABLE t_prop_com
AS
   SELECT   a.f_ivk,
            convert(f_termcsop, 'US7ASCII') as f_termcsop,
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
            convert(f_kecs_pg, 'US7ASCII') as f_kecs_pg,
            f_erkezes
     FROM   kontakt.t_ajanlat_attrib a
    WHERE   f_erkezes BETWEEN DATE '2018-05-14' AND DATE '2018-06-13'
            OR (f_erkezes < DATE '2018-05-14'
                AND f_lezaras >= DATE '2018-05-14');
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



/* Gen premium table*/
DROP TABLE t_prem_abl;
COMMIT;

CREATE TABLE t_prem_abl
AS
     SELECT   a.szerzazon,
              MIN (f_dijbeido) AS dijbefizdat,
              MIN (f_banknap) AS dijerkdat,
              MIN (f_datum) AS dijkonyvdat
       FROM   t_prop_com a, ab_t_dijtabla@dl_peep b
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
              t_prop_com c
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
DROP INDEX prop;

CREATE INDEX prop
   ON t_prop_com (szerzazon);

COMMIT;
DROP INDEX prem;

CREATE INDEX prem
   ON t_prem_helper (szerzazon);

COMMIT;

UPDATE   t_prop_com a
   SET   (dijbefizdat,dijerkdat,dijkonyvdat) =
            (SELECT   dijbefizdat, dijerkdat, dijkonyvdat
               FROM   t_prem_helper b
              WHERE   a.szerzazon = b.szerzazon);

COMMIT;

/* Gen premium flag*/
ALTER TABLE t_prop_com
ADD(
dijkonyv varchar2(20));
COMMIT;

UPDATE   t_prop_com
   SET   dijkonyv = 'Van konyvelt dij'
 WHERE   dijkonyvdat IS NOT NULL;

COMMIT;

UPDATE   t_prop_com
   SET   dijkonyv = 'Nincs konyvelt dij'
 WHERE   dijkonyvdat IS NULL;

COMMIT;


/* Delete old items*/
DELETE FROM   t_prop_com
      WHERE   f_erkezes < DATE '2018-03-01';

COMMIT;