library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;
use ieee.math_real.all;

entity alu is
    generic (
       constant W : positive := 32
    );
    port (
        A : in std_logic_vector (W-1 downto 0);
        B : in std_logic_vector (W-1 downto 0);
        sel_fn : in std_logic_vector (3 downto 0);
        Y : out std_logic_vector (W-1 downto 0);
        Z : out std_logic
    );
end alu;
architecture arch of alu is
    signal Y_aux : std_logic_vector(W -1 downto 0);
    constant Ws : natural := integer(ceil(log2(real(W))));  
    signal Au, Bu : unsigned(W-1 downto 0);
    signal As, Bs : signed(W-1 downto 0); 
 
begin
   Au <= unsigned(A);
   Bu <= unsigned(B);
   As <= signed(A);
   Bs <= signed(B);    
 funciones : process(all)
 begin
 case sel_fn is 
--suma A + B
    when "0000" =>
     Y_aux <=  std_logic_vector(Au + Bu);
-- resta A - B 
    when "0001" =>
     Y_aux <= std_logic_vector(Au - Bu);
--desplazamiento a la izquierda, A se dezplaza B veces a la izquierda (se le agrega B cantidades de ceros)
    when "0010"|"0011" =>
     Y_aux <= std_logic_vector(shift_left(Au, to_integer(Bu(Ws-1 downto 0))));
-- A menor a B en complemento a dos
    when "0100"|"0101" =>
     if As < Bs then
        Y_aux <=(0 => '1', others => '0');
        else
            Y_aux <= (others => '0');
     end if ;
--A menor que B en unsigned
    when "0110"|"0111" =>
     if Au < Bu then
        Y_aux <=(0 => '1',others => '0');
        else
            Y_aux <= (others => '0');
     end if ;
-- compuertas xor exclusiva
    when "1000" | "1001" =>
     Y_aux <= A xor B;
-- desplazamiento a la derecha unsigned, A se dezplaza B veces a la derecha(solo se agregan ceros)
    when "1010" =>
     Y_aux <= std_logic_vector(shift_right(Au, to_integer(Bu(Ws-1 downto 0))));
--desplazamiento a la derecha en complemento a dos, A se dezplaza B veces a la derecha (se agreagan ceros o unos, depende del signo)
    when "1011" =>
     Y_aux <= std_logic_vector(shift_right(As,to_integer(Bu(Ws-1 downto 0))));
--compuerta or
    when "1100" | "1101" =>
     Y_aux <= A or B;
--compuerta and
    when "1110" | "1111" =>
     Y_aux <= A and B;
    when others => 
     Y_aux <= (others => '0');
 end case;
 end process;
  Y <= Y_aux;
  Z <= '1' when Y_aux = (Y_aux'range => '0') else '0';
end arch;