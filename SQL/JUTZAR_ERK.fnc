CREATE OR REPLACE FUNCTION POORJ.jutzar_erk (erkezes IN DATE)
   RETURN DATE
IS
   idoszak   DATE;
BEGIN
   SELECT   MIN (f_idoszak)
     INTO   idoszak
     FROM   poorj.t_jut_zaras
    WHERE   f_erkezes >= trunc(erkezes, 'ddd');

   RETURN idoszak;
END jutzar_erk;
/
