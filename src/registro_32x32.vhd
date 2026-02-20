library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registro_32x32 is
    generic (
        constant init_file : string := ""
    );
    port (
        clk    : in  std_logic;
        addr_1 : in std_logic_vector(4 downto 0);
        dout_1 : out std_logic_vector(31 downto 0);
        addr_2 : in std_logic_vector(4 downto 0);
        dout_2 : out std_logic_vector(31 downto 0);

        we_w   : in  std_logic;
        addr_w : in  std_logic_vector(4 downto 0);
        din_w  : in  std_logic_vector(31 downto 0)
    );
end entity registro_32x32;
architecture arch of registro_32x32 is
    type reg_type is array (0 to 31) of std_logic_vector(31 downto 0);
    
    signal registro : reg_type;
    
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                if we_w = '1' then
                    registro(to_integer(unsigned(addr_w))) <= din_w;
                end if ;
            end if;
         dout_1 <= registro(to_integer(unsigned(addr_1)));
         dout_2 <= registro(to_integer(unsigned(addr_2)));    
        end process;
end arch;
