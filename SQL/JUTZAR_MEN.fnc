CREATE OR REPLACE FUNCTION POORJ.jutzar_men (menesztes IN DATE)
   RETURN DATE
IS
   idoszak   DATE;
BEGIN
   IF menesztes IS NULL
   THEN
      SELECT   NULL INTO idoszak FROM DUAL;
   ELSE
      SELECT   MIN (f_idoszak)
        INTO   idoszak
        FROM   poorj.t_jut_zaras
       WHERE   f_menesztes >= TRUNC (menesztes, 'ddd');
   END IF;

   RETURN idoszak;
END jutzar_men;
/