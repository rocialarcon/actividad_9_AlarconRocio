library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity O_controller is 
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
        leds : out std_logic_vector(7 downto 0)
    );
end O_controller;

architecture arch of O_controller is

    signal addr_match : std_logic;
    signal and_gate : std_logic;
    signal dout_reg : std_logic_vector(31 downto 0);

begin
    addr_match <= '1' when bus_addr = base_addr else '0';
    and_gate <= addr_match and bus_tms;
    process (clk)
    begin 
        if rising_edge(clk) then 
            if nreset = '0' then
                bus_sact <= '0';
                dout_reg <= (others => '0');
            else 
                bus_sact <= and_gate;
                if and_gate = '1' then 
                dout_reg <= bus_dms;
                end if;
            end if;
        end if;
    end process;

    bus_dsm <= dout_reg;
    leds <= dout_reg(7 downto 0);


end arch ; 

