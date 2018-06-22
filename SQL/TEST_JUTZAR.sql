-- test suite for function jutzar_erk
SELECT   f_ivk, f_erkezes, poorj.jutzar_erk (f_erkezes)
  FROM   kontakt.t_ajanlat_attrib
 WHERE   f_termcsop = 'ÉLET'
         AND (   TRUNC (f_erkezes, 'ddd') = DATE '2018-06-12'
              OR TRUNC (f_erkezes, 'ddd') = DATE '2018-06-13'
              OR TRUNC (f_erkezes, 'ddd') = DATE '2018-06-14');


-- test suite for function jutzar_men
SELECT   f_ivk,
         f_erkezes,
         f_lezaras,
         poorj.jutzar_erk (f_erkezes),
         poorj.jutzar_men (f_lezaras)
  FROM   kontakt.t_ajanlat_attrib
 WHERE   f_termcsop = 'ÉLET'
         AND (   TRUNC (f_erkezes, 'ddd') = DATE '2018-06-12'
              OR TRUNC (f_erkezes, 'ddd') = DATE '2018-06-13'
              OR TRUNC (f_erkezes, 'ddd') = DATE '2018-06-14')
         AND (f_lezaras IS NULL
         OR TRUNC (f_lezaras, 'ddd') = DATE '2018-06-19'
              OR TRUNC (f_lezaras, 'ddd') = DATE '2018-06-20'
              OR TRUNC (f_lezaras, 'ddd') = DATE '2018-06-21');
