library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tipos.all;
use work.all;

entity top is port (
    clk_i : in std_logic;
    leds_o : out std_logic_vector(7 downto 0);
    interruptores : in std_logic_vector(7 downto 0)
);
end top;

architecture arch of top is
    --bus maestro (CPU -> crosbar)
    signal m_addr : std_logic_vector(31 downto 0);
    signal m_dms : std_logic_vector(31 downto 0);
    signal m_twidth : std_logic_vector(2 downto 0);
    signal m_tms : std_logic;
    signal m_dsm : std_logic_vector(31 downto 0);
    --bus esclavo (crossbar -> RAM/IO)
    signal s_addr : std_logic_vector(31 downto 0); 
    signal s_dms : std_logic_vector(31 downto 0);
    signal s_twidth : std_logic_vector(2 downto 0); 
    signal s_tms : std_logic;
    --respiuestas de esclavos 
    signal s_sact_arr : std_logic_vector(1 downto 0);
    signal s_dsm_arr : word_array(1 downto 0);
    --señales RAM
    signal ram_we_c : std_logic;
    signal ram_mask_c : std_logic_vector(3 downto 0);
    signal ram_addr_c : std_logic_vector(8 downto 0);
    signal ram_din_c : std_logic_vector(31 downto 0);
    signal ram_dout_c : std_logic_vector(31 downto 0);
    --reset
    signal sys_nreset : std_logic;
begin
    
    U_NRESET : entity reset_al_inicializar_fpga port map (
        clk => clk_i,
        nreset_in => interruptores(7),
        nreset_out => sys_nreset
    );

    U_CPU : entity cpu port map (
        clk => clk_i,
        nreset => sys_nreset,
        bus_dsm => m_dsm,
        bus_addr => m_addr,
        bus_dms => m_dms,
        bus_twidth => m_twidth,
        bus_tms => m_tms
    );

    U_CROSSBAR : entity crossbar generic map (
        num_slaves => 2
    ) port map (
        bus_maddr => m_addr,
        bus_mdms => m_dms,
        bus_mtwidth => m_twidth,
        bus_mtms => m_tms,
        bus_mdsm => m_dsm,
        bus_saddr => s_addr,
        bus_sdms => s_dms,
        bus_stwidth => s_twidth,
        bus_stms => s_tms,
        bus_sdsm => s_dsm_arr,
        bus_sact => s_sact_arr
    );

    U_RAM_CONTROLLER : entity ram_controller generic map (
        ram_addr_nbits => 9,
        ram_base => x"00000000"
    ) port map (
        clk => clk_i,
        bus_addr => s_addr,
        bus_dms => s_dms,
        bus_twidth => s_twidth,
        bus_tms => s_tms,
        bus_dsm => s_dsm_arr(0),
        bus_sact => s_sact_arr(0),
        ram_we => ram_we_c,
        ram_mask => ram_mask_c,
        ram_addr => ram_addr_c,
        ram_din => ram_din_c,
        ram_dout => ram_dout_c
    );

    U_O_CONTROLLER : entity O_controller generic map (
        base_addr => x"80000000"
    ) port map (
        clk => clk_i,
        nreset => sys_nreset,
        bus_addr => s_addr,
        bus_dms => s_dms,
        bus_tms => s_tms,
        bus_sact => s_sact_arr(1),
        bus_dsm => s_dsm_arr(1),
        leds => leds_o
    );

    U_RAM : entity ram_512x32 generic map(
        init_file => "../src/cuenta_en_display.txt"
    )
    port map (
        clk => clk_i,
        addr => ram_addr_c,
        dout => ram_dout_c,
        we => ram_we_c,
        din => ram_din_c,
        mask => ram_mask_c

    );


end arch ;