/* Run query for t-4 months as of arrival then filter for current closing period*/
  SELECT   TRUNC (SYSDATE, 'hh') AS idopont,
           a.f_ivk,
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
           kontakt.basic.aivk_atfutas(a.f_ivk) afc_napos,
           f_erkezes,
           f_lezaras,
           poorj.jutzar_erk (f_erkezes) AS jutzar_erk_idoszak,
           poorj.jutzar_men (f_lezaras) AS jutzar_men_idoszak,
           b.dijbefizdat,
           b.dijerkdat,
           b.dijkonyvdat
    FROM   kontakt.t_ajanlat_attrib a, t_first_paid_prem b
   WHERE   a.f_ivk = b.f_ivk(+)
           AND                          --filter fot t-4 periods as of arrival
              f_erkezes >=
                 (SELECT   ADD_MONTHS (TRUNC (MIN (f_menesztes), 'mm'), -4)
                    FROM   t_jut_zaras
                   WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd'))
           AND --filter for pending cases or cases closed in period (until end of closing the below select evaluates to current period)
               (poorj.jutzar_men (f_lezaras) IS NULL
                OR poorj.jutzar_men (f_lezaras) =
                     (SELECT   TRUNC (MIN (f_menesztes), 'mm')
                        FROM   t_jut_zaras
                       WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd')))
           --second exclude cases that arrive in the closing period (until end of closing the below select evaluates to current period)
           AND poorj.jutzar_erk (f_erkezes) <=
                 (SELECT   TRUNC (MIN (f_menesztes), 'mm')
                    FROM   t_jut_zaras
                   WHERE   f_menesztes >= TRUNC (SYSDATE, 'ddd'))
ORDER BY   f_erkezes
