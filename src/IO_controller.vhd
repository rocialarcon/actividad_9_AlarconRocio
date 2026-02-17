library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IO_controller is 
    generic (
        base_addr : std_logic_vector(31 downto 0) := x"80000000"
    
     );
    port (
        clk  : in std_logic;
        nreset : in std_logic;
        --interfaz del bus 
        bus_addr : in std_logic_vector(31 downto 0);
        bus_dms  : in std_logic_vector(31 downto 0);
        bus_tms : in std_logic;
        --respuestas al bus 
        bus_sact : out std_logic;
        bus_dsm : out std_logic_vector(31 downto 0);
        --salida fisica
        leds : out std_logic_vector(3 downto 0)
    );
end IO_controller;

architecture arch of IO_controller is

    signal is_addr : boolean;
    signal reg_leds : std_logic_vector(3 downto 0);

begin
    is_addr <= (base_addr(31 downto 4) = bus_addr(31 downto 4));
    bus_sact <= '1' when is_addr else '0';
    bus_dsm <= (31 downto 4 => '0') & reg_leds;

    process (clk)
    begin
        if rising_edge(clk) then
            if nreset = '0' then
                reg_leds <= (others => '0');
            else
                if is_addr and bus_tms = '1' then
                    reg_leds <= bus_dms(3 downto 0);
                end if;
            end if;
        end if;
    end process;
    leds <= reg_leds;

end arch ; 

